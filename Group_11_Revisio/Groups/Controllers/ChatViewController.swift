//
//  ChatViewController.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 27/11/25.
//

import UIKit
import MessageKit
import InputBarAccessoryView

class ChatViewController: MessagesViewController {
    
    var group: Group?
    var groupName: String = ""
    
    // MARK: - Senders
    let currentUser = ChatSender(
        senderId: "me",
        displayName: "Chirag"
    )

    let otherUsers: [String: ChatSender] = [
        "ashika": ChatSender(senderId: "ashika", displayName: "Ashika"),
        "mithil": ChatSender(senderId: "mithil", displayName: "Mithil"),
        "ayaana": ChatSender(senderId: "ayaana", displayName: "Ayaana")
    ]
    
    // MARK: - MessageKit data
    private let otherUser = ChatSender(senderId: "other", displayName: "User")
    private var chatMessages: [ChatMessage] = []
    
    //Mic symbol before send button
    private lazy var micButton: InputBarButtonItem = {
        let item = InputBarButtonItem()
        item.image = UIImage(systemName: "mic.fill")
        item.tintColor = .systemGray
        item.setSize(CGSize(width: 36, height: 36), animated: false)
        return item
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
        chatMessages = [

            // Ashika
            ChatMessage(
                sender: otherUsers["ashika"]!,
                messageId: UUID().uuidString,
                sentDate: Date(timeIntervalSinceNow: -3600),
                kind: .text("Hey everyone 👋")
            ),
            ChatMessage(
                sender: otherUsers["ashika"]!,
                messageId: UUID().uuidString,
                sentDate: Date(timeIntervalSinceNow: -3500),
                kind: .text("Did anyone finish the DBMS assignment?")
            ),
            // Mithil
            ChatMessage(
                sender: otherUsers["mithil"]!,
                messageId: UUID().uuidString,
                sentDate: Date(timeIntervalSinceNow: -3200),
                kind: .text("Almost done, just revising the last question.")
            ),
            // You
            ChatMessage(
                sender: currentUser,
                messageId: UUID().uuidString,
                sentDate: Date(timeIntervalSinceNow: -3000),
                kind: .text("Same here, planning to submit tonight.")
            ),
            // Ayaana
            ChatMessage(
                sender: otherUsers["ayaana"]!,
                messageId: UUID().uuidString,
                sentDate: Date(timeIntervalSinceNow: -2800),
                kind: .text("Guys don’t forget statistics viva tomorrow")
            ),
            // You
            ChatMessage(
                sender: currentUser,
                messageId: UUID().uuidString,
                sentDate: Date(timeIntervalSinceNow: -2600),
                kind: .text("Oh right, thanks for the reminder 👍🏻")
            )
        ]
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: false)
        
        // Default: show mic button
        messageInputBar.setStackViewItems([micButton], forStack: .right, animated: false)
        messageInputBar.setRightStackViewWidthConstant(to: 42, animated: false)
        
        // Style input bar (iMessage-like)
        messageInputBar.inputTextView.placeholder = "Message"
        messageInputBar.inputTextView.font = UIFont.systemFont(ofSize: 16)
        messageInputBar.sendButton.setTitle("", for: .normal)
        messageInputBar.sendButton.setImage(
            UIImage(systemName: "arrow.up.circle.fill"),
            for: .normal
        )
        messageInputBar.sendButton.tintColor = .systemBlue
        messageInputBar.sendButton.setSize(
            CGSize(width: 48, height: 48),
            animated: true
        )
        
        // MARK: - iMessage input bar appearance

        messageInputBar.backgroundView.backgroundColor = .clear
        messageInputBar.backgroundView.layer.shadowColor = UIColor.clear.cgColor
        // Capsule text field
        let tv = messageInputBar.inputTextView
        tv.backgroundColor = UIColor.secondarySystemBackground
        tv.layer.cornerRadius = 20
        tv.layer.masksToBounds = true
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.textContainerInset = UIEdgeInsets(
            top: 10,
            left: 14,
            bottom: 10,
            right: 14
        )

        // Reduce overall bar height (THIS is the missing magic)
        messageInputBar.padding.top = 6
        messageInputBar.padding.bottom = 6
        messageInputBar.padding.left = 8
        messageInputBar.padding.right = 8
        messageInputBar.middleContentViewPadding.right = 6
        
        // initial inset
        view.layoutIfNeeded()
        
        navigationItem.title = groupName
        navigationItem.largeTitleDisplayMode = .never

