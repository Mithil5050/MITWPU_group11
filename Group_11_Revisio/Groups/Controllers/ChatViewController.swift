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
    
    // MARK: - MessageKit data
    private let currentUser = ChatSender(senderId: "self", displayName: "Me")
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
            ChatMessage(
                sender: otherUser,
                messageId: UUID().uuidString,
                sentDate: Date(timeIntervalSinceNow: -3600),
                kind: .text("Welcome to the group 👋")
            ),
            ChatMessage(
                sender: currentUser,
                messageId: UUID().uuidString,
                sentDate: Date(timeIntervalSinceNow: -3500),
                kind: .text("Hey everyone!")
            ),
            ChatMessage(
                sender: otherUser,
                messageId: UUID().uuidString,
                sentDate: Date(timeIntervalSinceNow: -3200),
                kind: .text("Assignments due today.")
            )
        ]
        
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: false)
        
        // Default: show mic button
        messageInputBar.setStackViewItems([micButton], forStack: .right, animated: false)
        messageInputBar.setRightStackViewWidthConstant(to: 38, animated: false)
        
        // Style input bar (iMessage-like)
        messageInputBar.inputTextView.placeholder = "Aa"
        messageInputBar.inputTextView.font = UIFont.systemFont(ofSize: 16)
        messageInputBar.sendButton.setTitle("", for: .normal)
        messageInputBar.sendButton.setImage(
            UIImage(systemName: "arrow.up.circle.fill"),
            for: .normal
        )
        messageInputBar.sendButton.tintColor = .systemBlue
        messageInputBar.sendButton.setSize(
            CGSize(width: 36, height: 36),
            animated: false
        )
        
        // initial inset
        view.layoutIfNeeded()
        
        navigationItem.title = group?.name ?? "Group"
        navigationItem.largeTitleDisplayMode = .never
        
        let titleButton = UIButton(type: .system)
        titleButton.setTitle(group?.name ?? "Group", for: .normal)
        titleButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleButton.addTarget(self, action: #selector(groupTitleTapped), for: .touchUpInside)
        
        navigationItem.titleView = titleButton
        
        // iMessage-style input bar appearance
        messageInputBar.backgroundView.backgroundColor = .clear
        messageInputBar.backgroundView.layer.cornerRadius = 18
        messageInputBar.backgroundView.clipsToBounds = true
        
        let blur = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.frame = messageInputBar.backgroundView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        messageInputBar.backgroundView.insertSubview(blurView, at: 0)
        
        messageInputBar.inputTextView.backgroundColor = .clear
        messageInputBar.inputTextView.layer.cornerRadius = 16
        messageInputBar.inputTextView.layer.borderWidth = 0
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(
            top: 8, left: 12, bottom: 8, right: 12
        )
        
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
        settingsVC.delegate = navigationController?.viewControllers.first {
            $0 is GroupsViewController
        } as? LeaveGroupDelegate
        
        navigationController?.pushViewController(settingsVC, animated: true)
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

    // Hide avatars for consecutive messages (iMessage style)
    func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section + 1 < chatMessages.count else { return false }
        return chatMessages[indexPath.section].sender.senderId ==
               chatMessages[indexPath.section + 1].sender.senderId
    }
}

extension ChatViewController: MessagesLayoutDelegate {

    func avatarSize(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> CGSize {
        return isNextMessageSameSender(at: indexPath)
            ? .zero
            : CGSize(width: 28, height: 28)
    }

    func messagePadding(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> UIEdgeInsets {
        return UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)
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

    func configureAvatarView(
        _ avatarView: AvatarView,
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) {
        if message.sender.senderId == currentUser.senderId {
            avatarView.image = UIImage(systemName: "person.fill")
        } else {
            avatarView.image = UIImage(systemName: "person.circle")
        }
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
