import UIKit
import AuthenticationServices
import Supabase
import GoogleSignIn
import CryptoKit

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    private var currentNonce: String?
    
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
                let defaultName = user.email?.components(separatedBy: "@").first?.replacingOccurrences(of: ".", with: " ").replacingOccurrences(of: "_", with: " ").capitalized ?? "Student"
                let googleName = user.userMetadata["full_name"]?.value as? String ?? (user.userMetadata["name"]?.value as? String ?? defaultName)
                
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
                    _ = try? await supabase.from("profiles").insert(newProfileData).execute()
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
        let nonce = randomNonceString()
        currentNonce = nonce
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    // MARK: - Helper Methods for Apple Sign-In
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }

//    @IBAction func signUpTapped(_ sender: Any) {
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        if let signupVC = storyboard.instantiateViewController(withIdentifier: "SignupViewController") as? SignupViewController {
//            let navController = UINavigationController(rootViewController: signupVC)
//            present(navController, animated: true)
//        }
//    }

    @IBAction func forgotPasswordTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let forgotVC = storyboard.instantiateViewController(withIdentifier: "ForgotPasswordViewController") as? ForgotPasswordViewController {
            let navController = UINavigationController(rootViewController: forgotVC)
            present(navController, animated: true)
        }
    }
}

extension LoginViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor { return view.window! }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let authError = error as? ASAuthorizationError
        if authError?.code != .canceled {
            DispatchQueue.main.async { [weak self] in
                let alert = UIAlertController(title: "Apple Sign In Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            let givenName = appleIDCredential.fullName?.givenName
            let familyName = appleIDCredential.fullName?.familyName
            let fullName = [givenName, familyName].compactMap({ $0 }).joined(separator: " ")
            
            Task {
                do {
                    try await supabase.auth.signInWithIdToken(credentials: .init(provider: .apple, idToken: idTokenString, nonce: nonce))
                    
                    let user = try await supabase.auth.session.user
                    let defaultName = user.email?.components(separatedBy: "@").first?.replacingOccurrences(of: ".", with: " ").replacingOccurrences(of: "_", with: " ").capitalized ?? "Student"
                    let appleName: String
                    if !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        appleName = fullName
                    } else if let metaName = user.userMetadata["full_name"]?.value as? String, !metaName.isEmpty {
                        appleName = metaName
                    } else if let metaName = user.userMetadata["name"]?.value as? String, !metaName.isEmpty {
                        appleName = metaName
                    } else {
                        appleName = defaultName
                    }
                    
                    // Ensure profile exists in the 'profiles' table
                    do {
                        let _ = try await supabase.from("profiles").select("id").eq("id", value: user.id).single().execute()
                    } catch {
                        let newProfileData: [String: AnyJSON] = [
                            "id": .string(user.id.uuidString),
                            "username": .string(appleName),
                            "total_xp": .integer(0),
                            "current_level": .integer(1),
                            "current_streak": .integer(0)
                        ]
                        _ = try? await supabase.from("profiles").insert(newProfileData).execute()
                    }
                    
                    DispatchQueue.main.async { self.transitionToMainApp() }
                    
                } catch {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Apple Sign In Error", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
        }
    }
}

