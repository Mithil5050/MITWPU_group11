//
//  BadgeUnlockPopupView.swift
//  Group_11_Revisio
//
//  Pure UIKit badge-earned / badge-unlocked overlay popup.
//  No SwiftUI, no XIB — entirely programmatic.
//

import UIKit

// MARK: - Public presenter helper

/// Call from any UIViewController (or the tab-bar controller) to show the popup.
final class BadgeUnlockPopup {

    static func show(badge: Badging.Badge, type: String, completion: @escaping () -> Void) {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first(where: { $0.isKeyWindow }) else {
            completion()
            return
        }
        let popup = BadgeUnlockPopupView(badge: badge, type: type, completion: completion)
        popup.frame = window.bounds
        popup.alpha = 0
        window.addSubview(popup)
        popup.animateIn()
    }
}

// MARK: - BadgeUnlockPopupView

private final class BadgeUnlockPopupView: UIView {

    // MARK: Inputs
    private let badge: Badging.Badge
    private let eventType: String          // "BadgeEarned" | "BadgeUnlocked"
    private let onDismiss: () -> Void

    // MARK: Sub-views
    private let dimView        = UIView()
    private let card           = UIView()
    private let glowLayer      = CAGradientLayer()
    private let ribbonLabel    = PaddedLabel()
    private let badgeImageView = UIImageView()
    private let sparkContainer = UIView()
    private let headlineLabel  = UILabel()
    private let titleLabel     = UILabel()
    private let detailLabel    = UILabel()
    private let tierView       = TierBadgeView()
    private let ctaButton      = UIButton(type: .system)
    private var shimmerLayer: CAGradientLayer?

