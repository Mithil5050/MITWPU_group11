import UIKit
import Supabase // Ensure you import Supabase to use the client

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!

    // Use your existing shared client
    private let supabase = SupabaseManager.shared.client

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()

        navigationItem.title = "Reset Password"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        // MARK: - Keyboard Fix: Tap to dismiss
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    // Helper function to dismiss the keyboard when tapping the screen
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    private func configureUI() {
        view.backgroundColor = .systemBackground

        emailTextField.layer.cornerRadius = 14
        emailTextField.layer.masksToBounds = true
        emailTextField.backgroundColor = UIColor(red: 40/255, green: 44/255, blue: 55/255, alpha: 0.85)
        emailTextField.textColor = .white

        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 44))
        emailTextField.leftView = padding
        emailTextField.leftViewMode = .always

        emailTextField.attributedPlaceholder = NSAttributedString(
            string: "Enter your email",
            attributes: [.foregroundColor: UIColor(white: 1.0, alpha: 0.5)]
        )

        // Ensure the button is styled to match your Signup screen
        sendButton.layer.cornerRadius = 25
        sendButton.clipsToBounds = true
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @IBAction func sendResetTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty else {
            showAlert(title: "Error", message: "Please enter your email address.")
            return
        }

        // Disable button to prevent multiple taps
        sendButton.isEnabled = false
        sendButton.setTitle("Sending...", for: .normal)

        Task {
            do {
                // ✅ Call Supabase to send the reset email
                try await supabase.auth.resetPasswordForEmail(email)

                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: "Reset Link Sent",
                        message: "If this email exists, a reset link has been sent to \(email).",
                        preferredStyle: .alert
                    )

                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.dismiss(animated: true)
                    })

                    self.present(alert, animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.sendButton.isEnabled = true
                    self.sendButton.setTitle("Send Reset Link", for: .normal)
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
