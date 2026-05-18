//
//  XPInfoSheetViewController.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 05/03/26.
//

import UIKit

class XPInfoSheetViewController: UIViewController {

    private let scrollView   = UIScrollView()
    private let contentStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // dynamic navigation title based on current level
        let manager = ProgressDataManager.shared
        navigationItem.title = "Level \(manager.userLevel)"

        setupLayout()
        populateContent()
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        contentStack.axis    = .vertical
        contentStack.spacing = 20
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    private func populateContent() {
        let manager   = ProgressDataManager.shared
        let remaining = max(0, manager.requiredXPForCurrentLevel - manager.currentLevelXP)

        // Next level callout
        contentStack.addArrangedSubview(makeCallout(
            "You need \(remaining) more XP to reach Level \(manager.userLevel + 1)."
        ))

        contentStack.addArrangedSubview(makeDivider())

        // "How XP Works" 
        let mainHeadingLabel = UILabel()
        mainHeadingLabel.text = "How XP Works"
        mainHeadingLabel.font = .systemFont(ofSize: 22, weight: .bold)
        mainHeadingLabel.textColor = .label
        contentStack.addArrangedSubview(mainHeadingLabel)

        // What is XP
        let boltImageView = UIImageView(image: UIImage(systemName: "bolt.fill"))
        boltImageView.tintColor = .systemYellow
        boltImageView.contentMode = .scaleAspectFit

        boltImageView.translatesAutoresizingMaskIntoConstraints = false
        boltImageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        boltImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let headingLabel = makeHeading("Experience Points (XP)")

        let headingStack = UIStackView(arrangedSubviews: [boltImageView, headingLabel])
        headingStack.axis = .horizontal
        headingStack.spacing = 8 // Space between the icon and the text
        headingStack.alignment = .center

        contentStack.addArrangedSubview(headingStack)

        contentStack.addArrangedSubview(makeBody(
            "XP measures your learning activity across ReviseQ. " +
            "The more you study, the faster you level up."
        ))

        // How XP is earned
        contentStack.addArrangedSubview(makeDivider())
        contentStack.addArrangedSubview(makeHeading("How You Earn XP"))

        let earningItems: [(String, UIColor, String)] = [
            ("checkmark.circle.fill", .systemIndigo, "Completing a quiz"),
            ("rectangle.on.rectangle.angled", .systemIndigo, "Reviewing flashcards"),
            ("doc.text.fill", .systemIndigo, "Generating AI notes or cheatsheets"),
            ("flame.fill", .systemIndigo, "Maintaining your daily streak (+100 XP / day)"),
            ("trophy.fill", .systemIndigo, "Unlocking and earning badges"),
            ("target", .systemIndigo, "Completing quests and practice sessions")
        ]

        for (icon, color, text) in earningItems {
            contentStack.addArrangedSubview(makeBulletRow(icon: icon, color: color, text: text))
        }

        // How leveling works
        contentStack.addArrangedSubview(makeDivider())
        contentStack.addArrangedSubview(makeHeading("How Leveling Works"))
        contentStack.addArrangedSubview(makeBody(
            "When your XP reaches the threshold for your current level, " +
            "you level up automatically. Any extra XP carries over — " +
            "it is never lost."
        ))
        contentStack.addArrangedSubview(makeBody(
            "Example: You need 250 XP for Level 1. You earn 300 XP. " +
            "You level up and carry 50 XP toward Level 2."
        ))
    }

    // Reusable view builders
    private func makeHeading(_ text: String) -> UILabel {
        let label = UILabel()
        label.text          = text
        label.font          = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor     = .label
        label.numberOfLines = 0
        return label
    }

    private func makeBody(_ text: String) -> UILabel {
        let label = UILabel()
        label.text          = text
        label.font          = .systemFont(ofSize: 15, weight: .regular)
        label.textColor     = .secondaryLabel
        label.numberOfLines = 0
        return label
    }

    private func makeBulletRow(icon: String, color: UIColor, text: String) -> UIView {
        let row       = UIStackView()
        row.axis      = .horizontal
        row.spacing   = 12
        row.alignment = .center

        let imageView = UIImageView(image: UIImage(systemName: icon))
        imageView.tintColor                = color
        imageView.contentMode              = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.heightAnchor.constraint(equalToConstant: 20)
        ])
        imageView.setContentHuggingPriority(.required, for: .horizontal)

        let textLabel           = UILabel()
        textLabel.text          = text
        textLabel.font          = .systemFont(ofSize: 15)
        textLabel.textColor     = .secondaryLabel
        textLabel.numberOfLines = 0

        row.addArrangedSubview(imageView)
        row.addArrangedSubview(textLabel)
        return row
    }

    private func makeCallout(_ text: String) -> UIView {
        let card = UIView()
        card.backgroundColor    = UIColor.systemBlue.withAlphaComponent(0.1)
        card.layer.cornerRadius = 12

        let label           = UILabel()
        label.text          = text
        label.font          = .systemFont(ofSize: 15, weight: .medium)
        label.textColor     = .systemBlue
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
        return card
    }

    private func makeDivider() -> UIView {
        let line = UIView()
        line.backgroundColor = .separator
        line.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return line
    }
}
