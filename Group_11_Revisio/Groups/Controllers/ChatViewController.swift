//
//  ChatViewController.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 27/11/25.
//
import UIKit
import MessageKit
import InputBarAccessoryView
import Supabase

class ChatViewController: MessagesViewController, GroupUpdateDelegate {

    weak var updateDelegate: GroupUpdateDelegate?
    var group: Group?
    var groupName: String = ""

    // MARK: - Senders
    var currentUser: ChatSender = ChatSender(senderId: "unknown", displayName: "Me")

    // MARK: - MessageKit data
    private var chatMessages: [ChatMessage] = []
    private var senderNameCache: [String: String] = [:]
    private var realtimeChannel: RealtimeChannelV2?

    // Mic symbol before send button
    private lazy var micButton: InputBarButtonItem = {
        let item = InputBarButtonItem()
        item.image = UIImage(systemName: "mic.fill")
        item.tintColor = .systemGray
        item.setSize(CGSize(width: 36, height: 36), animated: false)
        return item
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set current user from Supabase auth
        if let user = SupabaseManager.shared.client.auth.currentUser {
            currentUser = ChatSender(
                senderId: user.id.uuidString,
                displayName: user.email ?? "Me"
            )
        }

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self

        // MARK: - Message Input Bar
        messageInputBar.backgroundView.backgroundColor = .systemBackground
        messageInputBar.backgroundView.layer.borderWidth = 0
        messageInputBar.separatorLine.isHidden = true

        // Text View
        let textView = messageInputBar.inputTextView
        textView.placeholder = "Message"
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.backgroundColor = UIColor.secondarySystemBackground
        textView.layer.cornerRadius = 20
        textView.layer.masksToBounds = true
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)

        // Input bar padding
        messageInputBar.padding.top = 8
        messageInputBar.padding.bottom = 8
        messageInputBar.padding.left = 12
        messageInputBar.padding.right = 12
        messageInputBar.middleContentViewPadding.right = 8

        // Send Button
        let sendButton = messageInputBar.sendButton
        sendButton.setTitle(nil, for: .normal)
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendButton.tintColor = .systemBlue

        // Attach Button (left)
        let attachButton = InputBarButtonItem()
        attachButton.image = UIImage(systemName: "plus")
        attachButton.tintColor = .systemBlue
        attachButton.setSize(CGSize(width: 32, height: 32), animated: false)
        attachButton.onTouchUpInside { [weak self] _ in
            self?.openAttachmentPicker()
        }

        messageInputBar.leftStackView.arrangedSubviews.forEach {
            messageInputBar.leftStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        messageInputBar.leftStackView.addArrangedSubview(attachButton)
        messageInputBar.leftStackView.alignment = .center
        messageInputBar.leftStackView.distribution = .equalCentering
        messageInputBar.setLeftStackViewWidthConstant(to: 40, animated: false)

        messageInputBar.setStackViewItems([micButton], forStack: .right, animated: false)
        messageInputBar.setRightStackViewWidthConstant(to: 40, animated: false)

        // Load messages from Supabase
        Task {
            await loadMessages()
            await subscribeToMessages()
        }

        // MARK: - Navigation title
        view.layoutIfNeeded()
        navigationItem.title = groupName
        navigationItem.largeTitleDisplayMode = .never

        let titleButton = UIButton(type: .system)
        let chevron = UIImage(systemName: "chevron.right")
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)

        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.title = group?.name ?? groupName
        buttonConfig.image = chevron?.withConfiguration(symbolConfig)
        buttonConfig.imagePlacement = .trailing
        buttonConfig.imagePadding = 6

        titleButton.configuration = buttonConfig
        titleButton.tintColor = .systemBlue
        titleButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleButton.addTarget(self, action: #selector(groupTitleTapped), for: .touchUpInside)

        navigationItem.titleView = titleButton

        messagesCollectionView.scrollsToTop = false
        messagesCollectionView.contentInsetAdjustmentBehavior = .always
    }

