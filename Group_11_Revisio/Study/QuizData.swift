//
//  QuizData.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 11/12/25.
//

//
//  QuizData.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 11/12/25.
//

import Foundation

// MARK: - 1. Structure Definitions

struct SourceTopic {
    let name: String
}

struct QuizQuestion {
    let questionText: String
    let answers: [String]
    let correctAnswerIndex: Int
    var userAnswerIndex: Int? = nil
    var isFlagged: Bool = false
    var hint: String
}

// MARK: - 2. Source Array

let allQuizSources: [SourceTopic] = [
    SourceTopic(name: "Taylor Series PDF"),
    SourceTopic(name: "Prof. Leonard Channel"),
    SourceTopic(name: "Derivative Rules Cheat"),
    SourceTopic(name: "Hadoop Docs"),
    SourceTopic(name: "Assembly Guide")
]

// MARK: - 3. Quiz Manager (Data and Fetching Logic)

struct QuizManager {
    
    // The main data source, keyed by Source Name
    static let quizDataBySource: [String: [QuizQuestion]] = [
        
        // --- SOURCE 1: Taylor Series PDF (3 Questions) ---
        "Taylor Series PDF": [
            QuizQuestion(
                questionText: "What is the formula for the Taylor Series expansion around a point 'a'?",
                answers: ["f(a) + f'(a)(x-a) + ...", "f'(a)(x-a) + f''(a)...", "Integral of f(x)dx", "Sum of power series"],
                correctAnswerIndex: 0,
                userAnswerIndex: nil, isFlagged: false, hint: "It involves the function's value and its derivatives at the center point 'a'."),
            QuizQuestion(
                questionText: "What is the Taylor Series expansion for e^x centered at 0 (Maclaurin Series)?",
                answers: ["Sum of x^n/n!", "Sum of x^n", "1 + x^2/2!", "1 - x^2/2!"],
                correctAnswerIndex: 0,
                userAnswerIndex: nil, isFlagged: false, hint: "Remember the derivative of e^x is e^x."),
            QuizQuestion(
                questionText: "The Taylor Series can be used to approximate which types of functions?",
                answers: ["Differentiable functions", "Only polynomials", "Discontinuous functions", "All functions"],
                correctAnswerIndex: 0,
                userAnswerIndex: nil, isFlagged: false, hint: "The formula fundamentally requires derivatives to exist."),
        ],
        
        // --- SOURCE 2: Prof. Leonard Channel (3 Questions) ---
        "Prof. Leonard Channel": [
            QuizQuestion(
                questionText: "If Prof. Leonard discusses L'Hôpital's Rule, what kind of indeterminate form must the limit have?",
                answers: ["0/0 or ∞/∞", "1/0 or 0*∞", "∞-∞ or 1^∞", "Any indeterminate form"],
                correctAnswerIndex: 0,
                userAnswerIndex: nil, isFlagged: false, hint: "The rule applies only to specific fractional forms of limits."),
            QuizQuestion(
                questionText: "What method is used to integrate functions that are products of polynomials and exponentials?",
                answers: ["U-Substitution", "Partial Fractions", "Integration by Parts", "Trigonometric Substitution"],
                correctAnswerIndex: 2,
                userAnswerIndex: nil, isFlagged: false, hint: "The LIATE rule often helps select 'u' in this technique."),
            QuizQuestion(
                questionText: "A sequence that approaches a finite number is said to be...",
                answers: ["Divergent", "Convergent", "Oscillating", "Undefined"],
                correctAnswerIndex: 1,
                userAnswerIndex: nil, isFlagged: false, hint: "Think of an ending point or final value."),
        ],

        // --- SOURCE 3: Derivative Rules Cheat (3 Questions) ---
        "Derivative Rules Cheat": [
            QuizQuestion(
                questionText: "The derivative of a constant (e.g., f(x) = 5) is always:",
                answers: ["1", "5", "0", "x"],
                correctAnswerIndex: 2,
                userAnswerIndex: nil, isFlagged: false, hint: "A constant has no rate of change."),
            QuizQuestion(
                questionText: "Which rule is used to differentiate a quotient of two functions, f(x)/g(x)?",
                answers: ["Product Rule", "Chain Rule", "Quotient Rule", "Power Rule"],
                correctAnswerIndex: 2,
                userAnswerIndex: nil, isFlagged: false, hint: "Remember 'low d high minus high d low...'"),
            QuizQuestion(
                questionText: "The derivative of sin(x) is:",
                answers: ["cos(x)", "-sin(x)", "tan(x)", "-cos(x)"],
                correctAnswerIndex: 0,
                userAnswerIndex: nil, isFlagged: false, hint: "Its derivative retains the positive co-function."),
        ],
        
        // --- SOURCE 4: Hadoop Docs (3 Questions) ---
        "Hadoop Docs": [
            QuizQuestion(
                questionText: "What is the primary function of HDFS?",
                answers: ["Data processing", "Data storage", "Cluster monitoring", "Job scheduling"],
                correctAnswerIndex: 1,
                userAnswerIndex: nil, isFlagged: false, hint: "Hadoop is known for large-scale distributed storage."),
            QuizQuestion(
                questionText: "Which component of Hadoop is responsible for resource management?",
                answers: ["MapReduce", "HDFS", "YARN", "Hive"],
                correctAnswerIndex: 2,
                userAnswerIndex: nil, isFlagged: false, hint: "Think of the operating system of the Hadoop cluster."),
            QuizQuestion(
                questionText: "What is the default replication factor for data blocks in HDFS?",
                answers: ["1", "2", "3", "4"],
                correctAnswerIndex: 2,
                userAnswerIndex: nil, isFlagged: false, hint: "This factor determines data fault tolerance."),
        ],

        // --- SOURCE 5: Assembly Guide (3 Questions) ---
        "Assembly Guide": [
            QuizQuestion(
                questionText: "The assembly instruction 'MOV AX, 5' performs which operation?",
                answers: ["Compares AX to 5", "Moves value 5 into register AX", "Increments AX by 5", "Jumps to address 5"],
                correctAnswerIndex: 1,
                userAnswerIndex: nil, isFlagged: false, hint: "The mnemonic stands for 'Move'."),
            QuizQuestion(
                questionText: "What does the instruction 'JMP LABEL' do?",
                answers: ["Conditional jump", "Unconditional jump", "Loop execution", "Function call"],
                correctAnswerIndex: 1,
                userAnswerIndex: nil, isFlagged: false, hint: "It changes the program counter directly without checking a flag."),
            QuizQuestion(
                questionText: "Assembly language is considered a type of:",
                answers: ["High-level language", "Intermediate language", "Low-level language", "Interpreted language"],
                correctAnswerIndex: 2,
                userAnswerIndex: nil, isFlagged: false, hint: "It corresponds directly to machine code."),
        ],
    ]
    
    
    static func getQuestions(for sourceName: String) -> [QuizQuestion] {
        return quizDataBySource[sourceName] ?? []
    }
}
