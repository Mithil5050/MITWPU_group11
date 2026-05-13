//
//  UIViewController+QuitConfirmation.swift
//  Group_11_Revisio
//
//  Adds a "Quit Game?" confirmation alert when the user tries to
//  navigate back from any game screen. Intercepts both the nav bar
//  back button AND the swipe-to-go-back gesture.
//

import UIKit

extension UIViewController {

    /// Call this in `viewDidLoad()` to install a quit-confirmation guard.
    /// It replaces the default back button with a custom one and
    /// disables the interactive pop gesture until the user confirms.
    func installQuitConfirmation(
        title: String = "Quit Game?",
        message: String = "Your progress will be lost. Are you sure you want to quit?",
        quitTitle: String = "Quit",
        cancelTitle: String = "Cancel"
    ) {
        // Custom back button
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(_showQuitAlert)
        )
        navigationItem.leftBarButtonItem = backButton

        // Disable swipe-to-go-back (we'll show alert on attempt)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false

        // Store strings for the alert via associated objects
        objc_setAssociatedObject(self, &AssociatedKeys.quitTitle, title, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(self, &AssociatedKeys.quitMessage, message, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(self, &AssociatedKeys.quitButtonTitle, quitTitle, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(self, &AssociatedKeys.cancelButtonTitle, cancelTitle, .OBJC_ASSOCIATION_RETAIN)
    }

    @objc private func _showQuitAlert() {
        let title = objc_getAssociatedObject(self, &AssociatedKeys.quitTitle) as? String ?? "Quit Game?"
        let message = objc_getAssociatedObject(self, &AssociatedKeys.quitMessage) as? String ?? "Your progress will be lost."
        let quitTitle = objc_getAssociatedObject(self, &AssociatedKeys.quitButtonTitle) as? String ?? "Quit"
        let cancelTitle = objc_getAssociatedObject(self, &AssociatedKeys.cancelButtonTitle) as? String ?? "Cancel"

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel))
        alert.addAction(UIAlertAction(title: quitTitle, style: .destructive) { [weak self] _ in
            // Re-enable the swipe gesture for the rest of the nav stack
            self?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            self?.navigationController?.popViewController(animated: true)
        })

        present(alert, animated: true)
    }
}

// MARK: - Associated Object Keys
private struct AssociatedKeys {
    static var quitTitle = "quitConfirm_title"
    static var quitMessage = "quitConfirm_message"
    static var quitButtonTitle = "quitConfirm_quit"
    static var cancelButtonTitle = "quitConfirm_cancel"
}
