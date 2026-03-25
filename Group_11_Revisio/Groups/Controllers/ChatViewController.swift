//
//  ChatViewController.swift
//  Group_11_Revisio
//

import UIKit
import MessageKit
import InputBarAccessoryView
import Supabase
import UniformTypeIdentifiers
import Speech
import AVFoundation

// MARK: - MessageMeta
// Sidecar dictionary keyed by messageId.
// NEVER use array indices to look up file info — chatMessages has optimistic bubbles
// that don't exist in DataManager, so indices don't match.
private struct MessageMeta {
    let fileType: String?
    let fileUrl:  String?
    let fileName: String?
}

// MARK: - DocBubbleView
// UIView rendered inside .custom MessageKind bubbles for document messages.
// Using .custom instead of .attributedText makes didTapMessage fire without interception.
class DocBubbleView: UIView {
    let iconView  = UIImageView()
    let nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font          = UIFont.systemFont(ofSize: 14, weight: .semibold)
        nameLabel.numberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)
        addSubview(nameLabel)
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 34),
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(fileName: String, isOutgoing: Bool) {
        let color = isOutgoing ? UIColor.white : UIColor.systemBlue
        let cfg   = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        let ext   = (fileName as NSString).pathExtension.lowercased()
        let symbol: String
        switch ext {
        case "pdf":          symbol = "doc.richtext.fill"
        case "doc", "docx":  symbol = "doc.text.fill"
        default:             symbol = "doc.fill"
        }
        iconView.image     = UIImage(systemName: symbol, withConfiguration: cfg)?
            .withTintColor(color, renderingMode: .alwaysOriginal)
        nameLabel.text      = fileName
        nameLabel.textColor = isOutgoing ? .white : .label
    }
}

// MARK: - CustomMessageSizeCalculator
private class CustomMessageSizeCalculator: MessageSizeCalculator {
    override func messageContainerSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        return CGSize(width: 220, height: 52)
    }
}

// MARK: - ChatViewController

class ChatViewController: MessagesViewController, GroupUpdateDelegate {

    weak var updateDelegate: GroupUpdateDelegate?
    var group: Group?
    var groupName: String = ""

    var currentUser = ChatSender(senderId: "unknown", displayName: "Me")
    private var chatMessages: [ChatMessage] = []
    private var messageMeta:  [String: MessageMeta] = [:]
    private var senderNameCache: [String: String] = [:]
    private var realtimeChannel: RealtimeChannelV2?

    // Speech recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var isRecording = false

    private lazy var micButton: InputBarButtonItem = {
        let item = InputBarButtonItem()
        item.image     = UIImage(systemName: "mic.fill")
        item.tintColor = .systemGray
        item.setSize(CGSize(width: 36, height: 36), animated: false)
        item.onTouchUpInside { [weak self] _ in self?.handleMicTapped() }
        return item
    }()

    // MARK: - viewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()

        if let user = SupabaseManager.shared.client.auth.currentUser {
            currentUser = ChatSender(senderId: user.id.uuidString,
                                     displayName: user.email ?? "Me")
        }

        messagesCollectionView.messagesDataSource      = self
        messagesCollectionView.messagesLayoutDelegate  = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate     = self
        messageInputBar.delegate = self

        setupInputBar()
        setupNavigationTitle()

        messagesCollectionView.scrollsToTop = false
        messagesCollectionView.contentInsetAdjustmentBehavior = .always

