//
//  ForgotPasswordViewController.swift
//  App_Onboarding
//
//  Created by Chirag Poojari on 11/02/26.
//

import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        
        navigationItem.title = "Reset Password"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
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
        
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @IBAction func sendResetTapped(_ sender: UIButton) {
        
        let alert = UIAlertController(
            title: "Reset Link Sent",
            message: "If this email exists, a reset link has been sent.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.dismiss(animated: true)
        })
        
        present(alert, animated: true)
    }

}
