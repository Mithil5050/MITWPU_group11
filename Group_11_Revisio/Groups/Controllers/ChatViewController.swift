//
//  ChatViewController.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 27/11/25.
//

import UIKit
import MessageKit
import InputBarAccessoryView

class ChatViewController: MessagesViewController, GroupUpdateDelegate {
    
    weak var updateDelegate: GroupUpdateDelegate?
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
        
        //MARK: - Message Input Bar

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
        textView.textContainerInset = UIEdgeInsets(
            top: 10,
            left: 14,
            bottom: 10,
            right: 14
        )

        // Input bar padding (THIS fixes height)
        messageInputBar.padding.top = 8
        messageInputBar.padding.bottom = 8
        messageInputBar.padding.left = 12
        messageInputBar.padding.right = 12
        messageInputBar.middleContentViewPadding.right = 8

        // Send Button (large like iMessage)
        let sendButton = messageInputBar.sendButton
        sendButton.setTitle(nil, for: .normal)
        sendButton.setImage(
            UIImage(systemName: "arrow.up.circle.fill"),
            for: .normal
        )
        sendButton.tintColor = .systemBlue

        // Attach Button (left)
        let attachButton = InputBarButtonItem()
        attachButton.image = UIImage(systemName: "plus")
        attachButton.tintColor = .systemBlue
        attachButton.setSize(CGSize(width: 32, height: 32), animated: false)
        attachButton.onTouchUpInside { _ in }

        // Clear left stack first
        messageInputBar.leftStackView.arrangedSubviews.forEach {
            messageInputBar.leftStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        // Add attach button properly
        messageInputBar.leftStackView.addArrangedSubview(attachButton)

        // Width + alignment
        messageInputBar.leftStackView.alignment = .center
        messageInputBar.leftStackView.distribution = .equalCentering
        messageInputBar.setLeftStackViewWidthConstant(to: 40, animated: false)
        
        // Default right = mic
        messageInputBar.setStackViewItems([micButton], forStack: .right, animated: false)
        messageInputBar.setRightStackViewWidthConstant(to: 40, animated: false)
        
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

        
        //MARK: - Group settings from title
        // initial inset
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
    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section - 1 >= 0 else { return false }
        return chatMessages[indexPath.section].sender.senderId ==
               chatMessages[indexPath.section - 1].sender.senderId
    }
}

extension ChatViewController: MessagesLayoutDelegate {
        
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
    
    func messageTopLabelAlignment(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> LabelAlignment? {

        if message.sender.senderId != currentUser.senderId,
           (indexPath.section == 0 || !isPreviousMessageSameSender(at: indexPath)) {

            return LabelAlignment(
                textAlignment: .left,
                textInsets: UIEdgeInsets(top: 6, left: 12, bottom: 2, right: 12)
            )
        }

        return nil
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
        }

        updateDelegate?.didUpdateGroup(group)
    }
}


