import UIKit

class ReviewQuestionCell: UITableViewCell {

    @IBOutlet weak var QuestionLabel: UILabel!

    @IBOutlet weak var userAnswerLabel: UILabel!

    @IBOutlet weak var correctAnswerLabel: UILabel!
    func configure(with detail: QuestionResultDetail, index: Int) {

        QuestionLabel.numberOfLines = 0
        QuestionLabel.text = "Q\(index + 1). \(detail.questionText)"

        let userAnswerText = detail.selectedAnswer ?? "N/A"
        userAnswerLabel.text = "Your answer: \(userAnswerText)"

        correctAnswerLabel.text = "Correct answer: \(detail.correctOptionLetter)"

        if detail.wasCorrect {
            self.contentView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        } else {
            self.contentView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        }
    }
}
