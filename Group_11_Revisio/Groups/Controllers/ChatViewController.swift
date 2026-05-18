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
// Sidecar keyed by messageId. Stores file info AND raw content so
// study material can be previewed without a network call.
private struct MessageMeta {
    let fileType: String?
    let fileUrl: String?
    let fileName: String?
    let content: String?   // raw packed content (notes text / quiz JSON / flashcard JSON)
    let materialType: String?  // "Notes" | "Cheatsheet" | "Flashcards" | "Quiz"
}

// MARK: - DocBubbleView
// Single horizontal row: icon on left, text on right — compact like iMessage file bubble.
class DocBubbleView: UIView {
    private let iconContainerView = UIView()
    private let iconView  = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let labelsStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .systemGray6
        layer.cornerRadius = 12
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.separator.cgColor
        clipsToBounds = true
        layoutMargins = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 12)

        iconContainerView.translatesAutoresizingMaskIntoConstraints = false
        iconContainerView.layer.cornerRadius = 8
        iconContainerView.clipsToBounds = true

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.allowsDefaultTighteningForTruncation = true
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        labelsStack.axis = .vertical
        labelsStack.spacing = 1
        labelsStack.alignment = .leading
        labelsStack.translatesAutoresizingMaskIntoConstraints = false
        labelsStack.addArrangedSubview(titleLabel)
        labelsStack.addArrangedSubview(subtitleLabel)

        iconContainerView.addSubview(iconView)
        addSubview(iconContainerView)
        addSubview(labelsStack)

        NSLayoutConstraint.activate([
            iconContainerView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            iconContainerView.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor),
            iconContainerView.widthAnchor.constraint(equalToConstant: 28),
            iconContainerView.heightAnchor.constraint(equalToConstant: 28),

            iconView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 14),
            iconView.heightAnchor.constraint(equalToConstant: 14),

            labelsStack.leadingAnchor.constraint(equalTo: iconContainerView.trailingAnchor, constant: 10),
            labelsStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            labelsStack.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor)
        ])
    }

    func configure(fileName: String, materialType: String?, isOutgoing: Bool) {
        let parts = Self.displayParts(for: fileName, materialType: materialType)
        let (symbol, color) = iconStyle(for: parts.type, fileName: fileName)

        titleLabel.text = parts.title
        subtitleLabel.text = subtitleText(for: parts.type, fileName: fileName)

        iconView.image = UIImage(systemName: symbol)
        iconView.tintColor = color
        iconContainerView.backgroundColor = color.withAlphaComponent(0.15)
        accessibilityIdentifier = isOutgoing ? "studyBubbleOutgoing" : "studyBubbleIncoming"
    }

    private func displayParts(for fileName: String, materialType: String?) -> (title: String, type: String?) {
        Self.displayParts(for: fileName, materialType: materialType)
    }

    static func displayParts(for fileName: String, materialType: String?) -> (title: String, type: String?) {
        if let type = materialType {
            let parts = fileName.components(separatedBy: " · ")
            if parts.count >= 2 {
                return (Self.cleanDisplayName(parts[0]), type)
            }
            let trimmed = fileName.replacingOccurrences(of: " · \(type)", with: "")
            return (Self.cleanDisplayName(trimmed), type)
        }

        let parts = fileName.components(separatedBy: " · ")
        if parts.count >= 2 {
            return (Self.cleanDisplayName(parts[0]), parts.last)
        }

        return (Self.cleanDisplayName(fileName), nil)
    }

    private func subtitleText(for type: String?, fileName: String) -> String {
        if let type = type, !type.isEmpty {
            return "\(type) • Shared"
        }
        let ext = (fileName as NSString).pathExtension.uppercased()
        if !ext.isEmpty {
            return "\(ext) • Shared"
        }
        return "Document • Shared"
    }

    private func iconStyle(for type: String?, fileName: String) -> (String, UIColor) {
        switch type {
        case "Quiz":
            return ("timer", UIColor(red: 0.45, green: 0.85, blue: 0.61, alpha: 1.0))
        case "Notes":
            return ("book.pages", UIColor(hex: "FFC445", alpha: 0.75))
        case "Flashcards":
            return ("rectangle.on.rectangle.angled", UIColor(hex: "91C1EF"))
        case "Cheatsheet":
            return ("list.clipboard", UIColor(hex: "8A38F5", alpha: 0.50))
        default:
            let ext = (fileName as NSString).pathExtension.lowercased()
            switch ext {
            case "jpg", "jpeg", "png":
                return ("photo.fill", .systemIndigo)
            case "pdf":
                return ("doc.richtext.fill", .systemIndigo)
            case "doc", "docx":
                return ("doc.text.fill", .systemIndigo)
            case "txt":
                return ("textformat", .systemIndigo)
            default:
                return ("doc.text.fill", .systemIndigo)
            }
        }
    }

    static func cleanDisplayName(_ rawName: String) -> String {
        rawName.replacingOccurrences(of: ".txt", with: "")
            .replacingOccurrences(of: "Note_", with: "")
            .replacingOccurrences(of: "Link_", with: "")
            .replacingOccurrences(of: "Image_", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - CustomMessageSizeCalculator
private class CustomMessageSizeCalculator: MessageSizeCalculator {
    override func messageContainerSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        guard let collectionView = layout?.collectionView else {
            return CGSize(width: 220, height: 60)
        }
        let maxWidth = collectionView.bounds.width * 0.7
        return CGSize(width: maxWidth, height: 60)
    }
}

// MARK: - ChatViewController

class ChatViewController: MessagesViewController, GroupUpdateDelegate {

    weak var updateDelegate: GroupUpdateDelegate?
    var group: Group?
    var groupName: String = ""

    var currentUser = ChatSender(senderId: "unknown", displayName: "Me")
    private var chatMessages: [ChatMessage] = []
    private var messageMeta: [String: MessageMeta] = [:]
    private var senderNameCache: [String: String] = [:]
    private var realtimeChannel: RealtimeChannelV2?

    // Speech
    private let speechRecognizer     = SFSpeechRecognizer(locale: Locale.current)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine          = AVAudioEngine()
    private var isRecording          = false

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
        setupLongPressGesture()

        messagesCollectionView.scrollsToTop = false
        messagesCollectionView.contentInsetAdjustmentBehavior = .always

        Task {
            await loadMessages()
            await subscribeToMessages()
        }
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

    // MARK: - Navigation title

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
        sheet.addAction(UIAlertAction(title: "Study Material", style: .default) { [weak self] _ in
            self?.openStudyMaterialPicker() })
        sheet.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            self?.openPhotoLibrary() })
        sheet.addAction(UIAlertAction(title: "Files", style: .default) { [weak self] _ in
            self?.openDocumentPicker() })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .destructive))
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
            let cm     = makeChatMessage(from: msg, sender: sender)
            built.append(cm)
            // Derive materialType from fileName ("Recursion · Notes" → "Notes")
            let mt = extractMaterialType(from: msg.fileName)
            messageMeta[cm.messageId] = MessageMeta(
                fileType: msg.fileType,
                fileUrl: msg.fileUrl,
                fileName: msg.fileName,
                content: msg.content,
                materialType: mt)
        }
        built.sort { $0.sentDate < $1.sentDate }

        DispatchQueue.main.async {
            self.chatMessages = built
            self.messagesCollectionView.reloadData()
            self.messagesCollectionView.scrollToLastItem(animated: false)
        }
    }

    // Extract material type from file name like "Recursion · Notes" → "Notes"
    private func extractMaterialType(from fileName: String?) -> String? {
        guard let fn = fileName else { return nil }
        let types = ["Notes", "Flashcards", "Quiz", "Cheatsheet"]
        for t in types { if fn.contains(t) { return t } }
        return nil
    }

    // MARK: - Build ChatMessage from DB row

    private func makeChatMessage(from msg: Message, sender: ChatSender) -> ChatMessage {
        let out = msg.senderId.uuidString == currentUser.senderId
        let mt  = extractMaterialType(from: msg.fileName)

        // Link bubble
        if let urlStr = msg.fileUrl, msg.fileType == "link", let url = URL(string: urlStr) {
            return ChatMessage(sender: sender, messageId: msg.id.uuidString,
                               sentDate: msg.createdAt,
                               kind: .attributedText(linkAttr(text: msg.content, url: url, isOutgoing: out)))
        }

        // Study material OR uploaded document — both use .custom DocBubbleView
        if msg.fileType == "document", let fn = msg.fileName, !fn.isEmpty {
            return ChatMessage(sender: sender, messageId: msg.id.uuidString,
                               sentDate: msg.createdAt,
                               kind: .custom(makeDocBubbleView(fileName: fn, materialType: mt, isOutgoing: out)))
        }

        // Image
        if msg.fileType == "image" {
            return ChatMessage(sender: sender, messageId: msg.id.uuidString,
                               sentDate: msg.createdAt,
                               kind: .photo(RemoteImageMediaItem(urlString: msg.fileUrl,
                                                                 collectionView: messagesCollectionView)))
        }

        return ChatMessage(sender: sender, messageId: msg.id.uuidString,
                           sentDate: msg.createdAt, kind: .text(msg.content))
    }

    // MARK: - Doc bubble factory

    private func makeDocBubbleView(fileName: String, materialType: String?, isOutgoing: Bool) -> DocBubbleView {
        let availableWidth = messagesCollectionView.bounds.width
        let maxWidth = availableWidth * 0.7
        let v = DocBubbleView(frame: CGRect(x: 0, y: 0, width: maxWidth, height: 60))
        v.configure(fileName: fileName, materialType: materialType, isOutgoing: isOutgoing)
        return v
    }

    // MARK: - Link attributed string

    private func linkAttr(text: String, url: URL, isOutgoing: Bool) -> NSAttributedString {
        let color = isOutgoing ? UIColor.white : UIColor.systemBlue
        let a = NSMutableAttributedString(string: text)
        let r = NSRange(text.startIndex..., in: text)
        a.addAttributes([
            .foregroundColor: color,
            .underlineColor: color,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .font: UIFont.systemFont(ofSize: 15),
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
        let channel = SupabaseManager.shared.client.realtimeV2
            .channel("messages:\(groupId)")
        let changes = channel.postgresChange(
            InsertAction.self, schema: "public", table: "messages",
            filter: .eq("group_id", value: groupId))
        _ = try? await channel.subscribeWithError()
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
            let mt       = extractMaterialType(from: fileName)

            let kind: MessageKind
            if let u = fileUrl, fileType == "link", let url = URL(string: u) {
                kind = .attributedText(linkAttr(text: content, url: url, isOutgoing: false))
            } else if fileType == "document", let fn = fileName, !fn.isEmpty {
                kind = .custom(makeDocBubbleView(fileName: fn, materialType: mt, isOutgoing: false))
            } else if fileType == "image" {
                kind = .photo(RemoteImageMediaItem(urlString: fileUrl,
                                                   collectionView: messagesCollectionView))
            } else {
                kind = .text(content)
            }

            let cm   = ChatMessage(sender: sender, messageId: id, sentDate: date, kind: kind)
            let meta = MessageMeta(fileType: fileType, fileUrl: fileUrl, fileName: fileName,
                                   content: content, materialType: mt)

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.chatMessages.append(cm)
                self.messageMeta[id] = meta
                self.messagesCollectionView.reloadData()
                self.messagesCollectionView.scrollToLastItem(animated: true)
            }
        }
    }

    // MARK: - Dictation

    private func handleMicTapped() {
        if isRecording { stopDictation() } else {
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    guard status == .authorized else { return }
                    self?.startDictation()
                }
            }
        }
    }

    private func startDictation() {
        if audioEngine.isRunning {
            stopDictation()
        }
        recognitionTask?.cancel()
        recognitionTask = nil

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .measurement,
                                    options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ audio session start failed: \(error)")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let req = recognitionRequest,
              let rec = speechRecognizer, rec.isAvailable else { return }
        req.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        recognitionTask = rec.recognitionTask(with: req) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                self.messageInputBar.inputTextView.text = result.bestTranscription.formattedString
                self.messageInputBar.setStackViewItems([self.messageInputBar.sendButton],
                                                       forStack: .right, animated: false)
            }
            if error != nil || result?.isFinal == true { self.stopDictation() }
        }
        let fmt = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: fmt) { [weak self] buf, _ in
            self?.recognitionRequest?.append(buf)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            micButton.tintColor = .systemRed
        } catch {
            print("❌ audio engine start failed: \(error)")
            stopDictation()
        }
    }

    private func stopDictation() {
        if audioEngine.isRunning { audioEngine.stop() }
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ audio session stop failed: \(error)")
        }
        micButton.tintColor = .systemGray
        let hasText = !(messageInputBar.inputTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        if !hasText {
            messageInputBar.setStackViewItems([micButton], forStack: .right, animated: true)
        }
    }

    // MARK: - Long press gesture

    private func setupLongPressGesture() {
        let lp = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        lp.minimumPressDuration = 0.4
        lp.cancelsTouchesInView = false
        messagesCollectionView.addGestureRecognizer(lp)

        // Tap gesture on the collection view — fires for ALL cell types (.custom, .photo, .text)
        // didTapMessage from MessageCellDelegate does NOT fire for plain UICollectionViewCell
        // (.custom cells), so we handle ALL taps here instead.
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.cancelsTouchesInView = false
        messagesCollectionView.addGestureRecognizer(tap)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: messagesCollectionView)
        guard let indexPath = messagesCollectionView.indexPathForItem(at: point),
              indexPath.section < chatMessages.count else { return }

        let cm   = chatMessages[indexPath.section]
        let meta = messageMeta[cm.messageId]

        switch cm.kind {

        case .photo(let media):
            if let img = media.image {
                openImagePreview(img)
            } else if let s = meta?.fileUrl, let url = URL(string: s) {
                downloadThenShowImage(url: url)
            }

        case .attributedText(let attr):
            var found: URL?
            attr.enumerateAttribute(NSAttributedString.Key("customURL"),
                                    in: NSRange(location: 0, length: attr.length)) { v, _, _ in
                if let u = v as? URL { found = u }
            }
            if let url = found { UIApplication.shared.open(url) }

        case .custom:
            guard let m = meta else { return }
            openDocument(meta: m)

        default: break
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: messagesCollectionView)
        guard let indexPath = messagesCollectionView.indexPathForItem(at: point),
              indexPath.section < chatMessages.count else { return }

        let cm = chatMessages[indexPath.section]
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Copy", style: .default) { _ in
            if case .text(let t) = cm.kind { UIPasteboard.general.string = t } else if case .attributedText(let a) = cm.kind { UIPasteboard.general.string = a.string }
        })

        if cm.sender.senderId == currentUser.senderId {
            alert.addAction(UIAlertAction(title: "Unsend", style: .destructive) { [weak self] _ in
                self?.unsendMessage(cm)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func unsendMessage(_ cm: ChatMessage) {
        guard let idx = chatMessages.firstIndex(where: { $0.messageId == cm.messageId }) else { return }
        chatMessages.remove(at: idx)
        messageMeta.removeValue(forKey: cm.messageId)
        messagesCollectionView.reloadData()
        Task {
            do { try await SupabaseManager.shared.deleteMessage(id: cm.messageId,
                                                                 senderId: currentUser.senderId) } catch { print("❌ unsend: \(error)") }
        }
    }

    // MARK: - Navigation

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
            let mt    = extractMaterialType(from: att.displayName)
            chatMessages.append(ChatMessage(sender: currentUser, messageId: msgId,
                                            sentDate: Date(),
                                            kind: .custom(makeDocBubbleView(
                                                fileName: att.displayName,
                                                materialType: mt,
                                                isOutgoing: true))))
            messageMeta[msgId] = MessageMeta(fileType: "document", fileUrl: nil,
                                              fileName: att.displayName,
                                              content: att.content,
                                              materialType: mt)
            Task {
                do { try await SupabaseManager.shared.sendAttachment(
                    groupId: groupId, senderId: currentUser.senderId, attachment: att) } catch { print("❌ sendAttachment: \(error)") }
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
        messageMeta[msgId] = MessageMeta(fileType: "image", fileUrl: nil,
                                          fileName: "Image", content: nil, materialType: nil)
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
                DispatchQueue.main.async { [weak self] in
                    self?.messageMeta[msgId] = MessageMeta(fileType: "image", fileUrl: publicUrl,
                                                           fileName: "Image", content: nil,
                                                           materialType: nil)
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

        let accessed = url.startAccessingSecurityScopedResource()
        let fileData: Data?
        do { fileData = try Data(contentsOf: url) } catch { fileData = nil }
        if accessed { url.stopAccessingSecurityScopedResource() }
        guard let data = fileData else { return }

        let fileName = url.lastPathComponent
        let msgId    = UUID().uuidString
        chatMessages.append(ChatMessage(sender: currentUser, messageId: msgId, sentDate: Date(),
                                        kind: .custom(makeDocBubbleView(fileName: fileName,
                                                                        materialType: nil,
                                                                        isOutgoing: true))))
        messageMeta[msgId] = MessageMeta(fileType: "document", fileUrl: nil,
                                          fileName: fileName, content: nil, materialType: nil)
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
                DispatchQueue.main.async { [weak self] in
                    self?.messageMeta[msgId] = MessageMeta(fileType: "document", fileUrl: publicUrl,
                                                           fileName: fileName, content: nil,
                                                           materialType: nil)
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

    func customCell(for message: MessageType, at indexPath: IndexPath,
                    in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {
        messagesCollectionView.register(UICollectionViewCell.self,
                                        forCellWithReuseIdentifier: "DocBubbleCell")
        let cell = messagesCollectionView.dequeueReusableCell(
            withReuseIdentifier: "DocBubbleCell", for: indexPath)
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.backgroundColor = .clear
        cell.contentView.layer.cornerRadius = 0
        cell.contentView.clipsToBounds = false

        if case .custom(let payload) = message.kind, let v = payload as? DocBubbleView {
            let isOut = message.sender.senderId == currentUser.senderId
            let maxWidth = messagesCollectionView.bounds.width * 0.7
            let layout = messagesCollectionView.messagesCollectionViewFlowLayout
            let avatarSize = isOut
                ? layout.textMessageSizeCalculator.outgoingAvatarSize
                : layout.textMessageSizeCalculator.incomingAvatarSize
            let avatarInset = avatarSize.width > 0 ? (avatarSize.width + 6) : 0
            v.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(v)
            NSLayoutConstraint.activate([
                v.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                v.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
                v.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth),
                isOut
                    ? v.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor,
                                                  constant: -avatarInset)
                    : v.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor,
                                                  constant: avatarInset),
                isOut
                    ? v.leadingAnchor.constraint(greaterThanOrEqualTo: cell.contentView.leadingAnchor)
                    : v.trailingAnchor.constraint(lessThanOrEqualTo: cell.contentView.trailingAnchor)
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
        UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
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

        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let r        = NSRange(trimmed.startIndex..., in: trimmed)
        let isLink   = !(detector?.matches(in: trimmed, options: [], range: r) ?? []).isEmpty

        let msgId = UUID().uuidString
        let kind: MessageKind
        if isLink, let url = URL(string: trimmed.hasPrefix("http") ? trimmed : "https://\(trimmed)") {
            kind = .attributedText(linkAttr(text: trimmed, url: url, isOutgoing: true))
        } else {
            kind = .text(trimmed)
        }

        chatMessages.append(ChatMessage(sender: currentUser, messageId: msgId,
                                        sentDate: Date(), kind: kind))
        messageMeta[msgId] = MessageMeta(fileType: isLink ? "link" : nil, fileUrl: nil,
                                          fileName: nil, content: nil, materialType: nil)
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: true)
        inputBar.inputTextView.text = ""
        inputBar.setStackViewItems([micButton], forStack: .right, animated: true)

        guard let groupId = group?.id else { return }
        Task {
            do { try await SupabaseManager.shared.sendMessage(
                groupId: groupId, senderId: currentUser.senderId, text: trimmed) } catch { print("❌ sendMessage: \(error)") }
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
            var cfg = btn.configuration; cfg?.title = group.name; btn.configuration = cfg
        }
        updateDelegate?.didUpdateGroup(group)
    }
}

// MARK: - MessageCellDelegate

extension ChatViewController: MessageCellDelegate {

    // Long press backup for text/link bubbles (handleTap handles actual taps)
    func didLongPressMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
              indexPath.section < chatMessages.count else { return }
        let cm = chatMessages[indexPath.section]
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Copy", style: .default) { _ in
            if case .text(let t) = cm.kind { UIPasteboard.general.string = t } else if case .attributedText(let a) = cm.kind { UIPasteboard.general.string = a.string }
        })
        if cm.sender.senderId == currentUser.senderId {
            alert.addAction(UIAlertAction(title: "Unsend", style: .destructive) { [weak self] _ in
                self?.unsendMessage(cm)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Open document (study material or real file)

    private func openDocument(meta: MessageMeta) {
        let fileUrl  = meta.fileUrl ?? ""
        let fileName = meta.fileName ?? "document"

        // study material: reviseq:// deep link OR no URL (optimistic bubble not yet confirmed)
        if fileUrl.isEmpty || fileUrl.hasPrefix("reviseq://") {
            openStudyMaterial(meta: meta)
            return
        }

        // Real file uploaded to Supabase Storage — download then open
        guard let url = URL(string: fileUrl) else { return }
        openRemoteFile(url: url, fileName: fileName)
    }

    private func openStudyMaterial(meta: MessageMeta) {
        let parts = DocBubbleView.displayParts(for: meta.fileName ?? "", materialType: meta.materialType)
        let rawName = (meta.fileName ?? "").components(separatedBy: " · ").first ?? parts.title
        let materialType = meta.materialType ?? parts.type ?? "Notes"
        let subjectName = group?.name ?? (groupName.isEmpty ? "Shared" : groupName)

        let topic = findExistingTopic(named: rawName, cleanedName: parts.title, type: materialType)
            ?? buildTopic(name: rawName, materialType: materialType, subjectName: subjectName, content: meta.content)

        if openStudyMaterialViewer(for: topic) { return }

        let vc = StudyMaterialPreviewViewController()
        vc.materialType = materialType
        vc.materialName = parts.title
        vc.content = meta.content ?? "No content available."
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

    private func findExistingTopic(named rawName: String, cleanedName: String, type: String) -> Topic? {
        let candidates = DataManager.shared.getAllRecentTopics().filter { $0.materialType == type }
        if let exact = candidates.first(where: { $0.name == rawName }) { return exact }
        return candidates.first(where: { $0.name == cleanedName })
    }

    private func buildTopic(name: String, materialType: String, subjectName: String, content: String?) -> Topic {
        var topic = Topic(name: name, lastAccessed: "Just now", materialType: materialType,
                          parentSubjectName: subjectName)
        let payload = content ?? ""
        switch materialType {
        case "Notes":
            topic.notesContent = payload
        case "Cheatsheet":
            topic.cheatsheetContent = payload
        case "Quiz":
            topic.largeContentBody = payload
            let parsed = parseQuizQuestions(from: payload)
            topic.quizQuestions = parsed.isEmpty ? nil : parsed
        case "Flashcards":
            topic.largeContentBody = payload
        default:
            topic.largeContentBody = payload
        }
        return topic
    }

    private func parseQuizQuestions(from content: String) -> [QuizQuestion] {
        let lines = content.components(separatedBy: "\n")
        return lines.compactMap { line in
            let parts = line.components(separatedBy: "|")
            guard parts.count >= 6 else { return nil }
            let answers = Array(parts[1...4])
            let correctIndex = Int(parts[5]) ?? 0
            let hint = parts.count > 6 ? parts[6] : "Focus on core concepts."
            return QuizQuestion(
                questionText: parts[0],
                answers: answers,
                correctAnswerIndex: max(0, min(correctIndex, answers.count - 1)),
                userAnswerIndex: nil,
                isFlagged: false,
                hint: hint
            )
        }
    }

    private func openStudyMaterialViewer(for topic: Topic) -> Bool {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        switch topic.materialType {
        case "Notes":
            guard let vc = storyboard.instantiateViewController(
                withIdentifier: "NotesViewController") as? NotesViewController else { return false }
            vc.currentTopic = topic
            vc.parentSubjectName = topic.parentSubjectName
            showMaterialViewer(vc)
            return true
        case "Cheatsheet":
            guard let vc = storyboard.instantiateViewController(
                withIdentifier: "CheatsheetViewController") as? CheatsheetViewController else { return false }
            vc.currentTopic = topic
            vc.parentSubjectName = topic.parentSubjectName
            showMaterialViewer(vc)
            return true
        case "Flashcards":
            guard let vc = storyboard.instantiateViewController(
                withIdentifier: "FlashcardViewController") as? FlashcardViewController else { return false }
            vc.currentTopic = topic
            vc.parentSubjectName = topic.parentSubjectName
            showMaterialViewer(vc)
            return true
        case "Quiz":
            guard let vc = storyboard.instantiateViewController(
                withIdentifier: "QuizStartViewController") as? QuizStartViewController else { return false }
            vc.currentTopic = topic
            vc.parentSubject = topic.parentSubjectName
            vc.quizSourceName = topic.name
            showMaterialViewer(vc)
            return true
        default:
            return false
        }
    }

    private func openRemoteFile(url: URL, fileName: String) {
        // QLPreviewController needs a local file — download to temp first
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data else { return }
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
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

    private func showMaterialViewer(_ vc: UIViewController) {
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
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
            DispatchQueue.main.async { self?.collectionView?.reloadData() }
        }.resume()
    }
}
