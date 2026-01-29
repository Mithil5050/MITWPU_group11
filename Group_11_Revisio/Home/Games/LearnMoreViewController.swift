//
//  LearnMoreViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 28/01/26.
//


import UIKit

final class LearnMoreViewController: UIViewController {

    private let word: String
    private let definition: String

    // MARK: - UI
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let container = UIView()
    private let titleLabel = UILabel()
    private let definitionLabel = UILabel()

    // MARK: - Init
    init(word: String, definition: String) {
        self.word = word
        self.definition = definition
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        animateIn()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2)

        // Blur
        blurView.frame = view.bounds
        view.addSubview(blurView)

        // Container
        container.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.7)
        container.layer.cornerRadius = 22
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.2
        container.layer.shadowRadius = 20
        container.layer.shadowOffset = .zero
        container.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        // Title
        titleLabel.text = word
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center

        // Definition
        definitionLabel.text = definition
        definitionLabel.font = .systemFont(ofSize: 16)
        definitionLabel.textAlignment = .center
        definitionLabel.numberOfLines = 0
        definitionLabel.textColor = .secondaryLabel

        // Buttons
        let backButton = makeButton(title: "Go Back", style: .secondary)
        let learnButton = makeButton(title: "Next", style: .primary)

        backButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        learnButton.addTarget(self, action: #selector(openLearnMore), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            definitionLabel,
            learnButton,
            backButton
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -24)
        ])
    }

    // MARK: - Animations
    private func animateIn() {
        container.transform = CGAffineTransform(translationX: 0, y: 60)
        container.alpha = 0

        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.6,
            options: [.curveEaseOut],
            animations: {
                self.container.transform = .identity
                self.container.alpha = 1
            }
        )
    }

    // MARK: - Actions
    @objc private func dismissSelf() {
        dismiss(animated: true)
    }

    @objc private func openLearnMore() {

        // 1️⃣ First dismiss the glass popover
        dismiss(animated: true) {

            // 2️⃣ Then present native iOS alert
            let alert = UIAlertController(
                title: "It is Over",
                message: "Click on Close to Continue",
                preferredStyle: .alert
            )

            alert.addAction(
                UIAlertAction(title: "Close", style: .default)
            )

            // Present from the top-most VC
            UIApplication.shared
                .connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?
                .windows
                .first?
                .rootViewController?
                .present(alert, animated: true)
        }
    }
    // MARK: - Button Factory
    private func makeButton(title: String, style: ButtonStyle) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 14
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true

        switch style {
        case .primary:
            button.backgroundColor = .systemBlue
            button.setTitleColor(.white, for: .normal)
        case .secondary:
            button.backgroundColor = .systemGray5
            button.setTitleColor(.label, for: .normal)
        }

        return button
    }

    private enum ButtonStyle {
        case primary, secondary
    }
}