        Task { await loadMessages(); await subscribeToMessages() }
    }

    // MARK: - Input bar

    private func setupInputBar() {
        messageInputBar.backgroundView.backgroundColor = .systemBackground
        messageInputBar.separatorLine.isHidden = true

        let tv = messageInputBar.inputTextView
        tv.placeholder         = "Message"
        tv.font                = UIFont.systemFont(ofSize: 17)
        tv.backgroundColor     = UIColor.secondarySystemBackground
        tv.layer.cornerRadius  = 20
        tv.layer.masksToBounds = true
        tv.textContainerInset  = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)

        messageInputBar.padding = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        messageInputBar.middleContentViewPadding.right = 8

        let send = messageInputBar.sendButton
        send.setTitle(nil, for: .normal)
        send.setImage(
            UIImage(systemName: "arrow.up.circle.fill")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)),
            for: .normal)
        send.tintColor = .systemBlue
        send.setSize(CGSize(width: 36, height: 36), animated: false)

        let attachButton = InputBarButtonItem()
        attachButton.image     = UIImage(systemName: "plus")
        attachButton.tintColor = .systemBlue
        attachButton.setSize(CGSize(width: 32, height: 32), animated: false)
        attachButton.onTouchUpInside { [weak self] _ in self?.showAttachmentSheet() }

        messageInputBar.leftStackView.arrangedSubviews.forEach {
            messageInputBar.leftStackView.removeArrangedSubview($0); $0.removeFromSuperview()
        }
        messageInputBar.leftStackView.addArrangedSubview(attachButton)
        messageInputBar.leftStackView.alignment = .center
        messageInputBar.setLeftStackViewWidthConstant(to: 40, animated: false)
        messageInputBar.setStackViewItems([micButton], forStack: .right, animated: false)
        messageInputBar.setRightStackViewWidthConstant(to: 40, animated: false)
    }

    // MARK: - Nav title

    private func setupNavigationTitle() {
        view.layoutIfNeeded()
        navigationItem.largeTitleDisplayMode = .never

        let btn = UIButton(type: .system)
        var cfg = UIButton.Configuration.plain()
        cfg.title          = group?.name ?? groupName
        cfg.image          = UIImage(systemName: "chevron.right")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 13, weight: .medium))
        cfg.imagePlacement = .trailing
        cfg.imagePadding   = 6
        btn.configuration  = cfg
        btn.tintColor      = .systemBlue
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        btn.addTarget(self, action: #selector(groupTitleTapped), for: .touchUpInside)
        navigationItem.titleView = btn
    }

    // MARK: - Attachment sheet

    private func showAttachmentSheet() {
        let sheet = UIAlertController(title: "Send Attachment", message: nil,
                                      preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "📚  Study Material", style: .default) { [weak self] _ in
            self?.openStudyMaterialPicker() })
        sheet.addAction(UIAlertAction(title: "🖼  Photo Library", style: .default) { [weak self] _ in
            self?.openPhotoLibrary() })
        sheet.addAction(UIAlertAction(title: "📄  Files", style: .default) { [weak self] _ in
            self?.openDocumentPicker() })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    private func openStudyMaterialPicker() {
        let vc  = AttachmentFolderViewController()
        vc.sendDelegate = self
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

    private func openPhotoLibrary() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate   = self
        present(picker, animated: true)
    }

    private func openDocumentPicker() {
        let types: [UTType] = [.pdf, .plainText, .data, .spreadsheet, .presentation, .image]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    // MARK: - Load messages

    private func loadMessages() async {
        guard let groupId = group?.id else { return }
        await DataManager.shared.loadMessages(for: groupId)
        let raw = DataManager.shared.groupMessages[groupId] ?? []

        var built: [ChatMessage] = []
        for msg in raw {
            let name = msg.senderId.uuidString == currentUser.senderId
                ? currentUser.displayName
                : await fetchDisplayName(for: msg.senderId.uuidString)
            let sender = ChatSender(senderId: msg.senderId.uuidString, displayName: name)
            let cm = makeChatMessage(from: msg, sender: sender)
            built.append(cm)
            messageMeta[cm.messageId] = MessageMeta(
                fileType: msg.fileType, fileUrl: msg.fileUrl, fileName: msg.fileName)
        }
        built.sort { $0.sentDate < $1.sentDate }

        await MainActor.run {
            chatMessages = built
            messagesCollectionView.reloadData()
            messagesCollectionView.scrollToLastItem(animated: false)
        }
    }

    // MARK: - Build ChatMessage from DB row

    private func makeChatMessage(from msg: Message, sender: ChatSender) -> ChatMessage {
        let out = msg.senderId.uuidString == currentUser.senderId

        if let urlStr = msg.fileUrl, msg.fileType == "link", let url = URL(string: urlStr) {
            return ChatMessage(sender: sender, messageId: msg.id.uuidString,
                               sentDate: msg.createdAt,
                               kind: .attributedText(linkAttr(text: msg.content, url: url, isOutgoing: out)))
        }
        if msg.fileType == "document", let fn = msg.fileName, !fn.isEmpty {
            return ChatMessage(sender: sender, messageId: msg.id.uuidString,
                               sentDate: msg.createdAt,
                               kind: .custom(makeDocBubbleView(fileName: fn, isOutgoing: out)))
        }
        if msg.fileType == "image" {
            return ChatMessage(sender: sender, messageId: msg.id.uuidString,
                               sentDate: msg.createdAt,
                               kind: .photo(RemoteImageMediaItem(urlString: msg.fileUrl, collectionView: messagesCollectionView)))
        }
        return ChatMessage(sender: sender, messageId: msg.id.uuidString,
                           sentDate: msg.createdAt, kind: .text(msg.content))
    }

    // MARK: - Doc bubble factory

    private func makeDocBubbleView(fileName: String, isOutgoing: Bool) -> DocBubbleView {
        let v = DocBubbleView(frame: CGRect(x: 0, y: 0, width: 220, height: 52))
        v.configure(fileName: fileName, isOutgoing: isOutgoing)
        return v
    }

    // MARK: - Link attributed string
    // NO .link attribute key — MessageKit overrides foregroundColor for .link to tintColor (blue).
    // We store the URL in a custom attribute and handle taps manually.
    private func linkAttr(text: String, url: URL, isOutgoing: Bool) -> NSAttributedString {
        let color = isOutgoing ? UIColor.white : UIColor.systemBlue
        let a = NSMutableAttributedString(string: text)
        let r = NSRange(text.startIndex..., in: text)
        a.addAttributes([
            .foregroundColor:                  color,
            .underlineColor:                   color,
            .underlineStyle:                   NSUnderlineStyle.single.rawValue,
            .font:                             UIFont.systemFont(ofSize: 15),
            NSAttributedString.Key("customURL"): url
        ], range: r)
        return a
    }

    // MARK: - Display name

    private func fetchDisplayName(for senderId: String) async -> String {
        if let cached = senderNameCache[senderId] { return cached }
        do {
            struct Profile: Decodable { let username: String? }
            let rows: [Profile] = try await SupabaseManager.shared.client
                .from("profiles").select("username")
                .eq("id", value: senderId).limit(1).execute().value
            let name = rows.first?.username ?? "User"
            senderNameCache[senderId] = name
            return name
        } catch { return "User" }
    }

    // MARK: - Realtime

    private func subscribeToMessages() async {
        guard let groupId = group?.id else { return }
        let channel = await SupabaseManager.shared.client.realtimeV2
            .channel("messages:\(groupId)")
        let changes = await channel.postgresChange(
            InsertAction.self, schema: "public", table: "messages",
            filter: "group_id=eq.\(groupId)")
        await channel.subscribe()
        realtimeChannel = channel

        for await change in changes {
            let row = change.record
            guard let id           = row["id"]?.stringValue,
                  let senderId     = row["sender_id"]?.stringValue,
                  let content      = row["content"]?.stringValue,
                  let createdAtStr = row["created_at"]?.stringValue
            else { continue }

            if senderId == currentUser.senderId { continue }

            let date     = ISO8601DateFormatter().date(from: createdAtStr) ?? Date()
            let name     = await fetchDisplayName(for: senderId)
            let sender   = ChatSender(senderId: senderId, displayName: name)
            let fileUrl  = row["file_url"]?.stringValue
            let fileType = row["file_type"]?.stringValue
            let fileName = row["file_name"]?.stringValue

            let kind: MessageKind
            if let u = fileUrl, fileType == "link", let url = URL(string: u) {
                kind = .attributedText(linkAttr(text: content, url: url, isOutgoing: false))
            } else if fileType == "document", let fn = fileName, !fn.isEmpty {
                kind = .custom(makeDocBubbleView(fileName: fn, isOutgoing: false))
            } else if fileType == "image" {
                kind = .photo(RemoteImageMediaItem(urlString: fileUrl, collectionView: messagesCollectionView))
            } else {
                kind = .text(content)
            }

            let cm   = ChatMessage(sender: sender, messageId: id, sentDate: date, kind: kind)
            let meta = MessageMeta(fileType: fileType, fileUrl: fileUrl, fileName: fileName)

            await MainActor.run {
                chatMessages.append(cm)
                messageMeta[id] = meta
                messagesCollectionView.reloadData()
                messagesCollectionView.scrollToLastItem(animated: true)
            }
        }
    }

    // MARK: - Nav tap

    @objc private func groupTitleTapped() {
        let sb = UIStoryboard(name: "Groups", bundle: nil)
        guard let vc = sb.instantiateViewController(
            withIdentifier: "GroupSettingsVC") as? GroupSettingsViewController else { return }
        vc.group          = group
        vc.updateDelegate = self
        vc.delegate       = navigationController?.viewControllers
            .first { $0 is GroupsViewController } as? LeaveGroupDelegate
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Dictation (mic button)

    private func handleMicTapped() {
        if isRecording {
            stopDictation()
        } else {
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    guard status == .authorized else { return }
                    self?.startDictation()
                }
            }
        }
    }

    private func startDictation() {
        // Cancel any previous task
        recognitionTask?.cancel()
        recognitionTask = nil

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? session.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest,
              let recognizer = speechRecognizer, recognizer.isAvailable else { return }

        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                // Update text field in real time — exactly like iMessage dictation
                let text = result.bestTranscription.formattedString
                self.messageInputBar.inputTextView.text = text
                // Show send button as soon as there's text
                self.messageInputBar.setStackViewItems([self.messageInputBar.sendButton],
                                                       forStack: .right, animated: false)
            }
            if error != nil || (result?.isFinal == true) {
                self.stopDictation()
            }
        }

        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try? audioEngine.start()
        isRecording = true

        // Pulse the mic button red to show active recording — like iMessage
        micButton.tintColor = .systemRed
        micButton.image = UIImage(systemName: "mic.fill")
    }

    private func stopDictation() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        // Restore mic button to grey
        micButton.tintColor = .systemGray
        micButton.image = UIImage(systemName: "mic.fill")

        // If there's text now, keep send button visible
        let hasText = !(messageInputBar.inputTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        if !hasText {
            messageInputBar.setStackViewItems([micButton], forStack: .right, animated: true)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        if isRecording { stopDictation() }
        Task { [weak self] in await self?.realtimeChannel?.unsubscribe() }
    }
}

