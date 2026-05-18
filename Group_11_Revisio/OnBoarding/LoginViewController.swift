import UIKit
import AuthenticationServices
import Supabase
import GoogleSignIn

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextFields()
        addPasswordToggle(to: passwordTextField)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let emailText = emailTextField.text, !emailText.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            let alert = UIAlertController(title: "Missing Info", message: "Please enter email and password.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let cleanEmail = emailText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                try await supabase.auth.signIn(email: cleanEmail, password: password)
                let user = try await supabase.auth.session.user
                
                guard user.emailConfirmedAt != nil else {
                    try? await supabase.auth.signOut()
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Email Not Verified", message: "Please check your inbox.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                    return
                }
                
                DispatchQueue.main.async { self.transitionToMainApp() }
            } catch {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Login Failed", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    private func transitionToMainApp() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarVC = storyboard.instantiateViewController(withIdentifier: "MainTabBarController")
        ProgressDataManager.shared.restoreFromSupabase()
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        window.rootViewController = tabBarVC
        UIView.transition(with: window, duration: 0.4, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }
    
    private func configureTextFields() {
        styleTextField(emailTextField)
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        styleTextField(passwordTextField)
        passwordTextField.isSecureTextEntry = true
    }
    
    private func styleTextField(_ textField: UITextField) {
        textField.layer.cornerRadius = 14
        textField.backgroundColor = UIColor(red: 40/255, green: 44/255, blue: 55/255, alpha: 0.85)
        textField.textColor = .white
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 44))
        textField.leftView = padding
        textField.leftViewMode = .always
    }
    
    private func addPasswordToggle(to textField: UITextField) {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        container.addSubview(button)
        button.center = CGPoint(x: 22, y: 22)
        textField.rightView = container
        textField.rightViewMode = .always
    }
    
    @objc private func togglePasswordVisibility() {
        passwordTextField.isSecureTextEntry.toggle()
    }

    @IBAction func googleSignInTapped(_ sender: UIButton) {
        Task {
            do {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootVC = windowScene.windows.first?.rootViewController else { return }

                let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
                guard let idToken = result.user.idToken?.tokenString else { return }
                let accessToken = result.user.accessToken.tokenString

                try await supabase.auth.signInWithIdToken(
                    credentials: .init(provider: .google, idToken: idToken, accessToken: accessToken)
                )
                
                let user = try await supabase.auth.session.user
                let googleName = user.userMetadata["full_name"]?.value as? String ?? "New Student"
                
                // Ensure profile exists in the 'profiles' table
                do {
                    let _ = try await supabase.from("profiles").select("id").eq("id", value: user.id).single().execute()
                } catch {
                    let newProfileData: [String: AnyJSON] = [
                        "id": .string(user.id.uuidString),
                        "username": .string(googleName),
                        "total_xp": .integer(0),
                        "current_level": .integer(1),
                        "current_streak": .integer(0)
                    ]
                    try? await supabase.from("profiles").insert(newProfileData).execute()
                }

                DispatchQueue.main.async { self.transitionToMainApp() }
            } catch {
                DispatchQueue.main.async {
                    if (error as NSError).code != GIDSignInError.canceled.rawValue {
                        let alert = UIAlertController(title: "Google Error", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
        }
    }
    
    @IBAction func signUpTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let signupVC = storyboard.instantiateViewController(withIdentifier: "SignupViewController") as? SignupViewController else { return }
        let nav = UINavigationController(rootViewController: signupVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @IBAction func appleSignInTapped(_ sender: UIButton) { startAppleSignIn() }

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

extension LoginViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor { return view.window! }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) { print(error) }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {}
}
