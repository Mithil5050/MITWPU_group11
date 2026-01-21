//
//  CategoryModel.swift
//  Group_11_Revisio
//
//  Created by Mithil on 15/12/25.
//


// GameModels.swift

import UIKit

// MARK: - 1. Category Data
struct CategoryModel {
    let id: Int
    let title: String
    let words: [String]
    let color: UIColor

    static let allCategories: [CategoryModel] = [
        CategoryModel(
            id: 0,
            title: "DATA STRUCTURES",
            words: ["Stack", "Queue", "Tree", "Array"],
            color: .systemPurple
        ),
        CategoryModel(
            id: 1,
            title: "SORTING ALGORITHMS",
            words: ["Bubble", "Merge", "Heap", "Quick"],
            color: .systemGreen
        ),
        CategoryModel(
            id: 2,
            title: "ARITHMETIC APTITUDE",
            words: ["Ratio", "Average", "Profit", "Loss"],
            color: .systemYellow
        ),
        CategoryModel(
            id: 3,
            title: "TERMS IN DBMS",
            words: ["Field", "Schema", "Record", "Table"],
            color: .systemBlue
        )
    ]
}

// MARK: - 2. Word Data
struct WordModel {
    let text: String
    let categoryID: Int
    var isSelected: Bool = false
    var isGuessed: Bool = false

    init(text: String, categoryID: Int) {
        self.text = text
        self.categoryID = categoryID
    }

    static func generateInitialWords() -> [WordModel] {
        var allWords: [WordModel] = []
        for category in CategoryModel.allCategories {
            for word in category.words {
                allWords.append(WordModel(text: word, categoryID: category.id))
            }
        }
        return allWords.shuffled()
    }
}