// MARK: - AttachmentSendDelegate

extension ChatViewController: AttachmentSendDelegate {
    func didSendAttachments(_ items: [SentAttachment]) {
        guard let groupId = group?.id else { return }
        for att in items {
            let msgId = UUID().uuidString
            chatMessages.append(ChatMessage(sender: currentUser, messageId: msgId,
                                            sentDate: Date(),
                                            kind: .custom(makeDocBubbleView(fileName: att.displayName,
                                                                            isOutgoing: true))))
            messageMeta[msgId] = MessageMeta(fileType: "document", fileUrl: nil,
                                              fileName: att.displayName)
            Task {
                do {
                    try await SupabaseManager.shared.sendAttachment(
                        groupId: groupId, senderId: currentUser.senderId, attachment: att)
                } catch { print("❌ sendAttachment: \(error)") }
            }
        }
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        guard let image   = info[.originalImage] as? UIImage,
              let groupId = group?.id,
              let imgData = image.jpegData(compressionQuality: 0.7) else { return }

        let msgId = UUID().uuidString
        chatMessages.append(ChatMessage(sender: currentUser, messageId: msgId, sentDate: Date(),
                                        kind: .photo(LocalImageMediaItem(image: image))))
        messageMeta[msgId] = MessageMeta(fileType: "image", fileUrl: nil, fileName: "Image")
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: true)

