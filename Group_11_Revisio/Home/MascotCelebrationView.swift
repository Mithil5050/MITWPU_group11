//
//  MascotCelebrationView.swift
//  Group_11_Revisio
//
//  Reusable "Interactive Response" mascot celebration overlay.
//  Plays a pirouette → wave → cheer animation sequence when loading completes.
//

import UIKit

final class MascotCelebrationView: UIView {

    // MARK: - Subviews

    private let mascotImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "bot_pencil"))
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// Heart-eyes emoji overlay — hidden until the cheer phase
    private let heartEyesLabel: UILabel = {
        let l = UILabel()
        l.text = "😍"
        l.font = .systemFont(ofSize: 42)
        l.textAlignment = .center
        l.alpha = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let statusLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.alpha = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .medium)
        l.textColor = UIColor.white.withAlphaComponent(0.6)
        l.textAlignment = .center
        l.alpha = 0
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    /// Small confetti particle emitter behind the mascot
    private let confettiLayer = CAEmitterLayer()

    // MARK: - Init

    init(
        statusText: String = "All Done!",
        subtitle: String = "Your content is ready 🎉"
    ) {
        super.init(frame: .zero)
        statusLabel.text = statusText
        subtitleLabel.text = subtitle
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
        alpha = 0

        addSubview(mascotImageView)
        addSubview(heartEyesLabel)
        addSubview(statusLabel)
        addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            mascotImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            mascotImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -50),
            mascotImageView.widthAnchor.constraint(equalToConstant: 160),
            mascotImageView.heightAnchor.constraint(equalToConstant: 160),

            // Heart eyes — sits on top of the mascot's face area
            heartEyesLabel.centerXAnchor.constraint(equalTo: mascotImageView.centerXAnchor),
            heartEyesLabel.centerYAnchor.constraint(equalTo: mascotImageView.centerYAnchor, constant: -10),

            statusLabel.topAnchor.constraint(equalTo: mascotImageView.bottomAnchor, constant: 20),
            statusLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 6),
            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
        ])

        // Prepare 3D perspective on the mascot's layer
        var perspective = CATransform3DIdentity
        perspective.m34 = -1.0 / 800.0
        mascotImageView.layer.sublayerTransform = perspective
    }

    // MARK: - Public API

    /// Plays the full celebration sequence:
    /// 1. Fade in
    /// 2. Pirouette (3D Y-axis spin)
    /// 3. Wave & bounce (spring scale)
    /// 4. Heart-eyes + confetti + status text
    /// 5. Hold, then call completion
    func play(in parent: UIView, holdDuration: TimeInterval = 1.8, completion: (() -> Void)? = nil) {
        parent.addSubview(self)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: parent.topAnchor),
            bottomAnchor.constraint(equalTo: parent.bottomAnchor),
            leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            trailingAnchor.constraint(equalTo: parent.trailingAnchor),
        ])
        parent.layoutIfNeeded()

        // Fade in
        UIView.animate(withDuration: 0.2) { self.alpha = 1 }

        // Step 1 — Pirouette (0.0s → 0.6s)
        runPirouette {
            // Step 2 — Bounce/Wave (0.6s → 1.1s)
            self.runWaveBounce {
                // Step 3 — Heart-eyes + Confetti + Text (1.1s → ...)
                self.showCheer()

                // Hold, then call completion
                DispatchQueue.main.asyncAfter(deadline: .now() + holdDuration) {
                    completion?()
                }
            }
        }
    }

    /// Immediately remove from superview with a fade.
    func dismiss(completion: (() -> Void)? = nil) {
        confettiLayer.birthRate = 0
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }) { _ in
            self.removeFromSuperview()
            completion?()
        }
    }

    // MARK: - Animation Phases

    /// Phase 1 — Quick 360° Y-axis spin (the "pirouette")
    private func runPirouette(completion: @escaping () -> Void) {
        let spin = CABasicAnimation(keyPath: "transform.rotation.y")
        spin.fromValue = 0
        spin.toValue = CGFloat.pi * 2
        spin.duration = 0.6
        spin.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        mascotImageView.layer.add(spin, forKey: "pirouette")
        CATransaction.commit()
    }

    /// Phase 2 — Bouncy scale + slight vertical hop (the "wave")
    private func runWaveBounce(completion: @escaping () -> Void) {
        // Haptic burst
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        mascotImageView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            .translatedBy(x: 0, y: 12)

        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.45,
            initialSpringVelocity: 0.9,
            options: [],
            animations: {
                self.mascotImageView.transform = .identity
            },
            completion: { _ in completion() }
        )
    }

    /// Phase 3 — Show heart-eyes, confetti, and status text
    private func showCheer() {
        // Haptic success
        let notif = UINotificationFeedbackGenerator()
        notif.notificationOccurred(.success)

        // Heart-eyes pop
        heartEyesLabel.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.8,
            options: [],
            animations: {
                self.heartEyesLabel.alpha = 1
                self.heartEyesLabel.transform = .identity
            }
        )

        // Fade heart-eyes out after a beat so it doesn't obscure mascot
        UIView.animate(withDuration: 0.3, delay: 0.8) {
            self.heartEyesLabel.alpha = 0
        }

        // Status text slides up
        statusLabel.transform = CGAffineTransform(translationX: 0, y: 16)
        subtitleLabel.transform = CGAffineTransform(translationX: 0, y: 16)

        UIView.animate(withDuration: 0.4, delay: 0.1, options: .curveEaseOut) {
            self.statusLabel.alpha = 1
            self.statusLabel.transform = .identity
        }
        UIView.animate(withDuration: 0.4, delay: 0.2, options: .curveEaseOut) {
            self.subtitleLabel.alpha = 1
            self.subtitleLabel.transform = .identity
        }

        // Confetti burst
        emitConfetti()
    }

    // MARK: - Confetti

    private func emitConfetti() {
        confettiLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY - 50)
        confettiLayer.emitterSize = CGSize(width: 10, height: 10)
        confettiLayer.emitterShape = .point
        confettiLayer.renderMode = .additive

        let colors: [UIColor] = [
            UIColor(red: 0.39, green: 0.40, blue: 0.94, alpha: 1),  // ReviseQ indigo
            UIColor(red: 0.35, green: 0.78, blue: 0.98, alpha: 1),  // Cyan
            UIColor(red: 1.00, green: 0.76, blue: 0.27, alpha: 1),  // Gold
            UIColor(red: 0.53, green: 0.84, blue: 0.41, alpha: 1),  // Green
            UIColor(red: 0.95, green: 0.40, blue: 0.53, alpha: 1),  // Pink
        ]

        var cells: [CAEmitterCell] = []
        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 18
            cell.lifetime = 2.5
            cell.velocity = 180
            cell.velocityRange = 80
            cell.emissionRange = .pi * 2
            cell.spin = 4
            cell.spinRange = 6
            cell.scale = 0.06
            cell.scaleRange = 0.04
            cell.color = color.cgColor
            cell.alphaSpeed = -0.4
            cell.yAcceleration = 120   // gravity pull

            // Use a small filled circle as the confetti shape
            let size = CGSize(width: 12, height: 12)
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            let ctx = UIGraphicsGetCurrentContext()!
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(origin: .zero, size: size))
            cell.contents = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
            UIGraphicsEndImageContext()

            cells.append(cell)
        }

        confettiLayer.emitterCells = cells
        layer.insertSublayer(confettiLayer, at: 0)

        // Stop emission after a brief burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.confettiLayer.birthRate = 0
        }
    }
}