    // MARK: - Load Messages
    private func loadMessages() async {
        guard let groupId = group?.id else { return }

        await DataManager.shared.loadMessages(for: groupId)
        let raw = DataManager.shared.groupMessages[groupId] ?? []

        chatMessages = await withTaskGroup(of: ChatMessage.self) { group in
            var result: [ChatMessage] = []
            for msg in raw {
                group.addTask {
                    let name: String
                    if msg.senderId.uuidString == self.currentUser.senderId {
                        name = self.currentUser.displayName
                    } else {
                        name = await self.fetchDisplayName(for: msg.senderId.uuidString)
                    }
                    let sender = ChatSender(senderId: msg.senderId.uuidString, displayName: name)
                    return ChatMessage(
                        sender: sender,
                        messageId: msg.id.uuidString,
                        sentDate: msg.createdAt,
                        kind: .text(msg.content)
                    )
                }
                for await msg in group { result.append(msg) }
            }
            return result.sorted { $0.sentDate < $1.sentDate }
        }

        await MainActor.run {
            messagesCollectionView.reloadData()
            messagesCollectionView.scrollToLastItem(animated: false)
        }
    }

    // MARK: - Fetch Display Name
    private func fetchDisplayName(for senderId: String) async -> String {
        if let cached = senderNameCache[senderId] { return cached }
        do {
            struct Profile: Decodable { let username: String? }
            let result: [Profile] = try await SupabaseManager.shared.client
                .from("profiles")
                .select("username")
                .eq("id", value: senderId)
                .limit(1)
                .execute()
                .value
            let name = result.first?.username ?? "User"
            senderNameCache[senderId] = name
            return name
        } catch {
            return "User"
        }
    }

    // MARK: - Realtime Subscription
    private func subscribeToMessages() async {
        guard let groupId = group?.id else { return }

        let channel = await SupabaseManager.shared.client.realtimeV2
            .channel("messages:\(groupId)")

        let changes = await channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "messages",
            filter: "group_id=eq.\(groupId)"
        )

        await channel.subscribe()
        realtimeChannel = channel

