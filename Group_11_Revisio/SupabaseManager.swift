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

    // MARK: - 4. Send Message
    func sendMessage(groupId: String, senderId: String, text: String) async throws {
        struct MessageInsert: Encodable {
            let group_id: UUID
            let sender_id: UUID
            let content: String
        }
        guard let gid = UUID(uuidString: groupId),
              let sid = UUID(uuidString: senderId) else { return }

        try await client
            .from("messages")
            .insert(MessageInsert(group_id: gid, sender_id: sid, content: text))
            .execute()
    }

    // MARK: - 5. Fetch Groups for current user
    func fetchGroups() async throws -> [Group] {
        guard let userId = client.auth.currentUser?.id else { return [] }

        struct MemberRow: Decodable {
            let group_id: UUID
            let study_groups: GroupRow
            struct GroupRow: Decodable {
                let id: UUID
                let name: String
            }
        }

        let result: [MemberRow] = try await client
            .from("group_members")
            .select("group_id, study_groups(id, name)")
            .eq("user_id", value: userId)
            .execute()
            .value

        let avatars = ["gpfp1","gpfp2","gpfp3","gpfp4","gpfp5",
                       "gpfp6","gpfp7","gpfp8","gpfp9","gpfp10"]

        return result.enumerated().map { index, row in
            Group(
                id: row.study_groups.id.uuidString,
                name: row.study_groups.name,
                avatarName: avatars[index % avatars.count]
            )
        }
    }

    // MARK: - 6. Create Group
    func createGroup(name: String, avatarName: String, inviteCode: String) async throws -> Group {
        guard let userId = client.auth.currentUser?.id else {
            throw NSError(domain: "Auth", code: 401)
        }

        struct GroupInsert: Encodable {
            let name: String
            let invite_code: String
            let creator_id: UUID
        }

        struct GroupRow: Decodable {
            let id: UUID
            let name: String
        }

        let inserted: [GroupRow] = try await client
            .from("study_groups")
            .insert(GroupInsert(name: name, invite_code: inviteCode, creator_id: userId))
            .select()
            .execute()
            .value

        guard let row = inserted.first else {
            throw NSError(domain: "Groups", code: 500)
        }

        struct MemberInsert: Encodable {
            let group_id: UUID
            let user_id: UUID
        }
        try await client
            .from("group_members")
            .insert(MemberInsert(group_id: row.id, user_id: userId))
            .execute()

        return Group(id: row.id.uuidString, name: row.name, avatarName: avatarName)
    }

    // MARK: - 7. Join Group by invite code
    func joinGroup(code: String) async throws -> Group {
        guard let userId = client.auth.currentUser?.id else {
            throw NSError(domain: "Auth", code: 401)
        }

        struct GroupRow: Decodable {
            let id: UUID
            let name: String
        }

        let groups: [GroupRow] = try await client
            .from("study_groups")
            .select("id, name")
            .eq("invite_code", value: code)
            .limit(1)
            .execute()
            .value

        guard let group = groups.first else {
            throw NSError(domain: "Groups", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid invite code"])
        }

        struct MemberInsert: Encodable {
            let group_id: UUID
            let user_id: UUID
        }
        try await client
            .from("group_members")
            .upsert(MemberInsert(group_id: group.id, user_id: userId))
            .execute()

        return Group(id: group.id.uuidString, name: group.name, avatarName: "gpfp1")
    }

    // MARK: - 8. Delete Group
    func deleteGroup(id: String) async throws {
        guard let uuid = UUID(uuidString: id) else { return }
        try await client
            .from("study_groups")
            .delete()
            .eq("id", value: uuid)
            .execute()
    }

    // MARK: - 9. Update Group Name
    func updateGroup(id: String, newName: String) async throws {
        guard let uuid = UUID(uuidString: id) else { return }
        struct NameUpdate: Encodable { let name: String }
        try await client
            .from("study_groups")
            .update(NameUpdate(name: newName))
            .eq("id", value: uuid)
            .execute()
    }

    // MARK: - 10. Fetch Last Message for a Group
    func fetchLastMessage(for groupId: String) async -> String {
        guard let uuid = UUID(uuidString: groupId) else { return "No messages yet" }
        do {
            let result: [Message] = try await client
                .from("messages")
                .select()
                .eq("group_id", value: uuid)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value
            return result.first?.content ?? "No messages yet"
        } catch {
            return "No messages yet"
        }
    }
}

// ✅ Global Supabase variable for easy access everywhere in the app
let supabase = SupabaseManager.shared.client
