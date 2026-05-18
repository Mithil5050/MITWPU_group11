import UIKit

extension UIViewController {

    func showGenerationOverlay(message: String = "Our AI is reading your document and crafting questions...") {
        let screenBounds = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds ?? .zero
        let overlay = UIView(frame: screenBounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.88)
        overlay.tag = 9999
        overlay.alpha = 0

        // Card container
        let card = UIView()
        card.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.15, alpha: 1.0)
        card.layer.cornerRadius = 28
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.5
        card.layer.shadowRadius = 20
        card.layer.shadowOffset = .zero
        card.translatesAutoresizingMaskIntoConstraints = false

        // Mascot
        let mascotImageView = UIImageView()
        mascotImageView.image = UIImage(named: "bot_phone")
        mascotImageView.contentMode = .scaleAspectFit
        mascotImageView.translatesAutoresizingMaskIntoConstraints = false

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Generating..."
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Message
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = UIColor.white.withAlphaComponent(0.65)
        messageLabel.font = .systemFont(ofSize: 15, weight: .regular)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        // Spinner
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = UIColor(red: 0.55, green: 0.65, blue: 1.0, alpha: 1.0)
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false

        overlay.addSubview(card)
        card.addSubview(mascotImageView)
        card.addSubview(titleLabel)
        card.addSubview(messageLabel)
        card.addSubview(spinner)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: overlay.centerYAnchor, constant: -20),
            card.widthAnchor.constraint(equalToConstant: 300),

            mascotImageView.topAnchor.constraint(equalTo: card.topAnchor, constant: 32),
            mascotImageView.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            mascotImageView.widthAnchor.constraint(equalToConstant: 150),
            mascotImageView.heightAnchor.constraint(equalToConstant: 150),

            titleLabel.topAnchor.constraint(equalTo: mascotImageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),

            spinner.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            spinner.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            spinner.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -28)
        ])

        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            window.addSubview(overlay)
            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.3) {
                overlay.alpha = 1
                card.transform = .identity
            }
            // Float animation on mascot
            UIView.animate(withDuration: 1.8, delay: 0.2, options: [.autoreverse, .repeat, .curveEaseInOut]) {
                mascotImageView.transform = CGAffineTransform(translationX: 0, y: -10)
            }
        }
    }

    func hideGenerationOverlay() {
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            if let overlay = window.viewWithTag(9999) {
                UIView.animate(withDuration: 0.25, animations: {
                    overlay.alpha = 0
                    overlay.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                }) { _ in
                    overlay.removeFromSuperview()
                }
            }
        }
    }

}
