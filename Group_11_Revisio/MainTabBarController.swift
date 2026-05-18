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

        BadgeUnlockPopup.show(badge: event.badge, type: event.type) { [weak self] in
            self?.isShowingBadgePopup = false
            self?.showNextBadgePopupIfReady()
        }
    }


    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
