import UIKit

/// A reusable, premium loading overlay for all ReviseQ game screens.
/// Features the bot mascot, animated pulse, spinner, and customizable message.
final class GameLoadingOverlayView: UIView {

    // MARK: - Subviews
    private let mascotImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "bot_pencil"))
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.color = UIColor(red: 0.55, green: 0.70, blue: 1.0, alpha: 1.0)
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(white: 1.0, alpha: 0.5)
        l.textAlignment = .center
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Init
    init(title: String, subtitle: String = "AI is crafting your experience...") {
        super.init(frame: .zero)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup
    private func setupView() {
        // Dark navy background — matches DiagramDash style
        backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.14, alpha: 0.97)
        translatesAutoresizingMaskIntoConstraints = false
        alpha = 0

        addSubview(mascotImageView)
        addSubview(spinner)
        addSubview(titleLabel)
        addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            mascotImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            mascotImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -80),
            mascotImageView.widthAnchor.constraint(equalToConstant: 140),
            mascotImageView.heightAnchor.constraint(equalToConstant: 140),

            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.topAnchor.constraint(equalTo: mascotImageView.bottomAnchor, constant: 20),

            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),

            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
        ])

        spinner.startAnimating()
        startMascotAnimation()
    }

    private func startMascotAnimation() {
        UIView.animate(
            withDuration: 1.2,
            delay: 0,
            options: [.repeat, .autoreverse, .allowUserInteraction],
            animations: {
                self.mascotImageView.transform = CGAffineTransform(translationX: 0, y: -10)
                    .scaledBy(x: 1.05, y: 1.05)
            }
        )
    }

    // MARK: - Public API

    /// Attach and animate in from a parent view.
    func show(in parent: UIView) {
        parent.addSubview(self)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: parent.topAnchor),
            bottomAnchor.constraint(equalTo: parent.bottomAnchor),
            leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            trailingAnchor.constraint(equalTo: parent.trailingAnchor),
        ])
        UIView.animate(withDuration: 0.25) { self.alpha = 1.0 }
    }

    /// Update the message while loading.
    func updateTitle(_ newTitle: String) {
        UIView.transition(with: titleLabel, duration: 0.3, options: .transitionCrossDissolve) {
            self.titleLabel.text = newTitle
        }
    }

    /// Animate out and remove from superview.
    func hide(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
            completion?()
        }
    }

    /// Transition from loading → celebration (pirouette → wave → cheer),
    /// then auto-dismiss after the hold duration.
    func completeWithCelebration(
        statusText: String = "All Done!",
        subtitle: String = "Your content is ready 🎉",
        holdDuration: TimeInterval = 1.8,
        completion: (() -> Void)? = nil
    ) {
        // Stop spinner & idle float
        spinner.stopAnimating()
        mascotImageView.layer.removeAllAnimations()
        mascotImageView.transform = .identity

        // Fade out loading text
        UIView.animate(withDuration: 0.2) {
            self.titleLabel.alpha = 0
            self.subtitleLabel.alpha = 0
            self.spinner.alpha = 0
        }

        // Play the celebration on top
        let celebration = MascotCelebrationView(
            statusText: statusText,
            subtitle: subtitle
        )
        celebration.play(in: self, holdDuration: holdDuration) { [weak self] in
            celebration.dismiss {
                self?.hide(completion: completion)
            }
        }
    }
}
