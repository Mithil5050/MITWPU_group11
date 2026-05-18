import UIKit

// MARK: - Premium Instructions View Controller
class FlashcardInstructionsViewController: UIViewController {
    var instructions: [(icon: String, text: String)] = []

    private let container: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
        v.layer.cornerRadius = 24
        v.layer.masksToBounds = true
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        setupUI()
    }

    private func setupUI() {
        view.addSubview(container)

        let titleLabel = UILabel()
        titleLabel.text = "How to use Flashcards"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.contentView.addSubview(titleLabel)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.contentView.addSubview(stack)

        for item in instructions {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 14
            row.alignment = .center

            let icon = UIImageView(image: UIImage(systemName: item.icon))
            icon.tintColor = .systemIndigo
            icon.contentMode = .scaleAspectFit
            NSLayoutConstraint.activate([
                icon.widthAnchor.constraint(equalToConstant: 24),
                icon.heightAnchor.constraint(equalToConstant: 24)
            ])

            let label = UILabel()
            label.text = item.text
            label.font = .systemFont(ofSize: 15, weight: .medium)
            label.textColor = .white.withAlphaComponent(0.9)
            label.numberOfLines = 0

            row.addArrangedSubview(icon)
            row.addArrangedSubview(label)
            stack.addArrangedSubview(row)
        }

        let button = UIButton(type: .system)
        button.setTitle("Got it!", for: .normal)
        button.backgroundColor = .systemIndigo
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        button.layer.cornerRadius = 14
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        container.contentView.addSubview(button)

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.82),

            titleLabel.topAnchor.constraint(equalTo: container.contentView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: container.contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: container.contentView.trailingAnchor, constant: -20),

            stack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: container.contentView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: container.contentView.trailingAnchor, constant: -24),

            button.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 30),
            button.leadingAnchor.constraint(equalTo: container.contentView.leadingAnchor, constant: 24),
            button.trailingAnchor.constraint(equalTo: container.contentView.trailingAnchor, constant: -24),
            button.bottomAnchor.constraint(equalTo: container.contentView.bottomAnchor, constant: -24),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    @objc private func dismissSelf() { dismiss(animated: true) }
}

// MARK: - Flashcard Overlay
class FlashcardDetailOverlayVC: UIViewController {
    var term: String = ""
    var definition: String = ""
    private var isShowingTerm = true

    private let cardContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "1C1C1E")
        v.layer.cornerRadius = 32
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.5
        v.layer.shadowRadius = 20
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let contentLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 24, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.85)

        let tapToDismiss = UITapGestureRecognizer(target: self, action: #selector(dismissDetail))
        view.addGestureRecognizer(tapToDismiss)

        view.addSubview(cardContainer)
        cardContainer.addSubview(contentLabel)

        NSLayoutConstraint.activate([
            cardContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            cardContainer.heightAnchor.constraint(equalTo: cardContainer.widthAnchor, multiplier: 1.2),

            contentLabel.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: 30),
            contentLabel.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -30),
            contentLabel.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor)
        ])

        contentLabel.text = term

        let cardTap = UITapGestureRecognizer(target: self, action: #selector(flipCard))
        cardContainer.addGestureRecognizer(cardTap)
        tapToDismiss.require(toFail: cardTap)
    }

    @objc private func flipCard() {
        isShowingTerm = !isShowingTerm
        UIView.transition(with: cardContainer, duration: 0.4, options: [.transitionFlipFromRight, .showHideTransitionViews], animations: {
            self.contentLabel.text = self.isShowingTerm ? self.term : self.definition
            self.contentLabel.font = .systemFont(ofSize: self.isShowingTerm ? 24 : 18, weight: self.isShowingTerm ? .bold : .medium)

            // Background color logic: Term is Dark Grey, Definition is themed Purple
            self.cardContainer.backgroundColor = self.isShowingTerm ?
                UIColor(hex: "1C1C1E") :
                UIColor.systemPurple.withAlphaComponent(0.15)

            // Optional: Add border color to match
            self.cardContainer.layer.borderColor = self.isShowingTerm ?
                UIColor.white.withAlphaComponent(0.1).cgColor :
                UIColor.systemPurple.withAlphaComponent(0.4).cgColor
            self.cardContainer.layer.borderWidth = 1
        }, completion: nil)
    }

    @objc private func dismissDetail() { dismiss(animated: true) }
}
