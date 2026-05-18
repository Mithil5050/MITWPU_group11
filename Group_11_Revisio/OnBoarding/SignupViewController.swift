import UIKit
import Supabase

class SignupViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var institutionTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create Account"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        
        configureTextField(nameTextField)
        configureTextField(emailTextField)
        configureTextField(institutionTextField)
        configureTextField(passwordTextField)
        configurePasswordField(passwordTextField)
        configureSaveButton()
        
        saveButton.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        
        // MARK: Keyboard Fix 1 - Assign Delegates for 'Return' key
        nameTextField.delegate = self
        emailTextField.delegate = self
        institutionTextField.delegate = self
        passwordTextField.delegate = self
        
        // MARK: Keyboard Fix 2 - Tap to dismiss
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    // Helper function to dismiss the keyboard when tapping the screen
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Sign Up Logic
    @objc private func handleSignUp() {
        guard let name = nameTextField.text, !name.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let institution = institutionTextField.text, !institution.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Missing Info", message: "Please fill in all fields.")
            return
        }
        
        saveButton.setTitle("Creating Account...", for: .normal)
        saveButton.isEnabled = false
        
        Task {
            do {
                // Updated with redirectTo to enable Deep Linking back to the app
                let _ = try await supabase.auth.signUp(
                    email: email,
                    password: password,
                    data: [
                        "username": .string(name),
                        "institution": .string(institution)
                    ],
                    redirectTo: URL(string: "reviseq://login-callback")
                )
                
                
                // Show the Verification Pop-up and send them back to Login
                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: "Check Your Email",
                        message: "We've sent a confirmation link to \(email). Please verify your account before logging in.",
                        preferredStyle: .alert
                    )
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                        self.dismiss(animated: true) // Closes the signup screen
                    }))
                    
                    self.present(alert, animated: true)
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.saveButton.setTitle("Save", for: .normal)
                    self.saveButton.isEnabled = true
                    
                    let errorMessage = error.localizedDescription.contains("security purposes")
                        ? "Please wait a few seconds before trying again."
                        : error.localizedDescription
                    
                    self.showAlert(title: "Sign Up Failed", message: errorMessage)
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - UI Configuration Helpers
    private func configureTextField(_ textField: UITextField) {
        textField.layer.cornerRadius = 14
        textField.layer.masksToBounds = true
        textField.backgroundColor = UIColor(red: 40/255, green: 44/255, blue: 55/255, alpha: 0.85)
        textField.textColor = .white
        textField.attributedPlaceholder = NSAttributedString(
            string: textField.placeholder ?? "",
            attributes: [.foregroundColor: UIColor(white: 1.0, alpha: 0.5)]
        )
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 44))
        textField.leftView = padding
        textField.leftViewMode = .always
    }
    
    private func configurePasswordField(_ textField: UITextField) {
        textField.isSecureTextEntry = true
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.tintColor = .secondaryLabel
        button.frame = CGRect(x: 0, y: 0, width: 24, height: 24)

        button.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        container.addSubview(button)
        button.center = CGPoint(x: 22, y: 22)

        textField.rightView = container
        textField.rightViewMode = .always
    }
    
    @objc private func togglePasswordVisibility() {
        passwordTextField.isSecureTextEntry.toggle()
        let imageName = passwordTextField.isSecureTextEntry ? "eye.slash" : "eye"
        if let button = passwordTextField.rightView?.subviews.first as? UIButton {
            button.setImage(UIImage(systemName: imageName), for: .normal)
        }
    }
    
    private func configureSaveButton() {
        saveButton.layer.cornerRadius = 25
        saveButton.clipsToBounds = true
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
}

// MARK: - UITextFieldDelegate Extension
extension SignupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Tells the keyboard to hide when the 'Return' key is pressed
        textField.resignFirstResponder()
        return true
    }
}