        let titleButton = UIButton(type: .system)

        let chevron = UIImage(systemName: "chevron.right")
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)

        titleButton.setImage(chevron?.withConfiguration(config), for: .normal)
        let groupTitle = group?.name ?? groupName
        titleButton.setTitle("  \(groupTitle)", for: .normal)
        titleButton.tintColor = .systemBlue
        titleButton.setTitleColor(.systemBlue, for: .normal)
        titleButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)

        titleButton.semanticContentAttribute = .forceRightToLeft
        titleButton.imageEdgeInsets = UIEdgeInsets(top: 1, left: 0, bottom: 0, right: -6)

        titleButton.addTarget(self, action: #selector(groupTitleTapped), for: .touchUpInside)

        navigationItem.titleView = titleButton
        
        messagesCollectionView.scrollsToTop = false
        messagesCollectionView.contentInsetAdjustmentBehavior = .always
        
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
        navigationController?.pushViewController(settingsVC, animated: true)
        settingsVC.delegate = navigationController?.viewControllers
            .first(where: { $0 is GroupsViewController }) as? LeaveGroupDelegate
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
    
extension ChatViewController: MessagesDataSource {
        
        var currentSender: SenderType {
            return currentUser
        }
        
        func numberOfSections(
            in messagesCollectionView: MessagesCollectionView
        ) -> Int {
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

//    func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
//        guard indexPath.section + 1 < chatMessages.count else { return false }
//        return chatMessages[indexPath.section].sender.senderId ==
//               chatMessages[indexPath.section + 1].sender.senderId
//    }
    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section - 1 >= 0 else { return false }
        return chatMessages[indexPath.section].sender.senderId ==
               chatMessages[indexPath.section - 1].sender.senderId
    }
}

extension ChatViewController: MessagesLayoutDelegate {
    
    func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        
        return CGSize(width: 28, height: 28)
    }
        
    func messageTopLabelHeight(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> CGFloat {
        
        // Your messages → no name
        if message.sender.senderId == currentUser.senderId {
            return 0
        }
        
        // First message OR sender changed → show name
        if indexPath.section == 0 || !isPreviousMessageSameSender(at: indexPath) {
            return 16
        }
        
        return 0
    }
    
    func messageTopLabelInset(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> UIEdgeInsets {
        
        if message.sender.senderId != currentUser.senderId,
           (indexPath.section == 0 || !isPreviousMessageSameSender(at: indexPath)) {
            
            return UIEdgeInsets(top: 6, left: 12, bottom: 2, right: 12)
        }
        
        return .zero
    }
    
}

extension ChatViewController: MessagesDisplayDelegate {

    func backgroundColor(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> UIColor {

        if message.sender.senderId == currentUser.senderId {
            return .systemBlue   // outgoing (you)
        } else {
            return .systemGray5  // incoming
        }
    }

    func textColor(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> UIColor {

        if message.sender.senderId == currentUser.senderId {
            return .white
        } else {
            return .label
        }
    }
    
    func messageTopLabelAttributedText(
        for message: MessageType,
        at indexPath: IndexPath
    ) -> NSAttributedString? {

        if message.sender.senderId == currentUser.senderId {
            return nil
        }

        if isPreviousMessageSameSender(at: indexPath) {
            return nil
        }

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

        switch message.sender.senderId {
        case "me":
            avatarView.image = UIImage(named: "pfp_chirag")
        case "ashika":
            avatarView.image = UIImage(named: "pfp_ashika")
        case "mithil":
            avatarView.image = UIImage(named: "pfp_mithil")
        case "ayaana":
            avatarView.image = UIImage(named: "pfp_ayaana")
        default:
            avatarView.image = UIImage(systemName: "person.circle.fill")
        }

        avatarView.layer.cornerRadius = 14
        avatarView.clipsToBounds = true
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {

    func inputBar(
        _ inputBar: InputBarAccessoryView,
        didPressSendButtonWith text: String
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

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

        // After send → show mic again
        inputBar.setStackViewItems([micButton], forStack: .right, animated: true)
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

extension ChatViewController: LeaveGroupDelegate {
    
    func didLeaveGroup(_ group: Group) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    func didUpdateGroup(_ group: Group) {
            self.group = group

            let updatedName = group.name

            if let titleButton = navigationItem.titleView as? UIButton {
                titleButton.setTitle("  \(updatedName)", for: .normal)
            } else {
                navigationItem.title = updatedName
            }
        }
}
