//
//  MainTabBarViewController.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 05/03/26.

import UIKit

class MainTabBarController: UITabBarController {

    // Sequential queue: events are added here and shown one at a time.
    // The next popup only appears after the user dismisses the current one.
    private var badgeEventQueue: [(badge: Badging.Badge, type: String)] = []
    private var isShowingBadgePopup = false

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBadgeEvent(_:)),
            name: NSNotification.Name("BadgeEvent"),
            object: nil
        )
    }

    @objc private func handleBadgeEvent(_ notification: Notification) {
        guard let badge = notification.userInfo?["badge"] as? Badging.Badge,
              let type  = notification.userInfo?["type"]  as? String else {
            print("❌ Badge popup failed: missing badge or type in notification.")
            return
        }

        // Always enqueue — never present directly from the notification
        badgeEventQueue.append((badge: badge, type: type))
        showNextBadgePopupIfReady()
    }

    /// Presents the next queued popup only if no popup is currently on screen.
    private func showNextBadgePopupIfReady() {
        guard !isShowingBadgePopup, !badgeEventQueue.isEmpty else { return }

        let event = badgeEventQueue.removeFirst()
        isShowingBadgePopup = true

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        let alert: UIAlertController

        if event.type == "BadgeUnlocked" {
            alert = UIAlertController(
                title: "🔓 Badge Unlocked!",
                message: "\"\(event.badge.title)\" is now in progress.\n\(event.badge.detail)",
                preferredStyle: .alert
            )
        } else {
            alert = UIAlertController(
                title: "🏆 Badge Earned!",
                message: "You completed \"\(event.badge.title)\"!\n\(event.badge.detail)",
                preferredStyle: .alert
            )
        }

        // When the user taps OK/Awesome, mark as done and show the next one
        let actionTitle = event.type == "BadgeUnlocked" ? "Let's Go!" : "Awesome! 🎉"
        alert.addAction(UIAlertAction(title: actionTitle, style: .default) { [weak self] _ in
            self?.isShowingBadgePopup = false
            self?.showNextBadgePopupIfReady()
        })

        guard let topVC = topMostViewController() else {
            // If we can't present right now, put it back and try again shortly
            isShowingBadgePopup = false
            badgeEventQueue.insert(event, at: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showNextBadgePopupIfReady()
            }
            return
        }

        topVC.present(alert, animated: true)
    }

    private func topMostViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            // If a badge alert is already on screen, don't try to present over it
            if presented is UIAlertController { return nil }
            topVC = presented
        }
        return topVC
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
