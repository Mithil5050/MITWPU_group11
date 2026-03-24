//
//  ChatViewController.swift
//  Group_11_Revisio
//

import UIKit
import MessageKit
import InputBarAccessoryView
import Supabase
import UniformTypeIdentifiers

class ChatViewController: MessagesViewController, GroupUpdateDelegate {

    weak var updateDelegate: GroupUpdateDelegate?
    var group: Group?
    var groupName: String = ""

    var currentUser = ChatSender(senderId: "unknown", displayName: "Me")
    private var chatMessages: [ChatMessage] = []
    private var senderNameCache: [String: String] = [:]
    private var realtimeChannel: RealtimeChannelV2?

    private lazy var micButton: InputBarButtonItem = {
        let item = InputBarButtonItem()
        item.image     = UIImage(systemName: "mic.fill")
        item.tintColor = .systemGray
        item.setSize(CGSize(width: 36, height: 36), animated: false)
        return item
    }()

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

    // input bar layout + attach/mic buttons
    private func setupInputBar() {
        messageInputBar.backgroundView.backgroundColor = .systemBackground
        messageInputBar.separatorLine.isHidden = true

        let tv = messageInputBar.inputTextView
        tv.placeholder              = "Message"
        tv.font                     = UIFont.systemFont(ofSize: 17)
        tv.backgroundColor          = UIColor.secondarySystemBackground
        tv.layer.cornerRadius       = 20
        tv.layer.masksToBounds      = true
        tv.textContainerInset       = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)

        messageInputBar.padding    = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        messageInputBar.middleContentViewPadding.right = 8

        let send = messageInputBar.sendButton
        send.setTitle(nil, for: .normal)
        send.setImage(UIImage(systemName: "arrow.up.circle.fill")?
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

    // tappable group name in nav bar → opens group settings
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

    // shows study material / photo / file options
    private func showAttachmentSheet() {
        let sheet = UIAlertController(title: "Send Attachment",
                                      message: nil,
                                      preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Study Material",
                                      style: .default) { [weak self] _ in
            self?.openStudyMaterialPicker()
        })
        sheet.addAction(UIAlertAction(title: "Photo Library",
                                      style: .default) { [weak self] _ in
            self?.openPhotoLibrary()
        })
        sheet.addAction(UIAlertAction(title: "Files",
                                      style: .default) { [weak self] _ in
            self?.openDocumentPicker()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .destructive))
        present(sheet, animated: true)
    }

