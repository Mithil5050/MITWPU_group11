import Foundation
import Supabase

class AIContentManager {
    static let shared = AIContentManager()
    
    private init() {}
    
    struct AIRequest: Encodable {
        let topic: String
        let type: String
        let count: Int
        let difficulty: String
    }
    
    struct AIResponse: Decodable {
        let content: String
    }
    
    func generateContent(topic: String, type: String, count: Int, difficulty: String) async throws -> String {
        let noteInstructions = "Format: Comprehensive Academic Notes. Use # for Title, ## for main topics, and bullet points. START IMMEDIATELY with \(topic)."
        
        let cheatsheetInstructions = "Format: Online Cheatsheet. Use ## for sections and a Markdown table for definitions. START IMMEDIATELY with \(topic)."
        
        let selectedInstructions = (type.lowercased() == "notes") ? noteInstructions : cheatsheetInstructions
        
        let trainedPrompt = """
        ACTUAL TOPIC TO WRITE ABOUT: \(topic)
        
        INSTRUCTIONS:
        \(selectedInstructions)
        NEVER mention "Note Taker" or "AI instructions" in the output. 
        Only output study material for \(topic).
        """
        
        let requestBody = AIRequest(
            topic: trainedPrompt,
            type: type,
            count: count,
            difficulty: difficulty
        )
        
        do {
            let response: AIResponse = try await SupabaseManager.shared.client.functions
                .invoke(
                    "generate-study-material",
                    options: FunctionInvokeOptions(
                        body: requestBody
                    )
                )
            
            return response.content
            
        } catch {
            if let functionsError = error as? FunctionsError {
                switch functionsError {
                case .httpError(let code, let data):
                    let secretMessage = String(data: data, encoding: .utf8) ?? "Could not decode error"
                    print("\n🔴 SERVER CRASH REASON (Code \(code)): \(secretMessage)\n")
                    throw NSError(domain: "Supabase", code: code, userInfo: [NSLocalizedDescriptionKey: secretMessage])
                    
                case .relayError:
                    print("🔴 Relay Error: \(error)")
                }
            }
            
            print("❌ AI Edge Function Error: \(error)")
            throw error
        }
    }
    
    // Process Vision Framework labels specifically without forcing "Notes" or "Cheatsheets" format
    func processVisionLabels(words: [String]) async throws -> [String] {
        let list = words.joined(separator: ", ")
        let prompt = """
        I extracted these words from a diagram using OCR: [\(list)].
        Filter out diagram titles (like 'Plant Cell Anatomy'), user instructions, watermarks, or random stray letters.
        Return ONLY a raw comma-separated list of the actual scientific diagram anatomical parts/labels.
        Do NOT output tables, markdown, or any other explanations. Just the raw comma-separated labels.
        """
        
        let requestBody = AIRequest(
            topic: prompt,
            type: "Filter",
            count: 1,
            difficulty: "Normal"
        )
        
        let response: AIResponse = try await SupabaseManager.shared.client.functions
            .invoke("generate-study-material", options: FunctionInvokeOptions(body: requestBody))
            
        return response.content.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
