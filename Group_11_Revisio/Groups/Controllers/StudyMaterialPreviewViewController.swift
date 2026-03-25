//
//  StudyMaterialPreviewViewController.swift
//  Group_11_Revisio
//

import UIKit

// Renders study material content sent via group chat.
// Supports Notes, Cheatsheet (scrollable text), Flashcards (swipeable cards), Quiz (question list).
class StudyMaterialPreviewViewController: UIViewController {

    var materialType: String = ""   // "Notes" | "Cheatsheet" | "Flashcards" | "Quiz"
    var materialName: String = ""
    var content: String      = ""   // packed content stored in messages.content

    private let scrollView   = UIScrollView()
    private let contentStack = UIStackView()

    // Flashcard state
    private var flashcards: [(front: String, back: String)] = []
    private var currentCard = 0
    private var isShowingFront = true

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = materialName.isEmpty ? materialType : materialName

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(closeTapped))

        switch materialType {
        case "Flashcards": buildFlashcardUI()
        case "Quiz":       buildQuizUI()
        default:           buildTextUI()   // Notes + Cheatsheet
        }
    }

    @objc private func closeTapped() { dismiss(animated: true) }

    // MARK: - Notes / Cheatsheet

    private func buildTextUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let label = UILabel()
        label.text            = content.isEmpty ? "No content available." : content
        label.numberOfLines   = 0
        label.font            = UIFont.systemFont(ofSize: 15)
        label.textColor       = .label
        label.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            label.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            label.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }

    // MARK: - Flashcards

    private func buildFlashcardUI() {
        flashcards = parseFlashcards(from: content)
        if flashcards.isEmpty {
            buildTextUI(); return
        }
        currentCard   = 0
        isShowingFront = true

        let card = makeCardView()
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        let prev = UIButton(type: .system)
        prev.setTitle("← Prev", for: .normal)
        prev.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        prev.addTarget(self, action: #selector(prevCard), for: .touchUpInside)
        prev.tag = 100

        let next = UIButton(type: .system)
        next.setTitle("Next →", for: .normal)
        next.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        next.addTarget(self, action: #selector(nextCard), for: .touchUpInside)
        next.tag = 101

        let counter = UILabel()
        counter.tag       = 102
        counter.font      = UIFont.systemFont(ofSize: 13)
        counter.textColor = .secondaryLabel
        counter.textAlignment = .center

        let btnRow = UIStackView(arrangedSubviews: [prev, counter, next])
        btnRow.axis         = .horizontal
        btnRow.distribution = .equalSpacing
        btnRow.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(btnRow)

        let hint = UILabel()
        hint.text          = "Tap card to flip"
        hint.font          = UIFont.systemFont(ofSize: 12)
        hint.textColor     = .tertiaryLabel
        hint.textAlignment = .center
        hint.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hint)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            card.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -48),
            card.heightAnchor.constraint(equalToConstant: 220),
            btnRow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            btnRow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            btnRow.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 24),
            hint.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hint.topAnchor.constraint(equalTo: btnRow.bottomAnchor, constant: 12)
        ])

        card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(flipCard)))
        updateFlashcardDisplay()
    }

    private func makeCardView() -> UIView {
        let card = UIView()
        card.tag = 99
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 16
        card.layer.shadowColor  = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowRadius  = 8
        card.layer.shadowOffset  = CGSize(width: 0, height: 4)

        let lbl = UILabel()
        lbl.tag           = 103
        lbl.numberOfLines = 0
        lbl.textAlignment = .center
        lbl.font          = UIFont.systemFont(ofSize: 17, weight: .medium)
        lbl.textColor     = .label
        lbl.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(lbl)
        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            lbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            lbl.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
        return card
    }

    @objc private func flipCard() {
        guard let card = view.viewWithTag(99),
              let lbl  = card.viewWithTag(103) as? UILabel else { return }
        isShowingFront.toggle()
        UIView.transition(with: card, duration: 0.35,
                          options: .transitionFlipFromRight) {
            lbl.text = self.isShowingFront
                ? self.flashcards[self.currentCard].front
                : self.flashcards[self.currentCard].back
        }
    }

    @objc private func prevCard() {
        guard currentCard > 0 else { return }
        currentCard -= 1
        isShowingFront = true
        updateFlashcardDisplay()
    }

    @objc private func nextCard() {
        guard currentCard < flashcards.count - 1 else { return }
        currentCard += 1
        isShowingFront = true
        updateFlashcardDisplay()
    }

    private func updateFlashcardDisplay() {
        guard let card    = view.viewWithTag(99),
              let lbl     = card.viewWithTag(103) as? UILabel,
              let counter = view.viewWithTag(102) as? UILabel else { return }
        lbl.text     = flashcards[currentCard].front
        counter.text = "\(currentCard + 1) / \(flashcards.count)"
    }

    // MARK: - Quiz

    private func buildQuizUI() {
        let questions = parseQuiz(from: content)
        if questions.isEmpty { buildTextUI(); return }

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis    = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])

        for (i, q) in questions.enumerated() {
            let card = buildQuizCard(index: i + 1, question: q)
            contentStack.addArrangedSubview(card)
        }
    }

    private func buildQuizCard(index: Int, question: QuizQuestion) -> UIView {
        let card = UIView()
        card.backgroundColor    = .secondarySystemBackground
        card.layer.cornerRadius = 12
        card.clipsToBounds      = true

        let numLabel = UILabel()
        numLabel.text      = "Q\(index)"
        numLabel.font      = UIFont.systemFont(ofSize: 12, weight: .bold)
        numLabel.textColor = .systemBlue

        let qLabel = UILabel()
        qLabel.text          = question.questionText
        qLabel.font          = UIFont.systemFont(ofSize: 15, weight: .semibold)
        qLabel.numberOfLines = 0
        qLabel.textColor     = .label

        let stack = UIStackView(arrangedSubviews: [numLabel, qLabel])
        stack.axis    = .vertical
        stack.spacing = 6

        for (ai, answer) in question.answers.enumerated() {
            let row = UILabel()
            let isCorrect = ai == question.correctAnswerIndex
            row.text          = (isCorrect ? "✓ " : "   ") + answer
            row.font          = UIFont.systemFont(ofSize: 14)
            row.textColor     = isCorrect ? .systemGreen : .secondaryLabel
            row.numberOfLines = 0
            stack.addArrangedSubview(row)
        }

        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12)
        ])
        return card
    }

    // MARK: - Parsers

    private func parseFlashcards(from raw: String) -> [(front: String, back: String)] {
        guard let data = raw.data(using: .utf8) else { return [] }

        // Try array of {front, back} objects
        struct FC: Decodable { let front: String; let back: String }
        if let arr = try? JSONDecoder().decode([FC].self, from: data) {
            return arr.map { ($0.front, $0.back) }
        }

        // Try {flashcards: [{front, back}]}
        struct Wrapper: Decodable { let flashcards: [FC] }
        if let w = try? JSONDecoder().decode(Wrapper.self, from: data) {
            return w.flashcards.map { ($0.front, $0.back) }
        }

        // Try Q/A line format: "Q: ...\nA: ..."
        var result: [(String, String)] = []
        let lines = raw.components(separatedBy: "\n")
        var i = 0
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.lowercased().hasPrefix("q:") || line.lowercased().hasPrefix("front:") {
                let front = line.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                if i + 1 < lines.count {
                    let nextLine = lines[i + 1].trimmingCharacters(in: .whitespaces)
                    if nextLine.lowercased().hasPrefix("a:") || nextLine.lowercased().hasPrefix("back:") {
                        let back = nextLine.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                        result.append((front, back))
                        i += 2; continue
                    }
                }
            }
            i += 1
        }
        return result
    }

    private func parseQuiz(from raw: String) -> [QuizQuestion] {
        guard let data = raw.data(using: .utf8) else { return [] }

        // Try direct array
        if let arr = try? JSONDecoder().decode([QuizQuestion].self, from: data) {
            return arr
        }

        // Try {questions: [...]}
        struct Wrapper: Decodable { let questions: [QuizQuestion] }
        if let w = try? JSONDecoder().decode(Wrapper.self, from: data) {
            return w.questions
        }

        return []
    }
}
