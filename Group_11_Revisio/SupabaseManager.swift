import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    // ⚠️ PASTE YOUR KEYS HERE
    private let projectURL = URL(string: "PASTE_YOUR_PROJECT_URL_HERE")!
    private let apiKey = "PASTE_YOUR_ANON_KEY_HERE"
    
    let client: SupabaseClient
    
    private init() {
        self.client = SupabaseClient(supabaseURL: projectURL, supabaseKey: apiKey)
    }
    
    // MARK: - 1. Auth
    func signInAnonymously() async {
        do {
            let _ = try await client.auth.session
            print("✅ Supabase: Session active.")
        } catch {
            print("👤 Supabase: Signing in anonymously...")
            do {
                _ = try await client.auth.signInAnonymously()
                print("✅ Supabase: Signed in!")
            } catch {
                print("❌ Supabase Auth Error: \(error)")
            }
        }
    }
    
    // MARK: - 2. Sync XP
    func syncXP(totalXP: Int) async {
        guard let userId = client.auth.currentUser?.id else { return }
        
        struct XPUpdate: Encodable { let total_xp: Int }
        
        do {
            try await client.from("profiles")
                .update(XPUpdate(total_xp: totalXP))
                .eq("id", value: userId)
                .execute()
            print("☁️ Supabase: XP synced.")
        } catch {
            print("❌ XP Sync Failed: \(error)")
        }
    }
    
    // MARK: - 3. Backup Topic
    func backupTopic(_ topic: Topic) async {
        guard let userId = client.auth.currentUser?.id else { return }
        
        struct TopicDTO: Encodable {
            let id: UUID
            let user_id: UUID
            let name: String
            let subject: String
            let type: String
            let content: Topic // Supabase handles JSONB
        }
        
        let dto = TopicDTO(
            id: topic.id,
            user_id: userId,
            name: topic.name,
            subject: topic.parentSubjectName,
            type: topic.materialType,
            content: topic
        )
        
        do {
            try await client.from("topics").upsert(dto).execute()
            print("☁️ Supabase: Topic backed up.")
        } catch {
            print("❌ Topic Backup Failed: \(error)")
        }
    }
}