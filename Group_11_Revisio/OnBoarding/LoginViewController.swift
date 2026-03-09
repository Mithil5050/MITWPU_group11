//
//  LoginViewController.swift
//  Group_11_Revisio
//

import UIKit
import AuthenticationServices
import Supabase

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextFields()
        addPasswordToggle(to: passwordTextField)
    }

    // MARK: - Supabase Log In Logic
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let emailText = emailTextField.text, !emailText.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            let alert = UIAlertController(title: "Missing Info", message: "Please enter your email and password.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // ✅ Clean up any invisible spaces iOS adds to the email
        let cleanEmail = emailText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                // Log in with Supabase
                try await supabase.auth.signIn(email: cleanEmail, password: password)
                
                // Success! Go to Home Page
                DispatchQueue.main.async {
                    self.transitionToMainApp()
                }
            } catch {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Login Failed", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    // MARK: - Navigation
    private func transitionToMainApp() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // ✅ Load the Tab Bar Controller instead of just the Home screen
        let tabBarVC = storyboard.instantiateViewController(withIdentifier: "MainTabBarController")
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        window.rootViewController = tabBarVC
        UIView.transition(with: window, duration: 0.4, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }
    
    // MARK: - UI & Navigation Setup
    private func configureTextFields() {
        styleTextField(emailTextField)
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none

        styleTextField(passwordTextField)
        passwordTextField.isSecureTextEntry = true
        passwordTextField.textContentType = .password
    }
    
    private func styleTextField(_ textField: UITextField) {
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
    
    private func addPasswordToggle(to textField: UITextField) {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.tintColor = .secondaryLabel
        button.frame = CGRect(x: 0, y: 0, width: 24, height: 24)

        // Using standard target-action for the toggle
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

    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "ForgotPasswordViewController") as? ForgotPasswordViewController else { return }
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
    
    @IBAction func appleSignInTapped(_ sender: UIButton) {
        startAppleSignIn()
    }

    @IBAction func googleSignInTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Google Sign In", message: "Google login will be added later", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @IBAction func signUpTapped(_ sender: UITapGestureRecognizer) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let signupVC = storyboard.instantiateViewController(withIdentifier: "SignupViewController") as? SignupViewController else { return }
        let nav = UINavigationController(rootViewController: signupVC)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
    
    private func startAppleSignIn() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

// MARK: - Apple Sign In Delegates
extension LoginViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let alert = UIAlertController(title: "Success", message: "Signed in with Apple", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign In failed:", error.localizedDescription)
    }
}

extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}
