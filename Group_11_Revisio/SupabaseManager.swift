//
//  SupabaseManager.swift
//  Group_11_Revisio
//

import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    // ⚠️ PASTE YOUR KEYS HERE
    private let projectURL = URL(string: "https://mdtphliezfsqiqbgceen.supabase.co")!
    private let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kdHBobGllemZzcWlxYmdjZWVuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2MTgzMDUsImV4cCI6MjA4NjE5NDMwNX0.6BubgKX_aewynDg2IC1aNMYq_tYm9_Mhz8vNzY__ANc"
    
    let client: SupabaseClient
    
    private init() {
        self.client = SupabaseClient(supabaseURL: projectURL, supabaseKey: apiKey)
    }
    
    // MARK: - 1. Sync XP
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
    
    // MARK: - 2. Backup Topic
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
    
    
    // MARK: - 3. Fetch Messages for a Group
    func fetchMessages(for groupId: String) async throws -> [Message] {
        
        let response: [Message] = try await client
            .from("messages")
            .select()
            .eq("group_id", value: groupId)
            .order("created_at", ascending: true)
            .execute()
            .value
        
        return response
    }
    
    func sendMessage(
        groupId: String,
        senderId: String,
        text: String
    ) async throws {

        let message = Message(
            id: UUID().uuidString,
            groupId: groupId,
            senderId: senderId,
            content: text,
            createdAt: Date()
        )

        try await client
            .from("messages")
            .insert(message)
            .execute()
    }
}

// ✅ Global Supabase variable for easy access everywhere in the app
let supabase = SupabaseManager.shared.client
