import Foundation
import Supabase

class AIContentManager {
    static let shared = AIContentManager()
    
    private init() {}
    
    struct AIResponse: Decodable {
        let content: String
    }
    
    func generateContent(topic: String, type: String, count: Int, difficulty: String) async throws -> String {
        
        let parameters: [String: Any] = [
            "topic": topic,
            "type": type,
            "count": count,
            "difficulty": difficulty
        ]
        
        do {
            // This name MUST match the function you are deploying in Terminal right now
            let response: AIResponse = try await SupabaseManager.shared.client.functions
                .invoke(
                    "generate-study-material",
                    options: FunctionInvokeOptions(
                        body: parameters
                    )
                )
            
            return response.content
            
        } catch {
            print("❌ AI Edge Function Error: \(error)")
            throw error
        }
    }
}