//
//  ReviewQuestionCell.swift
//  Group_11_Revisio
//
//  Created by Ayaana Talwar on 15/12/25.
//

import UIKit

class ReviewQuestionCell: UITableViewCell {
    
    @IBOutlet weak var QuestionLabel: UILabel!
    
    @IBOutlet weak var userAnswerLabel: UILabel!
    
    @IBOutlet weak var correctAnswerLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func configure(with detail: QuestionResultDetail, index: Int) {
        
        // 🛑 Note: If you renamed the IBOutlet, adjust here.
        QuestionLabel.numberOfLines = 0
        QuestionLabel.text = "Q\(index + 1). \(detail.questionText)"
        
        let userAnswerText = detail.selectedAnswer ?? "N/A"
        userAnswerLabel.text = "Your answer: \(userAnswerText)"
        
        // 🛑 Use the new, clean computed property from the Model
        correctAnswerLabel.text = "Correct answer: \(detail.correctOptionLetter)"
        
        // ... Visual Feedback code ...
        if detail.wasCorrect {
            self.contentView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        } else {
            self.contentView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        }
    }
}