        Task {
            do {
                let path      = "\(groupId)/\(UUID().uuidString).jpg"
                let publicUrl = try await SupabaseManager.shared.uploadFile(
                    bucket: "group-media", path: path, data: imgData, contentType: "image/jpeg")

                struct ImageInsert: Encodable {
                    let group_id: UUID; let sender_id: UUID; let content: String
                    let file_url: String; let file_name: String; let file_type: String
                }
                guard let gid = UUID(uuidString: groupId),
                      let sid = UUID(uuidString: currentUser.senderId) else { return }
                try await SupabaseManager.shared.client.from("messages")
                    .insert(ImageInsert(group_id: gid, sender_id: sid, content: "📷 Image",
                                        file_url: publicUrl, file_name: "Image",
                                        file_type: "image")).execute()
                await MainActor.run {
                    self.messageMeta[msgId] = MessageMeta(fileType: "image",
                                                          fileUrl: publicUrl, fileName: "Image")
                }
            } catch { print("❌ image upload: \(error)") }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate

extension ChatViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first, let groupId = group?.id else { return }

        // IMPORTANT: Read file data synchronously here, before the Task.
        // defer would release the security scope when this function returns —
        // which happens before the async Task body runs, making Data(contentsOf:) fail.
        let accessed = url.startAccessingSecurityScopedResource()
        let fileData: Data?
        do { fileData = try Data(contentsOf: url) } catch { fileData = nil }
        if accessed { url.stopAccessingSecurityScopedResource() }

        guard let data = fileData else {
            print("❌ Could not read file: \(url.lastPathComponent)")
            return
        }

        let fileName = url.lastPathComponent
        let msgId    = UUID().uuidString

        chatMessages.append(ChatMessage(sender: currentUser, messageId: msgId, sentDate: Date(),
                                        kind: .custom(makeDocBubbleView(fileName: fileName,
                                                                        isOutgoing: true))))
        messageMeta[msgId] = MessageMeta(fileType: "document", fileUrl: nil, fileName: fileName)
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: true)

