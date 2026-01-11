//
//  APIService.swift
//  MITWPU_group11
//
//  Uses Gemini 1.0 Pro (Stable & Available)
//

import Foundation

// MARK: - Gemini Response Models
private struct GeminiResponse: Codable {
    struct Candidate: Codable {
        struct Content: Codable {
            struct Part: Codable {
                let text: String
            }
            let parts: [Part]
        }
        let content: Content
    }
    let candidates: [Candidate]?
    let error: GeminiError?
}

private struct GeminiError: Codable {
    let code: Int
    let message: String
    let status: String
}

// MARK: - AI Models
private struct AIQuizItem: Codable {
    let questionText: String
    let answers: [String]
    let correctAnswerIndex: Int
    let hint: String
}

private struct AIFlashcardItem: Codable {
    let term: String
    let definition: String
}

// MARK: - API Service
final class APIService {

    static let shared = APIService()
    private init() {}

    // 🔐 MOVE THIS TO Info.plist FOR PRODUCTION
    private let apiKey = "AIzaSyA9xUtdi321b8KorADyxtZv_eFFZwiWCOQ"

    // MARK: - Gemini Request
    private func performGeminiRequest(
        prompt: String,
        completion: @escaping (String?) -> Void
    ) {

        let urlString =
        "https://generativelanguage.googleapis.com/v1/models/gemini-1.0-pro:generateContent?key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in

            if let error {
                print("❌ Network Error:", error.localizedDescription)
                completion(nil)
                return
            }

            guard let data else {
                completion(nil)
                return
            }

            do {
                let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)

                if let apiError = decoded.error {
                    print("❌ Gemini API Error:", apiError.message)
                    completion(nil)
                    return
                }

                let text = decoded.candidates?
                    .first?
                    .content
                    .parts
                    .first?
                    .text

                completion(text)

            } catch {
                print("❌ Decoding Error:", error)
                print(String(data: data, encoding: .utf8) ?? "")
                completion(nil)
            }

        }.resume()
    }

    // MARK: - JSON Cleaner
    private func cleanJSONString(_ string: String) -> Data? {
        var cleaned = string.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
        return cleaned.data(using: .utf8)
    }

    // MARK: - Quiz Generator
    func generateQuiz(
        for topic: String,
        completion: @escaping ([QuizQuestion]?) -> Void
    ) {

        let prompt = """
        Create 5 multiple choice questions about "\(topic)".

        Return ONLY raw JSON:
        {
          "questions": [
            {
              "questionText": "",
              "answers": ["A","B","C","D"],
              "correctAnswerIndex": 0,
              "hint": ""
            }
          ]
        }
        """

        performGeminiRequest(prompt: prompt) { response in
            guard let response,
                  let data = self.cleanJSONString(response) else {
                completion(nil)
                return
            }

            do {
                struct Wrapper: Codable {
                    let questions: [AIQuizItem]
                }

                let decoded = try JSONDecoder().decode(Wrapper.self, from: data)

                let questions = decoded.questions.map {
                    QuizQuestion(
                        questionText: $0.questionText,
                        answers: $0.answers,
                        correctAnswerIndex: $0.correctAnswerIndex,
                        userAnswerIndex: nil,
                        isFlagged: false,
                        hint: $0.hint
                    )
                }

                completion(questions)

            } catch {
                print("❌ Quiz Parsing Error:", error)
                completion(nil)
            }
        }
    }

    // MARK: - Flashcard Generator
    func generateFlashcards(
        for topic: String,
        completion: @escaping ([Flashcard]?) -> Void
    ) {

        let prompt = """
        Create 5 flashcards about "\(topic)".

        Return ONLY raw JSON:
        {
          "cards": [
            { "term": "", "definition": "" }
          ]
        }
        """

        performGeminiRequest(prompt: prompt) { response in
            guard let response,
                  let data = self.cleanJSONString(response) else {
                completion(nil)
                return
            }

            do {
                struct Wrapper: Codable {
                    let cards: [AIFlashcardItem]
                }

                let decoded = try JSONDecoder().decode(Wrapper.self, from: data)

                let cards = decoded.cards.map {
                    Flashcard(term: $0.term, definition: $0.definition)
                }

                completion(cards)

            } catch {
                print("❌ Flashcard Parsing Error:", error)
                completion(nil)
            }
        }
    }
}