        for await change in changes {
            let row = change.record
            guard
                let id = row["id"]?.stringValue,
                let senderId = row["sender_id"]?.stringValue,
                let content = row["content"]?.stringValue,
                let createdAtStr = row["created_at"]?.stringValue
            else { continue }

            let date = ISO8601DateFormatter().date(from: createdAtStr) ?? Date()

            // Skip messages the current user just sent (already shown optimistically)
            if senderId == currentUser.senderId { continue }

            let name = await fetchDisplayName(for: senderId)
            let sender = ChatSender(senderId: senderId, displayName: name)
            let newMsg = ChatMessage(
                sender: sender,
                messageId: id,
                sentDate: date,
                kind: .text(content)
            )

            await MainActor.run {
                chatMessages.append(newMsg)
                messagesCollectionView.reloadData()
                messagesCollectionView.scrollToLastItem(animated: true)
            }
        }
    }

    // MARK: - Attachment Picker
    private func openAttachmentPicker() {
        let folderVC = AttachmentFolderViewController()
        let nav = UINavigationController(rootViewController: folderVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @objc private func groupTitleTapped() {
        let storyboard = UIStoryboard(name: "Groups", bundle: nil)

        guard let settingsVC = storyboard.instantiateViewController(
            withIdentifier: "GroupSettingsVC"
        ) as? GroupSettingsViewController else {
            print("ERROR: GroupSettingsVC not found")
            return
        }

        settingsVC.group = group
        settingsVC.updateDelegate = self

        navigationController?.pushViewController(settingsVC, animated: true)
        settingsVC.delegate = navigationController?.viewControllers
            .first(where: { $0 is GroupsViewController }) as? LeaveGroupDelegate
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        Task { [weak self] in
            await self?.realtimeChannel?.unsubscribe()
        }
    }
}

// MARK: - MessagesDataSource
extension ChatViewController: MessagesDataSource {

    var currentSender: SenderType {
        return currentUser
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return chatMessages.count
    }

    func messageForItem(
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> MessageType {
        return chatMessages[indexPath.section]
    }
}

extension ChatViewController {
    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section - 1 >= 0 else { return false }
        return chatMessages[indexPath.section].sender.senderId ==
               chatMessages[indexPath.section - 1].sender.senderId
    }
}

// MARK: - MessagesLayoutDelegate
extension ChatViewController: MessagesLayoutDelegate {

    func messageTopLabelHeight(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> CGFloat {
        if message.sender.senderId == currentUser.senderId { return 0 }
        if indexPath.section == 0 || !isPreviousMessageSameSender(at: indexPath) { return 16 }
        return 0
    }

    func messageTopLabelAlignment(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> LabelAlignment? {
        guard message.sender.senderId != currentUser.senderId else { return nil }
        if indexPath.section == 0 || !isPreviousMessageSameSender(at: indexPath) {
            return LabelAlignment(
                textAlignment: .left,
                textInsets: UIEdgeInsets(top: 0, left: 48, bottom: 4, right: 0)
            )
        }
        return nil
    }
}

// MARK: - MessagesDisplayDelegate
extension ChatViewController: MessagesDisplayDelegate {

    func backgroundColor(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> UIColor {
        return message.sender.senderId == currentUser.senderId ? .systemBlue : .systemGray5
    }

    func textColor(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> UIColor {
        return message.sender.senderId == currentUser.senderId ? .white : .label
    }

    func messageTopLabelAttributedText(
        for message: MessageType,
        at indexPath: IndexPath
    ) -> NSAttributedString? {
        if message.sender.senderId == currentUser.senderId { return nil }
        if isPreviousMessageSameSender(at: indexPath) { return nil }
        return NSAttributedString(
            string: message.sender.displayName,
            attributes: [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: UIColor.secondaryLabel
            ]
        )
    }

    func configureAvatarView(
        _ avatarView: AvatarView,
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) {
        avatarView.isHidden = false

        if message.sender.senderId == currentUser.senderId {
            avatarView.image = UIImage(named: "pfp_default") ?? UIImage(systemName: "person.circle.fill")
        } else {
            let initials = String(message.sender.displayName.prefix(1)).uppercased()
            avatarView.set(avatar: Avatar(image: nil, initials: initials))
        }

        avatarView.layer.cornerRadius = 14
        avatarView.clipsToBounds = true
    }
}

// MARK: - InputBarAccessoryViewDelegate
extension ChatViewController: InputBarAccessoryViewDelegate {

    func inputBar(
        _ inputBar: InputBarAccessoryView,
        didPressSendButtonWith text: String
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Optimistic UI — show immediately
        let msg = ChatMessage(
            sender: currentUser,
            messageId: UUID().uuidString,
            sentDate: Date(),
            kind: .text(trimmed)
        )
        chatMessages.append(msg)
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: true)
        inputBar.inputTextView.text = ""
        inputBar.setStackViewItems([micButton], forStack: .right, animated: true)

        // Send to Supabase
        guard let groupId = group?.id else { return }
        Task {
            do {
                try await SupabaseManager.shared.sendMessage(
                    groupId: groupId,
                    senderId: currentUser.senderId,
                    text: trimmed
                )
            } catch {
                print("❌ Failed to send message: \(error)")
            }
        }
    }

    func inputBar(
        _ inputBar: InputBarAccessoryView,
        textViewTextDidChangeTo text: String
    ) {
        if text.isEmpty {
            inputBar.setStackViewItems([micButton], forStack: .right, animated: true)
        } else {
            inputBar.setStackViewItems([inputBar.sendButton], forStack: .right, animated: true)
        }
    }
}

// MARK: - LeaveGroupDelegate
extension ChatViewController: LeaveGroupDelegate {

    func didLeaveGroup(_ group: Group) {
        navigationController?.popToRootViewController(animated: true)
    }

    func didUpdateGroup(_ group: Group) {
        self.group = group
        if let titleButton = navigationItem.titleView as? UIButton {
            titleButton.setTitle("  \(group.name)", for: .normal)
        }
        updateDelegate?.didUpdateGroup(group)
    }
}
