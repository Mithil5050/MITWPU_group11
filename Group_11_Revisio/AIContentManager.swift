import Foundation
import Supabase

class AIContentManager {
    static let shared = AIContentManager()
    
    private init() {}
    
    // 1. Define the structure for the data we SEND
    struct AIRequest: Encodable {
        let topic: String
        let type: String
        let count: Int
        let difficulty: String
    }
    
    // 2. Define the structure for the data we RECEIVE
    struct AIResponse: Decodable {
        let content: String
    }
    
    func generateContent(topic: String, type: String, count: Int, difficulty: String) async throws -> String {
        
        let requestBody = AIRequest(
            topic: topic,
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
            // 👇 THIS IS THE NEW PART: Decodes the hidden "59 byte" error
            if let functionsError = error as? FunctionsError {
                switch functionsError {
                case .httpError(let code, let data):
                    // Convert the raw data into readable text
                    let secretMessage = String(data: data, encoding: .utf8) ?? "Could not decode error"
                    print("\n🔴 SERVER CRASH REASON (Code \(code)): \(secretMessage)\n")
                    
                    // Throw a readable error so the UI can show it
                    throw NSError(domain: "Supabase", code: code, userInfo: [NSLocalizedDescriptionKey: secretMessage])
                    
                case .relayError:
                    print("🔴 Relay Error: \(error)")
                }
            }
            
            print("❌ AI Edge Function Error: \(error)")
            throw error
        }
    }
}
