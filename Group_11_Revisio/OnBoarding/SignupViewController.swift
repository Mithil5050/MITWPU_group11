//
//  SignupViewController.swift
//  Group_11_Revisio
//

import UIKit
import Supabase

// ✅ 1. Define this neat Struct right here. This perfectly tells Supabase what data to expect.
struct ProfileUpdate: Encodable {
    let id: String
    let username: String
    let institution: String
    let total_xp: Int
    let current_level: Int
}

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
                // 1. Create the Auth user
                let authResponse = try await supabase.auth.signUp(email: email, password: password)
                let userId = authResponse.user.id
                
                // ✅ 2. Use the Struct instead of a dictionary!
                // No more 'AnyEncodable' errors, Swift knows exactly what this is.
                let newProfile = ProfileUpdate(
                    id: userId.uuidString,
                    username: name,
                    institution: institution,
                    total_xp: 0,
                    current_level: 1
                )
                
                // 3. UPSERT into the database
                                try await supabase
                                    .from("profiles")
                                    .upsert(newProfile)
                                    .execute()
                                
                                // ✅ CHANGED: Show verification alert instead of jumping to the Home screen!
                                DispatchQueue.main.async {
                                    let alert = UIAlertController(
                                        title: "Check Your Email",
                                        message: "We've sent a confirmation link to \(email). Please verify your account before logging in.",
                                        preferredStyle: .alert
                                    )
                                    
                                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                                        // This closes the Sign Up screen and drops them back onto the Login screen
                                        self.dismiss(animated: true)
                                    }))
                                    
                                    self.present(alert, animated: true)
                                }
                                
                            } catch {
                                // ... (Keep your existing catch block here)
                DispatchQueue.main.async {
                    self.saveButton.setTitle("Save", for: .normal)
                    self.saveButton.isEnabled = true
                    self.showAlert(title: "Sign Up Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Navigation
    private func transitionToMainApp() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let tabBarVC = storyboard.instantiateViewController(withIdentifier: "MainTabBarController")
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        window.rootViewController = tabBarVC
        UIView.transition(with: window, duration: 0.4, options: .transitionCrossDissolve, animations: nil, completion: nil)
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
