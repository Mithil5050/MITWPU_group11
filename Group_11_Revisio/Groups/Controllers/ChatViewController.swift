//
//  ChatViewController.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 27/11/25.
//

import UIKit

class ChatViewController: UIViewController {
    
    // MARK: - IBOutlets (must match storyboard)
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputBarView: UIView!
    @IBOutlet weak var inputBarBottomConstraint: NSLayoutConstraint! // bottom constraint connecting inputBarView to safe area bottom
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var messageTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendButton: UIButton!

    // Placeholder label for the UITextView
    private let placeholderLabel = UILabel()
    // store the original bottom constraint constant so we can restore it
    private var originalInputBarBottomConstant: CGFloat = 0
    // Will be set before pushing/presenting
    var groupName: String?

    // MARK: - Data & config (fileprivate so extensions in this file can access)
    fileprivate var messages: [Message] = [
        // sample messages; yours may come from a DB or API
        Message(text: "Hey! Can you share the notes of Derivatives?", isOutgoing: false, date: Date()),
        Message(text: "Yes sure. Do you need the cheat sheet as well?", isOutgoing: true, date: Date()),
        Message(text: "Yes! That would be of great help.", isOutgoing: false, date: Date())
    ]

    // Minimum/Maximum heights for the growing text view
    fileprivate let textViewMinHeight: CGFloat = 36
    fileprivate let textViewMaxHeight: CGFloat = 120

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Title
        title = groupName ?? "Chat"

        // TableView setup
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60

