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
    
    var group: Group!
    
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
                kind: .text("Guys don’t forget statistics viva tomorrow 😭")
            ),
            // You
            ChatMessage(
                sender: currentUser,
                messageId: UUID().uuidString,
                sentDate: Date(timeIntervalSinceNow: -2600),
                kind: .text("Oh damn, thanks for the reminder 💀")
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
        titleButton.setTitle(group.name, for: .normal)
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

    func avatarSize(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> CGSize {
        return isPreviousMessageSameSender(at: indexPath)
            ? .zero
            : CGSize(width: 28, height: 28)
    }

    func messagePadding(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets {
        
        return UIEdgeInsets(top: 1, left: 8, bottom: 1, right: 8)
    }
    
    func messageTopLabelHeight(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> CGFloat {

        if message.sender.senderId == currentUser.senderId {
            return 0
        }

        if isPreviousMessageSameSender(at: indexPath) {
            return 0
        }

        return 14
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

    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        // Your messages → no avatar
            if message.sender.senderId == currentUser.senderId {
                avatarView.isHidden = true
                return
            }

            avatarView.isHidden = false

            switch message.sender.senderId {
            case "ashika":
                avatarView.image = UIImage(named: "pfp_ashika")
            case "mithil":
                avatarView.image = UIImage(named: "pfp_mithil")
            case "ayaana":
                avatarView.image = UIImage(named: "pfp_ayaana")
            case "chirag":
                avatarView.image = UIImage(named: "pfp_chirag")
            default:
                avatarView.image = UIImage(systemName: "person.circle.fill")
            }
        avatarView.layer.cornerRadius = avatarView.bounds.width / 2
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
}
