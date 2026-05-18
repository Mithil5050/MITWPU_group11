import UIKit

class FlashcardModeSelectionViewController: UIViewController {

    var onNormalModeSelected: (() -> Void)?

    var onChallengeModeSelected: (() -> Void)?

    var onCanceled: (() -> Void)?

    private let blurEffectView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let view = UIVisualEffectView(effect: blur)
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 24
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowRadius = 20
        view.layer.shadowOffset = CGSize(width: 0, height: 10)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Select Study Mode"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let normalModeButton: UIButton = createModeButton(
        title: "Normal Mode",
        description: "Standard flashcards with front and back.\nSwipe to flip and review.",
        iconName: "rectangle.portrait.on.rectangle.portrait",
        color: .systemBlue
    )

    private let challengeModeButton: UIButton = createModeButton(
        title: "Challenge Mode",
        description: "Test your knowledge.\nType the correct term to unlock the card.",
        iconName: "keyboard",
        color: UIColor.systemIndigo
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }

    private func setupUI() {
        view.backgroundColor = .clear

        view.addSubview(blurEffectView)
        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: view.topAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        view.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])

        containerView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])

        let stackView = UIStackView(arrangedSubviews: [normalModeButton, challengeModeButton])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24)
        ])

        normalModeButton.addTarget(self, action: #selector(normalModeTapped), for: .touchUpInside)
        challengeModeButton.addTarget(self, action: #selector(challengeModeTapped), for: .touchUpInside)

        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        containerView.alpha = 0
    }

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        blurEffectView.addGestureRecognizer(tap)
    }

    @objc private func normalModeTapped() {
        animateOut { [weak self] in
            self?.onNormalModeSelected?()
        }
    }

    @objc private func challengeModeTapped() {
        animateOut { [weak self] in
            self?.onChallengeModeSelected?()
        }
    }

    @objc private func backgroundTapped() {
        animateOut { [weak self] in
            self?.onCanceled?()
        }
    }

    private func animateIn() {
        UIView.animate(withDuration: 0.3, animations: {
            self.blurEffectView.alpha = 1.0
        })

        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.containerView.transform = .identity
            self.containerView.alpha = 1.0
        }, completion: nil)
    }

    private func animateOut(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2, animations: {
            self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.containerView.alpha = 0
            self.blurEffectView.alpha = 0
        }) { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }

    private static func createModeButton(title: String, description: String, iconName: String, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = color.withAlphaComponent(0.1)
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1.5
        button.layer.borderColor = color.withAlphaComponent(0.3).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false

        let container = UIStackView()
        container.axis = .horizontal
        container.alignment = .center
        container.spacing = 16
        container.isUserInteractionEnabled = false
        container.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(container)

        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = color
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32)
        ])

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 4

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = color

        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 13, weight: .regular)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(descLabel)

        container.addArrangedSubview(iconView)
        container.addArrangedSubview(textStack)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: button.topAnchor, constant: 16),
            container.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -16),
            container.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16)
        ])

        return button
    }
}