    // MARK: Init
    init(badge: Badging.Badge, type: String, completion: @escaping () -> Void) {
        self.badge      = badge
        self.eventType  = type
        self.onDismiss  = completion
        super.init(frame: .zero)
        buildHierarchy()
        styleViews()
        populate()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build

    private func buildHierarchy() {
        // Dim backdrop
        addSubview(dimView)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        // Card
        addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: centerXAnchor),
            card.centerYAnchor.constraint(equalTo: centerYAnchor),
            card.widthAnchor.constraint(equalToConstant: 300),
        ])

        // Ribbon (floats above card top edge)
        addSubview(ribbonLabel)
        ribbonLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ribbonLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            ribbonLabel.centerYAnchor.constraint(equalTo: card.topAnchor),
        ])

        // Spark container (sits behind card so sparks can overflow)
        insertSubview(sparkContainer, belowSubview: card)
        sparkContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sparkContainer.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            sparkContainer.centerYAnchor.constraint(equalTo: card.topAnchor, constant: 50),
            sparkContainer.widthAnchor.constraint(equalToConstant: 300),
            sparkContainer.heightAnchor.constraint(equalToConstant: 300),
        ])
        sparkContainer.isUserInteractionEnabled = false

        // Badge image
        card.addSubview(badgeImageView)
        badgeImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            badgeImageView.topAnchor.constraint(equalTo: card.topAnchor, constant: 40),
            badgeImageView.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            badgeImageView.widthAnchor.constraint(equalToConstant: 136),
            badgeImageView.heightAnchor.constraint(equalToConstant: 136),
        ])

        // Tier badge (small pill in corner of image)
        card.addSubview(tierView)
        tierView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tierView.trailingAnchor.constraint(equalTo: badgeImageView.trailingAnchor, constant: 6),
            tierView.bottomAnchor.constraint(equalTo: badgeImageView.bottomAnchor, constant: 6),
            tierView.widthAnchor.constraint(equalToConstant: 32),
            tierView.heightAnchor.constraint(equalToConstant: 32),
        ])

        // Headline ("Badge Earned!" / "Badge Unlocked")
        card.addSubview(headlineLabel)
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headlineLabel.topAnchor.constraint(equalTo: badgeImageView.bottomAnchor, constant: 20),
            headlineLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            headlineLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
        ])

        // Badge title
        card.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
        ])

        // Detail text
        card.addSubview(detailLabel)
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            detailLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            detailLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
        ])

        // CTA button
        card.addSubview(ctaButton)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ctaButton.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 24),
            ctaButton.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            ctaButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            ctaButton.heightAnchor.constraint(equalToConstant: 50),
            ctaButton.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24),
        ])
    }

    // MARK: - Style

    private func styleViews() {
        let isEarned = (eventType == "BadgeEarned")

        // Dim
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissTapped))
        dimView.addGestureRecognizer(tap)

        // Card
        card.backgroundColor    = UIColor(red: 0.11, green: 0.11, blue: 0.14, alpha: 1)
        card.layer.cornerRadius = 24
        card.clipsToBounds      = false                  // allow glow + ribbon overflow

        // Glow ring around card
        glowLayer.colors        = isEarned
            ? [UIColor.systemYellow.withAlphaComponent(0.7).cgColor,
               UIColor.systemOrange.withAlphaComponent(0.0).cgColor]
            : [UIColor.systemBlue.withAlphaComponent(0.5).cgColor,
               UIColor.systemBlue.withAlphaComponent(0.0).cgColor]
        glowLayer.type          = .radial
        glowLayer.startPoint    = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint      = CGPoint(x: 1.0, y: 1.0)
        card.layer.insertSublayer(glowLayer, at: 0)

        // Ribbon pill at top of card
        ribbonLabel.font            = .systemFont(ofSize: 13, weight: .bold)
        ribbonLabel.textColor       = isEarned ? .black : .white
        ribbonLabel.backgroundColor = isEarned
            ? UIColor.systemYellow
            : UIColor.systemBlue
        ribbonLabel.layer.cornerRadius = 12
        ribbonLabel.clipsToBounds      = true
        ribbonLabel.textAlignment      = .center
        ribbonLabel.text               = isEarned ? "BADGE EARNED" : "BADGE UNLOCKED"

        // Badge image — no corner clip so badge artwork shows in full
        badgeImageView.contentMode     = .scaleAspectFill
        badgeImageView.clipsToBounds   = false
        badgeImageView.backgroundColor = .clear
        // Soft glow shadow around the badge image
        badgeImageView.layer.shadowColor   = UIColor.white.cgColor
        badgeImageView.layer.shadowOpacity = 0.18
        badgeImageView.layer.shadowRadius  = 16
        badgeImageView.layer.shadowOffset  = .zero

        // Shimmer overlay — frame is set in layoutSubviews after layout
        let shimmer = CAGradientLayer()
        shimmer.colors  = [UIColor.clear.cgColor,
                           UIColor.white.withAlphaComponent(0.4).cgColor,
                           UIColor.clear.cgColor]
        shimmer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmer.endPoint   = CGPoint(x: 1, y: 0.5)
        shimmer.locations  = [-0.3, 0.0, 0.3]
        shimmerLayer       = shimmer
        badgeImageView.layer.addSublayer(shimmer)

        // Tier badge view
        tierView.configure(for: badge.tier)

        // Headline
        headlineLabel.textColor     = .white
        headlineLabel.font          = .systemFont(ofSize: 22, weight: .heavy)
        headlineLabel.textAlignment = .center
        headlineLabel.numberOfLines = 1

        // Title
        titleLabel.textColor     = UIColor(white: 0.85, alpha: 1)
        titleLabel.font          = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2

        // Detail
        detailLabel.textColor     = UIColor(white: 0.55, alpha: 1)
        detailLabel.font          = .systemFont(ofSize: 14, weight: .regular)
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 0

        // CTA button
        let btnColor: UIColor = isEarned ? .systemYellow : .systemBlue
        ctaButton.backgroundColor   = btnColor
        ctaButton.layer.cornerRadius = 14
        ctaButton.clipsToBounds     = true
        ctaButton.titleLabel?.font  = .systemFont(ofSize: 16, weight: .bold)
        ctaButton.setTitleColor(isEarned ? .black : .white, for: .normal)
        ctaButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
    }

    // MARK: - Populate

    private func populate() {
        let isEarned = (eventType == "BadgeEarned")

        // Badge image
        let resolvedImage = popupBadgeImage(for: badge)
        badgeImageView.image = resolvedImage.image
        badgeImageView.tintColor = resolvedImage.usesFallback ? .systemYellow : nil
        badgeImageView.alpha = 1.0

        headlineLabel.text = sanitizedPopupText(isEarned ? "Badge Earned!" : "Badge Unlocked!")
        titleLabel.text = sanitizedPopupText("\(badge.title) · \(badge.category.rawValue)")
        detailLabel.text = sanitizedPopupText(badge.detail)

        let cta = isEarned ? "Awesome!" : "Let's Go!"
        ctaButton.setTitle(sanitizedPopupText(cta), for: .normal)
    }

    // MARK: - Animate In

    func animateIn() {
        layoutIfNeeded()

        // Start off-screen (slide up) + shrunk
        card.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            .concatenating(CGAffineTransform(translationX: 0, y: 60))

        UIView.animate(
            withDuration: 0.55,
            delay: 0,
            usingSpringWithDamping: 0.65,
            initialSpringVelocity: 0.8,
            options: [.curveEaseOut],
            animations: {
                self.alpha          = 1
                self.card.transform = .identity
            },
            completion: { _ in
                self.runShimmer()
                self.launchParticles()
            }
        )

        // Pulse glow
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue  = 0.4
        pulse.toValue    = 1.0
        pulse.duration   = 0.9
        pulse.autoreverses  = true
        pulse.repeatCount   = .infinity
        glowLayer.add(pulse, forKey: "glow")
    }

    // MARK: - Shimmer

    private func runShimmer() {
        guard let shimmer = shimmerLayer else { return }
        // Frame must be set after layout so it matches the actual image view size
        shimmer.frame = badgeImageView.bounds

        let anim = CABasicAnimation(keyPath: "locations")
        anim.fromValue      = [-0.3, 0.0, 0.3]
        anim.toValue        = [0.7, 1.0, 1.3]
        anim.duration       = 1.4
        anim.repeatCount    = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        shimmer.add(anim, forKey: "shimmer")
    }

    // MARK: - Particles

    private func launchParticles() {
        let colors: [UIColor] = [.systemYellow, .systemOrange, .systemPink, .systemBlue, .systemGreen, .white]
        let count = 28
        let center = CGPoint(x: sparkContainer.bounds.midX, y: sparkContainer.bounds.midY)

        for i in 0..<count {
            let dot        = UIView()
            let size       = CGFloat.random(in: 5...11)
            dot.frame      = CGRect(x: center.x - size/2, y: center.y - size/2, width: size, height: size)
            dot.backgroundColor    = colors.randomElement()!
            dot.layer.cornerRadius = size / 2
            sparkContainer.addSubview(dot)

            let angle     = CGFloat(i) / CGFloat(count) * 2 * .pi + CGFloat.random(in: -0.2...0.2)
            let distance  = CGFloat.random(in: 80...150)
            let dx        = cos(angle) * distance
            let dy        = sin(angle) * distance

            UIView.animate(
                withDuration: Double.random(in: 0.6...1.0),
                delay: Double.random(in: 0...0.15),
                options: [.curveEaseOut],
                animations: {
                    dot.center  = CGPoint(x: center.x + dx, y: center.y + dy)
                    dot.alpha   = 0
                    dot.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
                },
                completion: { _ in dot.removeFromSuperview() }
            )
        }
    }

    // MARK: - Animate Out

    @objc private func dismissTapped() {
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: [.curveEaseIn],
            animations: {
                self.alpha = 0
                self.card.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                    .concatenating(CGAffineTransform(translationX: 0, y: -30))
            },
            completion: { _ in
                self.removeFromSuperview()
                self.onDismiss()
            }
        )
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        // Glow layer fills card + 20pt margin so it bleeds outside the card edges
        let inset: CGFloat = -20
        glowLayer.frame = card.bounds.insetBy(dx: inset, dy: inset)
        // Keep shimmer sized to image view (frame may not be set yet at init time)
        shimmerLayer?.frame = badgeImageView.bounds
    }

    private func popupBadgeImage(for badge: Badging.Badge) -> (image: UIImage?, usesFallback: Bool) {
        guard let assetName = Badging.imageName(for: badge) else {
            return (UIImage(systemName: "star.circle.fill"), true)
        }
        guard let badgeImage = UIImage(named: assetName) else {
            return (UIImage(systemName: "star.circle.fill"), true)
        }
        return (badgeImage.withRenderingMode(.alwaysOriginal), false)
    }

    private func sanitizedPopupText(_ text: String) -> String {
        let filteredScalars = text.unicodeScalars.filter { scalar in
            let isEmojiScalar =
                scalar.properties.isEmojiPresentation ||
                scalar.properties.isEmojiModifier ||
                scalar.properties.isEmojiModifierBase ||
                scalar.value == 0xFE0F ||
                scalar.value == 0x20E3 ||
                (scalar.properties.isEmoji && scalar.value > 0x238C)
            return !isEmojiScalar
        }
        return String(String.UnicodeScalarView(filteredScalars))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - TierBadgeView

/// Small circular badge showing Bronze / Silver / Gold with the right colour.
private final class TierBadgeView: UIView {

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 16
        clipsToBounds      = true
        addSubview(label)
        label.textAlignment = .center
        label.font          = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(for tier: Badging.BadgeTier) {
        switch tier {
        case .bronze:
            backgroundColor = UIColor(red: 0.80, green: 0.50, blue: 0.20, alpha: 1)
            label.text      = nil
        case .silver:
            backgroundColor = UIColor(red: 0.75, green: 0.75, blue: 0.80, alpha: 1)
            label.text      = nil
        case .gold:
            backgroundColor = UIColor(red: 1.00, green: 0.80, blue: 0.10, alpha: 1)
            label.text      = nil
        }
    }
}

// MARK: - PaddedLabel

private final class PaddedLabel: UILabel {
    var insets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + insets.left + insets.right,
                      height: s.height + insets.top + insets.bottom)
    }
}