        Task {
            do {
                let path      = "\(groupId)/\(UUID().uuidString)_\(fileName)"
                let publicUrl = try await SupabaseManager.shared.uploadFile(
                    bucket: "group-media", path: path, data: data,
                    contentType: "application/octet-stream")

                struct DocInsert: Encodable {
                    let group_id: UUID; let sender_id: UUID; let content: String
                    let file_url: String; let file_name: String; let file_type: String
                }
                guard let gid = UUID(uuidString: groupId),
                      let sid = UUID(uuidString: currentUser.senderId) else { return }
                try await SupabaseManager.shared.client.from("messages")
                    .insert(DocInsert(group_id: gid, sender_id: sid, content: fileName,
                                      file_url: publicUrl, file_name: fileName,
                                      file_type: "document")).execute()
                await MainActor.run {
                    self.messageMeta[msgId] = MessageMeta(fileType: "document",
                                                          fileUrl: publicUrl, fileName: fileName)
                }
            } catch { print("❌ doc upload: \(error)") }
        }
    }
}

// MARK: - MessagesDataSource

extension ChatViewController: MessagesDataSource {

    var currentSender: SenderType { currentUser }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        chatMessages.count
    }

    func messageForItem(at indexPath: IndexPath,
                        in messagesCollectionView: MessagesCollectionView) -> MessageType {
        chatMessages[indexPath.section]
    }

    // Renders the DocBubbleView inside a plain registered cell
    func customCell(for message: MessageType, at indexPath: IndexPath,
                    in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {
        messagesCollectionView.register(UICollectionViewCell.self,
                                        forCellWithReuseIdentifier: "DocBubbleCell")
        let cell = messagesCollectionView.dequeueReusableCell(
            withReuseIdentifier: "DocBubbleCell", for: indexPath)
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        if case .custom(let payload) = message.kind, let v = payload as? DocBubbleView {
            v.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(v)
            NSLayoutConstraint.activate([
                v.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                v.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
                v.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                v.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor)
            ])
        }
        return cell
    }

    func customCellSizeCalculator(for message: MessageType, at indexPath: IndexPath,
                                   in messagesCollectionView: MessagesCollectionView) -> CellSizeCalculator {
        CustomMessageSizeCalculator(layout: messagesCollectionView.messagesCollectionViewFlowLayout)
    }
}

