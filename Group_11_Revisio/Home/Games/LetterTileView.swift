//
//  LetterTileView.swift
//  Group_11_Revisio
//
//  Created by Mithil on 28/01/26.
//


//
//  LetterTileView.swift
//  Game1
//
//  Created by SDC-USER on 24/01/26.
//
import UIKit

final class LetterTileView: UIView {

    enum State {
        case empty
        case correct
        case present
        case absent
    }

    // MARK: - Subviews

    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterial)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let tintOverlay: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    let label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        clipsToBounds = true
        layer.cornerRadius = 10
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor

        // ⬇️ Order MATTERS
        addSubview(blurView)
        addSubview(tintOverlay)
        addSubview(label)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),

            tintOverlay.topAnchor.constraint(equalTo: topAnchor),
            tintOverlay.bottomAnchor.constraint(equalTo: bottomAnchor),
            tintOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            tintOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),

            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    // MARK: - Update State

    func update(letter: Character, state: State) {
        label.text = String(letter).uppercased()

        let tintColor: UIColor
        let borderColor: UIColor

        switch state {
        case .empty:
            tintColor = .clear
            borderColor = UIColor.systemGray4

        case .present:
            tintColor = UIColor.systemYellow.withAlphaComponent(0.35)
            borderColor = UIColor.systemYellow

        case .correct:
            tintColor = UIColor.systemGreen.withAlphaComponent(0.45)
            borderColor = UIColor.systemGreen.withAlphaComponent(0.45)

        case .absent:
            tintColor = UIColor.systemGray.withAlphaComponent(0.25)
            borderColor = UIColor.systemGray
        }

        UIView.animate(withDuration: 0.25) {
            self.tintOverlay.backgroundColor = tintColor
            self.layer.borderColor = borderColor.cgColor
        }
    }

    // MARK: - Reset

    func reset() {
        label.text = ""
        tintOverlay.backgroundColor = .clear
    }
}

struct GuessResult {

    struct Evaluation {
        let character: Character
        let state: LetterTileView.State
    }

    let evaluations: [Evaluation]

    var isCorrect: Bool {
        evaluations.allSatisfy { $0.state == .correct }
    }
}

final class WordleEngine {

    // MARK: - Private State
    private let answer: String

    // MARK: - Public Read-Only State
    private(set) var attempts: Int = 0
    let maxAttempts: Int = 4

    // MARK: - Init
    init(answer: String) {
        self.answer = answer.lowercased()
    }

    // MARK: - Safe Read Access (IMPORTANT)
    var revealedAnswer: String {
        answer
    }

    // MARK: - Core Logic
    func evaluate(_ guess: String) -> GuessResult {
        attempts += 1

        let answerChars = Array(answer)
        let guessChars = Array(guess.lowercased())

        var result: [GuessResult.Evaluation] = []

        for i in 0..<guessChars.count {
            let char = guessChars[i]

            if char == answerChars[i] {
                result.append(.init(character: char, state: .correct))
            } else if answerChars.contains(char) {
                result.append(.init(character: char, state: .present))
            } else {
                result.append(.init(character: char, state: .absent))
            }
        }

        return GuessResult(evaluations: result)
    }

    // MARK: - Game State
    func hasWon(_ result: GuessResult) -> Bool {
        result.isCorrect
    }

    func hasLost() -> Bool {
        attempts >= maxAttempts
    }

    func canContinue() -> Bool {
        attempts < maxAttempts
    }

    // MARK: - Reset
    func reset() {
        attempts = 0
    }
    
}