        // Scroll to bottom initial (after layout)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.scrollToBottom(animated: false)
        }

        // Configure send button image (iMessage-like arrow inside circular background)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        if let image = UIImage(systemName: "arrow.up.circle.fill", withConfiguration: config) {
            sendButton.setImage(image, for: .normal)
        }
        sendButton.tintColor = .systemBlue
        sendButton.adjustsImageWhenHighlighted = false
        sendButton.showsTouchWhenHighlighted = false
        sendButton.setTitle("", for: .normal)
        sendButton.accessibilityLabel = "Send"
        sendButton.accessibilityHint = "Sends the typed message"
        sendButton.isEnabled = false
        sendButton.alpha = 1.0

        // Style inputBarView (keep clear so it visually matches iMessage)
        inputBarView.backgroundColor = .clear
        inputBarView.layer.masksToBounds = false

        // Style message text view to look like iMessage rounded capsule
        messageTextView.backgroundColor = UIColor(white: 0.98, alpha: 1.0)
        messageTextView.layer.cornerRadius = 18
        messageTextView.layer.masksToBounds = true
        messageTextView.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        messageTextView.font = UIFont.systemFont(ofSize: 16)
        messageTextView.textColor = .label
        messageTextView.isScrollEnabled = false
        messageTextView.delegate = self

        // placeholder
        placeholderLabel.text = "iMessage"
        placeholderLabel.font = UIFont.systemFont(ofSize: 16)
        placeholderLabel.textColor = UIColor.systemGray3
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        messageTextView.addSubview(placeholderLabel)
        // Constraints: left & centerY inside textView
        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(equalTo: messageTextView.leadingAnchor, constant: 16),
            placeholderLabel.centerYAnchor.constraint(equalTo: messageTextView.centerYAnchor)
        ])

        // Keyboard observers (to move the input bar)
        NotificationCenter.default.addObserver(self, selector: #selector(kbWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(kbWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // capture initial constraint constant
        originalInputBarBottomConstant = inputBarBottomConstraint.constant
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Make sure the input bar inset equals its height
        let barHeight = inputBarView.frame.height
        tableView.contentInset.bottom = barHeight
        tableView.scrollIndicatorInsets.bottom = barHeight

        // Ensure send button is circular-looking
        sendButton.layer.cornerRadius = min(sendButton.bounds.height, sendButton.bounds.width) / 2
        sendButton.clipsToBounds = true

        // Ensure placeholder visibility
        updatePlaceholderVisibility()

        // Bring input bar to front so it's not hidden by table cells when keyboard animates
        view.bringSubviewToFront(inputBarView)
        // ensure bottom inset reflects bar height at rest
        tableView.contentInset.bottom = inputBarView.frame.height
        tableView.scrollIndicatorInsets.bottom = inputBarView.frame.height
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Send
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        sendMessageFromInput()
    }

    private func sendMessageFromInput() {
        let raw = messageTextView.text ?? ""
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // create a Message model (adjust initializer to your Message struct)
        let new = Message(text: text, isOutgoing: true, date: Date())
        messages.append(new)

        // Insert the new row
        let newIndex = IndexPath(row: messages.count - 1, section: 0)
        tableView.beginUpdates()
        tableView.insertRows(at: [newIndex], with: .automatic)
        tableView.endUpdates()
        scrollToBottom(animated: true)

        // Clear input & reset height
        messageTextView.text = ""
        messageTextViewHeightConstraint.constant = textViewMinHeight
        sendButton.isEnabled = false
        updatePlaceholderVisibility()

        // (Optional) simulate a reply — remove in production
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            let reply = Message(text: "Auto-reply to: \(text)", isOutgoing: false, date: Date())
            self.messages.append(reply)
            let idx = IndexPath(row: self.messages.count - 1, section: 0)
            self.tableView.beginUpdates()
            self.tableView.insertRows(at: [idx], with: .automatic)
            self.tableView.endUpdates()
            self.scrollToBottom(animated: true)
        }
    }

    // MARK: - Keyboard handling (robust)
    @objc private func kbWillShow(_ note: Notification) {
        guard let info = note.userInfo,
              let kbFrameScreen = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curveValue = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return
        }

        // Convert keyboard frame to our view coordinates
        let kbFrame = view.convert(kbFrameScreen, from: nil)

        // Keyboard height (full, including safe area)
        let keyboardHeight = kbFrame.height

        // Safe area bottom inset (home indicator area)
        let safeBottom = view.safeAreaInsets.bottom

        // How much of our view is overlapped by the keyboard (excluding safe area)
        let overlap = max(0, keyboardHeight - safeBottom)

        // Debug: prints to console so we can verify numbers if something still looks off
        print("[kbWillShow] keyboardHeight:", keyboardHeight, "safeBottom:", safeBottom, "overlap:", overlap)

        // Move the input bar up by the overlap (negative because constraint is to safe area bottom)
        inputBarBottomConstraint.constant = -overlap

        // Animate with same timing/curve as keyboard
        let options = UIView.AnimationOptions(rawValue: curveValue << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
            self.view.layoutIfNeeded()

            // Set table inset to exactly the overlap (so table content ends above keyboard)
            // plus keep the input bar height included in visible area so content isn't hidden.
            self.tableView.contentInset.bottom = overlap + self.inputBarView.frame.height
            self.tableView.scrollIndicatorInsets.bottom = overlap + self.inputBarView.frame.height

            // Keep the latest messages visible
            self.scrollToBottom(animated: true)
        }, completion: nil)
    }

    @objc private func kbWillHide(_ note: Notification) {
        guard let info = note.userInfo,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curveValue = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return
        }

        // Debug
        print("[kbWillHide] restoring originalInputBarBottomConstant:", originalInputBarBottomConstant)

        // Restore the input bar constraint to original (usually 0)
        inputBarBottomConstraint.constant = originalInputBarBottomConstant

        let options = UIView.AnimationOptions(rawValue: curveValue << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
            self.view.layoutIfNeeded()

            // Remove keyboard-related inset; keep only input bar height so table isn't cut off
            self.tableView.contentInset.bottom = self.inputBarView.frame.height
            self.tableView.scrollIndicatorInsets.bottom = self.inputBarView.frame.height
        }, completion: nil)
    }

    // MARK: - Helpers

    func scrollToBottom(animated: Bool) {
        let last = messages.count - 1
        guard last >= 0 else { return }
        let ip = IndexPath(row: last, section: 0)
        tableView.scrollToRow(at: ip, at: .bottom, animated: animated)
    }

    private func updatePlaceholderVisibility() {
        let trimmed = messageTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        placeholderLabel.isHidden = !trimmed.isEmpty
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ChatViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messages.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCellIdentifier", for: indexPath) as? MessageCell else {
            return UITableViewCell()
        }

        let message = messages[indexPath.row]
        cell.configure(with: message)
        cell.selectionStyle = .none
        return cell
    }
}

// MARK: - UITextViewDelegate (grows the text view)
extension ChatViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let trimmed = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        sendButton.isEnabled = !trimmed.isEmpty

        // Resize logic
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        var newHeight = size.height
        if newHeight < textViewMinHeight { newHeight = textViewMinHeight }
        if newHeight > textViewMaxHeight { newHeight = textViewMaxHeight; textView.isScrollEnabled = true } else { textView.isScrollEnabled = false }
        messageTextViewHeightConstraint.constant = newHeight
        UIView.animate(withDuration: 0.12) { self.view.layoutIfNeeded() }

        updatePlaceholderVisibility()
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool { true }
}
