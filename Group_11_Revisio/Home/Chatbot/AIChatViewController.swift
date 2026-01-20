//
//  AIChatViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 17/01/26.
//


import UIKit
import MessageKit
import InputBarAccessoryView
import UniformTypeIdentifiers

class AIChatViewController: MessagesViewController {
    
    // MARK: - Properties
    
    // Distinct Senders
    let currentUser = AIChatSender(senderId: "user_current", displayName: "Me")
    let aiAgent = AIChatSender(senderId: "ai_exora_agent", displayName: "Exora")
    
    // Data Source
    var aiMessages: [AIChatMessage] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMessageKit()
        setupInputBar()
        
        // Initial Greeting
        let greeting = AIChatMessage(
            sender: aiAgent,
            messageId: UUID().uuidString,
            sentDate: Date(),
            kind: .text("Hello! I'm Exora, your AI assistant. You can send me text or upload files for analysis.")
        )
        insertMessage(greeting)
        
        // Set initial title
        self.title = "Exora"
    }
    
    // MARK: - Setup
    
    private func setupMessageKit() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        // Aesthetics
        messagesCollectionView.backgroundColor = .systemBackground
        scrollsToLastItemOnKeyboardBeginsEditing = true
        
        // Ensure avatar size is set for incoming messages
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.textMessageSizeCalculator.incomingAvatarSize = CGSize(width: 35, height: 35)
        }
    }
    
    private func setupInputBar() {
        messageInputBar.delegate = self
        messageInputBar.inputTextView.placeholder = "  Message Exora..."
        
        // Style Send Button
        messageInputBar.sendButton.setTitleColor(.systemBlue, for: .normal)
        messageInputBar.sendButton.setTitleColor(.systemGray, for: .disabled)
        
        // Style Input Field
        messageInputBar.inputTextView.layer.cornerRadius = 18
        messageInputBar.inputTextView.layer.borderWidth = 1.0
        messageInputBar.inputTextView.layer.borderColor = UIColor.systemGray5.cgColor
        messageInputBar.inputTextView.backgroundColor = .systemGray6
        
        // Configure the Upload Button (Plus Icon)
        configureInputBarItems()
    }
    
    private func configureInputBarItems() {
        let plusButton = InputBarButtonItem()
        
        let configuration = UIImage.SymbolConfiguration(weight: .semibold)
        plusButton.setImage(UIImage(systemName: "plus", withConfiguration: configuration), for: .normal)
        plusButton.tintColor = .white
        plusButton.backgroundColor = .clear
        
        let buttonSize: CGFloat = 32
        plusButton.setSize(CGSize(width: buttonSize - 4, height: buttonSize), animated: false)
        plusButton.layer.cornerRadius = buttonSize / 2
        plusButton.clipsToBounds = true
        
        plusButton.addTarget(self, action: #selector(handleUploadTap), for: .touchUpInside)
        
        plusButton.spacing = .fixed(16)
        
        messageInputBar.leftStackView.alignment = .center
        
        messageInputBar.setStackViewItems([plusButton], forStack: .left, animated: false)
        
        messageInputBar.setLeftStackViewWidthConstant(to: buttonSize + 16, animated: false)
    }
    
    // MARK: - Actions
    
    @objc func handleUploadTap() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
            self.presentPhotoPicker()
        }))
        
        alert.addAction(UIAlertAction(title: "Document", style: .default, handler: { _ in
            self.presentDocumentPicker()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    // MARK: - Helpers
    
    func insertMessage(_ message: AIChatMessage) {
        aiMessages.append(message)
        messagesCollectionView.performBatchUpdates({
            messagesCollectionView.insertSections([aiMessages.count - 1])
            if aiMessages.count >= 2 {
                messagesCollectionView.reloadSections([aiMessages.count - 2])
            }
        }, completion: { [weak self] _ in
            self?.messagesCollectionView.scrollToLastItem(animated: true)
        })
    }
    
    func fetchAIResponse(for text: String) {
        self.title = "Exora is typing..."
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            let responseText = "I received your message: \"\(text)\". Processing..."
            let aiMsg = AIChatMessage(sender: self.aiAgent, messageId: UUID().uuidString, sentDate: Date(), kind: .text(responseText))
            self.insertMessage(aiMsg)
            
            self.title = "Exora"
        }
    }
}

// MARK: - MessagesDataSource
extension AIChatViewController: MessagesDataSource {
    
    var currentSender: SenderType {
        return currentUser
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return aiMessages.count
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return aiMessages[indexPath.section]
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 4 == 0 {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return NSAttributedString(
                string: formatter.string(from: message.sentDate),
                attributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.systemGray]
            )
        }
        return nil
    }
}

// MARK: - MessagesDisplayDelegate
extension AIChatViewController: MessagesDisplayDelegate {
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .systemBlue : .systemGray5
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .label
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        if isFromCurrentSender(message: message) {
            avatarView.isHidden = true
        } else {
            avatarView.isHidden = false
            avatarView.backgroundColor = .clear
            avatarView.image = UIImage(named: "Chatbot")
        }
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
}

// MARK: - MessagesLayoutDelegate
extension AIChatViewController: MessagesLayoutDelegate {
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return indexPath.section % 4 == 0 ? 18 : 0
    }
}

// MARK: - InputBarAccessoryViewDelegate
extension AIChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let userMsg = AIChatMessage(sender: currentUser, messageId: UUID().uuidString, sentDate: Date(), kind: .text(text))
        insertMessage(userMsg)
        inputBar.inputTextView.text = ""
        fetchAIResponse(for: text)
    }
}

// MARK: - File & Media Handling
extension AIChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate {
    
    func presentPhotoPicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func presentDocumentPicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .text, .image], asCopy: true)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let _ = info[.originalImage] as? UIImage {
            let userMsg = AIChatMessage(sender: currentUser, messageId: UUID().uuidString, sentDate: Date(), kind: .text("[Sent an Image]"))
            insertMessage(userMsg)
            fetchAIResponse(for: "I just uploaded an image.")
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        let filename = url.lastPathComponent
        let userMsg = AIChatMessage(sender: currentUser, messageId: UUID().uuidString, sentDate: Date(), kind: .text("[Sent Document: \(filename)]"))
        insertMessage(userMsg)
        fetchAIResponse(for: "I just uploaded a document named \(filename).")
    }
}