extension ChatViewController {
    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section > 0 else { return false }
        return chatMessages[indexPath.section].sender.senderId ==
               chatMessages[indexPath.section - 1].sender.senderId
    }
}

// MARK: - MessagesLayoutDelegate

extension ChatViewController: MessagesLayoutDelegate {

    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath,
                                in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if message.sender.senderId == currentUser.senderId { return 0 }
        return (indexPath.section == 0 || !isPreviousMessageSameSender(at: indexPath)) ? 16 : 0
    }

    func messageTopLabelAlignment(for message: MessageType, at indexPath: IndexPath,
                                   in messagesCollectionView: MessagesCollectionView) -> LabelAlignment? {
        guard message.sender.senderId != currentUser.senderId else { return nil }
        guard indexPath.section == 0 || !isPreviousMessageSameSender(at: indexPath) else { return nil }
        return LabelAlignment(textAlignment: .left,
                              textInsets: UIEdgeInsets(top: 0, left: 48, bottom: 4, right: 0))
    }

    func messagePadding(for message: MessageType, at indexPath: IndexPath,
                        in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets {
        UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
    }
}

// MARK: - MessagesDisplayDelegate

extension ChatViewController: MessagesDisplayDelegate {

    func backgroundColor(for message: MessageType, at indexPath: IndexPath,
                          in messagesCollectionView: MessagesCollectionView) -> UIColor {
        message.sender.senderId == currentUser.senderId ? .systemBlue : .systemGray5
    }

    func textColor(for message: MessageType, at indexPath: IndexPath,
                   in messagesCollectionView: MessagesCollectionView) -> UIColor {
        message.sender.senderId == currentUser.senderId ? .white : .label
    }

    func configureMessageLabel(_ messageLabel: MessageLabel, for message: MessageType,
                               at indexPath: IndexPath,
                               in messagesCollectionView: MessagesCollectionView) {
        messageLabel.tintColor = message.sender.senderId == currentUser.senderId
            ? .white : .systemBlue
    }

    func messageTopLabelAttributedText(for message: MessageType,
                                        at indexPath: IndexPath) -> NSAttributedString? {
        if message.sender.senderId == currentUser.senderId { return nil }
        if isPreviousMessageSameSender(at: indexPath) { return nil }
        return NSAttributedString(string: message.sender.displayName, attributes: [
            .font: UIFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: UIColor.secondaryLabel
        ])
    }

    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType,
                              at indexPath: IndexPath,
                              in messagesCollectionView: MessagesCollectionView) {
        avatarView.isHidden = false
        let initial = String(message.sender.displayName.prefix(1)).uppercased()
        avatarView.set(avatar: Avatar(image: nil, initials: initial))
        avatarView.layer.cornerRadius = 14
        avatarView.clipsToBounds = true
    }
}

// MARK: - InputBarAccessoryViewDelegate

extension ChatViewController: InputBarAccessoryViewDelegate {

    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue)
        let r      = NSRange(trimmed.startIndex..., in: trimmed)
        let isLink = !(detector?.matches(in: trimmed, options: [], range: r) ?? []).isEmpty

        let msgId = UUID().uuidString
        let kind: MessageKind
        if isLink, let url = URL(string: trimmed.hasPrefix("http") ? trimmed : "https://\(trimmed)") {
            kind = .attributedText(linkAttr(text: trimmed, url: url, isOutgoing: true))
        } else {
            kind = .text(trimmed)
        }

        chatMessages.append(ChatMessage(sender: currentUser, messageId: msgId,
                                        sentDate: Date(), kind: kind))
        messageMeta[msgId] = MessageMeta(fileType: isLink ? "link" : nil,
                                          fileUrl: nil, fileName: nil)
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: true)
        inputBar.inputTextView.text = ""
        inputBar.setStackViewItems([micButton], forStack: .right, animated: true)

        guard let groupId = group?.id else { return }
        Task {
            do {
                try await SupabaseManager.shared.sendMessage(
                    groupId: groupId, senderId: currentUser.senderId, text: trimmed)
            } catch { print("❌ sendMessage: \(error)") }
        }
    }

    func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
        inputBar.setStackViewItems(
            text.isEmpty ? [micButton] : [inputBar.sendButton],
            forStack: .right, animated: true)
    }
}

