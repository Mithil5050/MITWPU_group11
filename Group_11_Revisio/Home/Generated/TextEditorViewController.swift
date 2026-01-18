import UIKit

class TextEditorViewController: UIViewController, UITextViewDelegate {

    private let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Text Editor"

        setupTextView()
        setupNavigationItems()
    }

    private func setupTextView() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.delegate = self
        textView.backgroundColor = .secondarySystemBackground
        textView.textColor = .label
        textView.alwaysBounceVertical = true
        view.addSubview(textView)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 12),
            textView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 12),
            textView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -12),
            textView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -12)
        ])
    }

    private func setupNavigationItems() {
        // Example Save button; wire this to your upload flow as needed.
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
    }

    @objc private func saveTapped() {
        let content = textView.text ?? ""
        // TODO: Hook into your upload pipeline, pass `content`.
        // For now, just log.
        print("TextEditor content length: \(content.count)")
        navigationController?.popViewController(animated: true)
    }

    // MARK: - UITextViewDelegate (optional)

    func textViewDidChange(_ textView: UITextView) {
        // Handle live updates if needed.
    }
}
