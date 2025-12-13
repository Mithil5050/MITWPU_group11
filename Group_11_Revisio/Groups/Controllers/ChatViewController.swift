//
//  ChatViewController.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 27/11/25.
//

import UIKit

class ChatViewController: UIViewController {

    var group: Group?

    // MARK: - IBOutlets (must match storyboard)
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputBarView: UIView!
    @IBOutlet weak var inputBarBottomConstraint: NSLayoutConstraint! // bottom constraint connecting inputBarView to safe area bottom
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var messageTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendButton: UIButton!

    private var messagePlaceholderLabel: UILabel!

    // Data model
    var messages: [Message] = []

    // Config
    private let textViewMinHeight: CGFloat = 36
    private let textViewMaxHeight: CGFloat = 120

    override func viewDidLoad() {
        super.viewDidLoad()

        // Title from group
        if let g = group {
            self.title = g.name
        }

        // Table setup
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .interactive
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension

        // Original demo messages
        messages = [
            Message(text: "Welcome to iMAAC group!", isOutgoing: false, date: Date(timeIntervalSinceNow: -3600)),
            Message(text: "Hey everyone 👋", isOutgoing: true, date: Date(timeIntervalSinceNow: -3500)),
            Message(text: "Don't forget to submit your statistics assignment.", isOutgoing: false, date: Date(timeIntervalSinceNow: -3200)),
            Message(text: "Let’s finish it today 🔥", isOutgoing: true, date: Date(timeIntervalSinceNow: -3000))
        ]

        tableView.reloadData()
        scrollToBottom(animated: false)

        // Input UI
        messageTextView.delegate = self
        messageTextView.isScrollEnabled = false
        messageTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        messageTextView.font = UIFont.systemFont(ofSize: 16)
        messageTextView.backgroundColor = .clear
        messageTextView.textColor = .label

        // Send button original style
        if let img = UIImage(systemName: "arrow.up.circle.filled") {
            sendButton.setImage(img, for: .normal)
            sendButton.tintColor = .systemBlue
        }
        sendButton.setTitle("", for: .normal)
        sendButton.isEnabled = false

        // Placeholder label
        messagePlaceholderLabel = UILabel()
        messagePlaceholderLabel.text = "Message"
        messagePlaceholderLabel.font = UIFont.systemFont(ofSize: 16)
        messagePlaceholderLabel.textColor = UIColor.secondaryLabel
        messagePlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        messageTextView.addSubview(messagePlaceholderLabel)
        NSLayoutConstraint.activate([
            messagePlaceholderLabel.leadingAnchor.constraint(equalTo: messageTextView.leadingAnchor, constant: 12),
            messagePlaceholderLabel.centerYAnchor.constraint(equalTo: messageTextView.centerYAnchor)
        ])
        updatePlaceholderVisibility()

        // Keyboard observers
        NotificationCenter.default.addObserver(self, selector: #selector(kbWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(kbWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        // initial inset
        view.layoutIfNeeded()
        let barHeight = inputBarView.frame.height
        tableView.contentInset.bottom = barHeight
        tableView.scrollIndicatorInsets.bottom = barHeight
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if sendButton.bounds.height > 0 {
            sendButton.layer.cornerRadius = min(sendButton.bounds.height, sendButton.bounds.width) / 2
            sendButton.clipsToBounds = true
        }

        if messageTextViewHeightConstraint.constant <= 0 {
            messageTextViewHeightConstraint.constant = textViewMinHeight
        }

        let barHeight = inputBarView.frame.height
        tableView.contentInset.bottom = barHeight
        tableView.scrollIndicatorInsets.bottom = barHeight
    }

    // MARK: - Send
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        let raw = messageTextView.text ?? ""
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let new = Message(text: text, isOutgoing: true, date: Date())
        messages.append(new)

        let newIndex = IndexPath(row: messages.count - 1, section: 0)
        tableView.beginUpdates()
        tableView.insertRows(at: [newIndex], with: .automatic)
        tableView.endUpdates()
        scrollToBottom(animated: true)

        messageTextView.text = ""
        messageTextViewHeightConstraint.constant = textViewMinHeight
        updatePlaceholderVisibility()
        sendButton.isEnabled = false
    }

    private func scrollToBottom(animated: Bool) {
        guard messages.count > 0 else { return }
        let last = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: last, at: .bottom, animated: animated)
    }

    // MARK: - Keyboard
    @objc private func kbWillShow(_ notification: Notification) {
        if let info = notification.userInfo,
           let keyboardFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
           let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
           let curveValue = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt {

            let kbHeight = keyboardFrame.height - view.safeAreaInsets.bottom
            inputBarBottomConstraint.constant = -kbHeight

            let options = UIView.AnimationOptions(rawValue: curveValue << 16)
            UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
                self.view.layoutIfNeeded()
                let inset = kbHeight + self.inputBarView.frame.height
                self.tableView.contentInset.bottom = inset
                self.tableView.scrollIndicatorInsets.bottom = inset
                self.scrollToBottom(animated: true)
            })
        }
    }

    @objc private func kbWillHide(_ notification: Notification) {
        if let info = notification.userInfo,
           let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
           let curveValue = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt {

            inputBarBottomConstraint.constant = 0

            let options = UIView.AnimationOptions(rawValue: curveValue << 16)
            UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
                self.view.layoutIfNeeded()
                let barHeight = self.inputBarView.frame.height
                self.tableView.contentInset.bottom = barHeight
                self.tableView.scrollIndicatorInsets.bottom = barHeight
            })
        }
    }

    // MARK: - Placeholder
    private func updatePlaceholderVisibility() {
        let trimmed = (messageTextView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        messagePlaceholderLabel.isHidden = !trimmed.isEmpty
        sendButton.isEnabled = !trimmed.isEmpty
    }
}

// MARK: - UITableViewDataSource
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

// MARK: - UITextViewDelegate
extension ChatViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        let trimmed = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        sendButton.isEnabled = !trimmed.isEmpty

        // Resize text view
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .greatestFiniteMagnitude))
        var newHeight = size.height
        if newHeight < textViewMinHeight { newHeight = textViewMinHeight }
        if newHeight > textViewMaxHeight { newHeight = textViewMaxHeight; textView.isScrollEnabled = true }
        else { textView.isScrollEnabled = false }
        messageTextViewHeightConstraint.constant = newHeight
        UIView.animate(withDuration: 0.12) { self.view.layoutIfNeeded() }

        updatePlaceholderVisibility()
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool { return true }
}