// MARK: - LeaveGroupDelegate

extension ChatViewController: LeaveGroupDelegate {
    func didLeaveGroup(_ group: Group) {
        navigationController?.popToRootViewController(animated: true)
    }
    func didUpdateGroup(_ group: Group) {
        self.group = group
        if let btn = navigationItem.titleView as? UIButton {
            var cfg = btn.configuration
            cfg?.title = group.name
            btn.configuration = cfg
        }
        updateDelegate?.didUpdateGroup(group)
    }
}

// MARK: - MessageCellDelegate

extension ChatViewController: MessageCellDelegate {

    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let cm   = chatMessages[indexPath.section]
        let meta = messageMeta[cm.messageId]

        switch cm.kind {

        case .photo(let media):
            if let img = media.image {
                openImagePreview(img)
            } else if let urlStr = meta?.fileUrl, let url = URL(string: urlStr) {
                downloadThenShowImage(url: url)
            }

        case .attributedText(let attr):
            var found: URL? = nil
            attr.enumerateAttribute(NSAttributedString.Key("customURL"),
                                    in: NSRange(location: 0, length: attr.length)) { v, _, _ in
                if let u = v as? URL { found = u }
            }
            if let url = found { UIApplication.shared.open(url) }

        case .custom:
            guard let m = meta else { return }
            if m.fileType == "document" {
                openRemoteDoc(urlString: m.fileUrl, fileName: m.fileName)
            } else if m.fileType == "image",
                      let s = m.fileUrl, let url = URL(string: s) {
                downloadThenShowImage(url: url)
            }

        default: break
        }
    }

    private func openImagePreview(_ image: UIImage) {
        let vc  = MediaPreviewViewController()
        vc.image = image
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func downloadThenShowImage(url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let img = UIImage(data: data) else { return }
            DispatchQueue.main.async { self?.openImagePreview(img) }
        }.resume()
    }

    private func openRemoteDoc(urlString: String?, fileName: String?) {
        guard let s = urlString, !s.isEmpty, !s.hasPrefix("revisio://"),
              let url = URL(string: s) else { return }
        let name = fileName ?? "document"
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data else { return }
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(name)
            try? data.write(to: tmp)
            DispatchQueue.main.async {
                let vc  = DocumentPreviewViewController()
                vc.documentURL = tmp
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                self?.present(nav, animated: true)
            }
        }.resume()
    }
}

// MARK: - Media items

private struct LocalImageMediaItem: MediaItem {
    var url: URL? { nil }
    var image: UIImage?
    var placeholderImage: UIImage { UIImage(systemName: "photo") ?? UIImage() }
    var size: CGSize { CGSize(width: 200, height: 150) }
    init(image: UIImage) { self.image = image }
}

private class RemoteImageMediaItem: NSObject, MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage { UIImage(systemName: "photo") ?? UIImage() }
    var size: CGSize { CGSize(width: 200, height: 150) }
    // Weak ref to collection view so we can reload when download finishes
    weak var collectionView: MessagesCollectionView?

    init(urlString: String?, collectionView: MessagesCollectionView? = nil) {
        if let s = urlString { url = URL(string: s) }
        self.collectionView = collectionView
        super.init()
        loadImage()
    }

    private func loadImage() {
        guard let url = url else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let img = UIImage(data: data) else { return }
            self?.image = img
            // Reload so the cell replaces placeholder with the real image
            DispatchQueue.main.async {
                self?.collectionView?.reloadData()
            }
        }.resume()
    }
}