    private func openStudyMaterialPicker() {
        let folderVC = AttachmentFolderViewController()
        folderVC.sendDelegate = self
        let nav = UINavigationController(rootViewController: folderVC)
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
        let types: [UTType] = [.pdf, .plainText, .data,
                               .spreadsheet, .presentation, .image]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    // fetch history from DB and build bubble list
    private func loadMessages() async {
        guard let groupId = group?.id else { return }
        await DataManager.shared.loadMessages(for: groupId)
        let raw = DataManager.shared.groupMessages[groupId] ?? []

        var built: [ChatMessage] = []
        for msg in raw {
            let name: String
            if msg.senderId.uuidString == currentUser.senderId {
                name = currentUser.displayName
            } else {
                name = await fetchDisplayName(for: msg.senderId.uuidString)
            }
            let sender = ChatSender(senderId: msg.senderId.uuidString, displayName: name)
            built.append(makeChatMessage(from: msg, sender: sender))
        }
        built.sort { $0.sentDate < $1.sentDate }

        await MainActor.run {
            chatMessages = built
            messagesCollectionView.reloadData()
            messagesCollectionView.scrollToLastItem(animated: false)
        }
    }

    // routes a DB row to the right MessageKind (link / doc / plain text)
    private func makeChatMessage(from msg: Message, sender: ChatSender) -> ChatMessage {
        let isOutgoing = msg.senderId.uuidString == currentUser.senderId

        if let urlStr = msg.fileUrl, msg.fileType == "link",
           let url = URL(string: urlStr) {
            return ChatMessage(sender: sender, messageId: msg.id.uuidString,
                               sentDate: msg.createdAt,
                               kind: .attributedText(
                                   linkAttr(text: msg.content, url: url, isOutgoing: isOutgoing)
                               ))
        }

        if msg.fileType == "document", let fn = msg.fileName, !fn.isEmpty {
            return ChatMessage(sender: sender, messageId: msg.id.uuidString,
                               sentDate: msg.createdAt,
                               kind: .attributedText(
                                   docAttr(fileName: fn, isOutgoing: isOutgoing)
                               ))
        }

        return ChatMessage(sender: sender, messageId: msg.id.uuidString,
                           sentDate: msg.createdAt, kind: .text(msg.content))
    }

    // coloured underlined link, white on outgoing / blue on incoming
    private func linkAttr(text: String, url: URL, isOutgoing: Bool) -> NSAttributedString {
        let c = isOutgoing ? UIColor.white : UIColor.systemBlue
        let a = NSMutableAttributedString(string: text)
        let r = NSRange(text.startIndex..., in: text)
        a.addAttributes([.link: url, .foregroundColor: c,
                         .underlineColor: c,
                         .underlineStyle: NSUnderlineStyle.single.rawValue], range: r)
        return a
    }

    // doc.fill icon + filename label
    private func docAttr(fileName: String, isOutgoing: Bool) -> NSAttributedString {
        let cfg  = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let tint = isOutgoing ? UIColor.white : UIColor.systemBlue
        let att  = NSTextAttachment()
        att.image  = UIImage(systemName: "doc.fill", withConfiguration: cfg)?
            .withTintColor(tint, renderingMode: .alwaysOriginal)
        att.bounds = CGRect(x: 0, y: -2, width: 16, height: 18)

        let result = NSMutableAttributedString(attachment: att)
        result.append(NSAttributedString(string: " \(fileName)", attributes: [
            .foregroundColor: isOutgoing ? UIColor.white : UIColor.label,
            .font: UIFont.systemFont(ofSize: 15, weight: .medium)
        ]))
        return result
    }

    // username lookup with local cache
    private func fetchDisplayName(for senderId: String) async -> String {
        if let cached = senderNameCache[senderId] { return cached }
        do {
            struct Profile: Decodable { let username: String? }
            let result: [Profile] = try await SupabaseManager.shared.client
                .from("profiles").select("username")
                .eq("id", value: senderId).limit(1).execute().value
            let name = result.first?.username ?? "User"
            senderNameCache[senderId] = name
            return name
        } catch { return "User" }
    }

    // live incoming messages via Supabase realtime
    private func subscribeToMessages() async {
        guard let groupId = group?.id else { return }
        let channel = await SupabaseManager.shared.client.realtimeV2
            .channel("messages:\(groupId)")
        let changes = await channel.postgresChange(
            InsertAction.self, schema: "public", table: "messages",
            filter: "group_id=eq.\(groupId)"
        )
        await channel.subscribe()
        realtimeChannel = channel

        for await change in changes {
            let row = change.record
            guard
                let id           = row["id"]?.stringValue,
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
                kind = .attributedText(docAttr(fileName: fn, isOutgoing: false))
            } else {
                kind = .text(content)
            }

            let msg = ChatMessage(sender: sender, messageId: id, sentDate: date, kind: kind)
            await MainActor.run {
                chatMessages.append(msg)
                messagesCollectionView.reloadData()
                messagesCollectionView.scrollToLastItem(animated: true)
            }
        }
    }

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
        Task { [weak self] in await self?.realtimeChannel?.unsubscribe() }
    }
}

// MARK: - AttachmentSendDelegate

extension ChatViewController: AttachmentSendDelegate {

