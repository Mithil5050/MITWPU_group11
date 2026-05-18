//
//  XPNotificationBanner.swift
//  Group_11_Revisio
//
//  Created by Ayaana Talwar on 18/02/26.
//

import UIKit

class XPNotificationBanner: UIView {
    static func show(amount: Int, reason: String) {

        let bannerHeight: CGFloat = 70
        let screenWidth = (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.width ?? 390)
        let bannerWidth = screenWidth - 40
        let banner = XPNotificationBanner(frame: CGRect(x: 20, y: -100, width: bannerWidth, height: bannerHeight))

        banner.setup(amount: amount, reason: reason)

        // Add to the top-most window
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first(where: { $0.isKeyWindow }) else { return }

        window.addSubview(banner)

        // Slide Down Animation
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            banner.frame.origin.y = 60
        } completion: { _ in
            // Slide Up and Remove after delay
            UIView.animate(withDuration: 0.4, delay: 2.5, options: .curveEaseIn) {
                banner.frame.origin.y = -100
            } completion: { _ in
                banner.removeFromSuperview()
            }
        }
    }

    private func setup(amount: Int, reason: String) {
        backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 0.95)
        layer.cornerRadius = 15
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemBlue.cgColor

        let icon = UIImageView(image: UIImage(systemName: "bolt.fill"))
        icon.tintColor = .systemBlue

        let label = UILabel()
        label.text = "+\(amount) XP • \(reason)"
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .bold)

        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.spacing = 10
        stack.alignment = .center
        addSubview(stack)

        icon.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