    func didSendAttachments(_ items: [SentAttachment]) {
        guard let groupId = group?.id else { return }

        for att in items {
            // optimistic bubble before server confirms
            let kind = MessageKind.attributedText(docAttr(fileName: att.displayName, isOutgoing: true))
            chatMessages.append(ChatMessage(sender: currentUser,
                                            messageId: UUID().uuidString,
                                            sentDate: Date(),
                                            kind: kind))
            Task {
                do {
                    try await SupabaseManager.shared.sendAttachment(
                        groupId: groupId,
                        senderId: currentUser.senderId,
                        attachment: att)
                } catch { print("❌ sendAttachment error: \(error)") }
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

        // optimistic photo bubble
        let kind = MessageKind.photo(ImageMediaItem(image: image))
        chatMessages.append(ChatMessage(sender: currentUser,
                                        messageId: UUID().uuidString,
                                        sentDate: Date(),
                                        kind: kind))
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: true)

        Task {
            do {
                let path      = "\(groupId)/\(UUID().uuidString).jpg"
                let publicUrl = try await SupabaseManager.shared.uploadFile(
                    bucket: "group-media", path: path,
                    data: imgData, contentType: "image/jpeg")

                struct ImageInsert: Encodable {
                    let group_id: UUID; let sender_id: UUID; let content: String
                    let file_url: String; let file_name: String; let file_type: String
                }
                guard let gid = UUID(uuidString: groupId),
                      let sid = UUID(uuidString: currentUser.senderId) else { return }
                try await SupabaseManager.shared.client.from("messages")
                    .insert(ImageInsert(group_id: gid, sender_id: sid,
                                        content: "📷 Image",
                                        file_url: publicUrl,
                                        file_name: "Image",
                                        file_type: "image"))
                    .execute()
            } catch { print("❌ image upload error: \(error)") }
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
        guard let url     = urls.first,
              let groupId = group?.id else { return }
        let fileName = url.lastPathComponent

        // optimistic doc bubble
        let kind = MessageKind.attributedText(docAttr(fileName: fileName, isOutgoing: true))
        chatMessages.append(ChatMessage(sender: currentUser,
                                        messageId: UUID().uuidString,
                                        sentDate: Date(),
                                        kind: kind))
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: true)

        Task {
            do {
                let data      = try Data(contentsOf: url)
                let path      = "\(groupId)/\(UUID().uuidString)_\(fileName)"
                let publicUrl = try await SupabaseManager.shared.uploadFile(
                    bucket: "group-media", path: path,
                    data: data, contentType: "application/octet-stream")

                struct DocInsert: Encodable {
                    let group_id: UUID; let sender_id: UUID; let content: String
                    let file_url: String; let file_name: String; let file_type: String
                }
                guard let gid = UUID(uuidString: groupId),
                      let sid = UUID(uuidString: currentUser.senderId) else { return }
                try await SupabaseManager.shared.client.from("messages")
                    .insert(DocInsert(group_id: gid, sender_id: sid,
                                      content: fileName,
                                      file_url: publicUrl,
                                      file_name: fileName,
                                      file_type: "document"))
                    .execute()
            } catch { print("❌ document upload error: \(error)") }
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

    func messageTopLabelHeight(for message: MessageType,
                                at indexPath: IndexPath,
                                in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if message.sender.senderId == currentUser.senderId { return 0 }
        return (indexPath.section == 0 || !isPreviousMessageSameSender(at: indexPath)) ? 16 : 0
    }

    func messageTopLabelAlignment(for message: MessageType,
                                   at indexPath: IndexPath,
                                   in messagesCollectionView: MessagesCollectionView) -> LabelAlignment? {
        guard message.sender.senderId != currentUser.senderId else { return nil }
        guard indexPath.section == 0 || !isPreviousMessageSameSender(at: indexPath) else { return nil }
        return LabelAlignment(textAlignment: .left,
                              textInsets: UIEdgeInsets(top: 0, left: 48, bottom: 4, right: 0))
    }

    func messagePadding(for message: MessageType,
                        at indexPath: IndexPath,
                        in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets {
        return UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    }
}

// MARK: - MessagesDisplayDelegate

extension ChatViewController: MessagesDisplayDelegate {

    func backgroundColor(for message: MessageType,
                          at indexPath: IndexPath,
                          in messagesCollectionView: MessagesCollectionView) -> UIColor {
        message.sender.senderId == currentUser.senderId ? .systemBlue : .systemGray5
    }

    func textColor(for message: MessageType,
                   at indexPath: IndexPath,
                   in messagesCollectionView: MessagesCollectionView) -> UIColor {
        message.sender.senderId == currentUser.senderId ? .white : .label
    }

    // tintColor drives link tap color inside message labels
    func configureMessageLabel(_ messageLabel: MessageLabel,
                               for message: MessageType,
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

    func configureAvatarView(_ avatarView: AvatarView,
                              for message: MessageType,
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

    func inputBar(_ inputBar: InputBarAccessoryView,
                  didPressSendButtonWith text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue)
        let r      = NSRange(trimmed.startIndex..., in: trimmed)
        let isLink = !(detector?.matches(in: trimmed, options: [], range: r) ?? []).isEmpty

        let kind: MessageKind
        if isLink {
            let urlStr = trimmed.hasPrefix("http") ? trimmed : "https://\(trimmed)"
            if let url = URL(string: urlStr) {
                kind = .attributedText(linkAttr(text: trimmed, url: url, isOutgoing: true))
            } else { kind = .text(trimmed) }
        } else {
            kind = .text(trimmed)
        }

        chatMessages.append(ChatMessage(sender: currentUser,
                                        messageId: UUID().uuidString,
                                        sentDate: Date(), kind: kind))
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: true)
        inputBar.inputTextView.text = ""
        inputBar.setStackViewItems([micButton], forStack: .right, animated: true)

        guard let groupId = group?.id else { return }
        Task {
            do {
                try await SupabaseManager.shared.sendMessage(
                    groupId: groupId, senderId: currentUser.senderId, text: trimmed)
            } catch { print("❌ sendMessage error: \(error)") }
        }
    }

    func inputBar(_ inputBar: InputBarAccessoryView,
                  textViewTextDidChangeTo text: String) {
        inputBar.setStackViewItems(
            text.isEmpty ? [micButton] : [inputBar.sendButton],
            forStack: .right, animated: true
        )
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

// MARK: - MessageCellDelegate  (tap on doc / image bubbles)

extension ChatViewController: MessageCellDelegate {

    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let message = chatMessages[indexPath.section]

        switch message.kind {
        case .photo(let media):
            guard let image = media.image else { return }
            let vc  = MediaPreviewViewController()
            vc.image = image
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)

        case .attributedText(let attr):
            // Detect doc bubble by checking for a URL link attribute
            var foundURL: URL? = nil
            attr.enumerateAttribute(.link, in: NSRange(location: 0, length: attr.length)) { val, _, _ in
                if let url = val as? URL { foundURL = url }
            }
            if let url = foundURL {
                // Link bubble — open in Safari
                UIApplication.shared.open(url)
                return
            }
            // Doc bubble — look up the stored file_url for this message
            openDocumentFromMessage(at: indexPath.section)

        default:
            break
        }
    }

    private func openDocumentFromMessage(at section: Int) {
        guard let groupId = group?.id else { return }
        let raw = DataManager.shared.groupMessages[groupId] ?? []
        // match by position — chatMessages and raw are both sorted by date
        guard section < raw.count else { return }
        let msg = raw[section]
        guard let urlString = msg.fileUrl, !urlString.isEmpty,
              let url = URL(string: urlString) else { return }

        if msg.fileType == "image" {
            // Download and present in MediaPreviewViewController
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data = data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    let vc  = MediaPreviewViewController()
                    vc.image = img
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    self?.present(nav, animated: true)
                }
            }.resume()
        } else if msg.fileType == "document" {
            // Download to temp file and open in DocumentPreviewViewController
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data = data else { return }
                let tmp = FileManager.default.temporaryDirectory
                    .appendingPathComponent(msg.fileName ?? "document")
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
}

// MARK: - ImageMediaItem

private struct ImageMediaItem: MediaItem {
    var url: URL? { nil }
    var image: UIImage?
    var placeholderImage: UIImage { UIImage(systemName: "photo") ?? UIImage() }
    var size: CGSize { CGSize(width: 200, height: 150) }
    init(image: UIImage) { self.image = image }
}
