//
//  SupabaseManager.swift
//  Group_11_Revisio
//

import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()

    private let projectURL = URL(string: "https://mdtphliezfsqiqbgceen.supabase.co")!
    private let apiKey     = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kdHBobGllemZzcWlxYmdjZWVuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2MTgzMDUsImV4cCI6MjA4NjE5NDMwNX0.6BubgKX_aewynDg2IC1aNMYq_tYm9_Mhz8vNzY__ANc"

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(supabaseURL: projectURL, supabaseKey: apiKey)
    }

    // MARK: - 1. Sync XP
    func syncXP(totalXP: Int) async {
        guard let userId = client.auth.currentUser?.id else { return }
        struct XPUpdate: Encodable { let total_xp: Int }
        do {
            try await client.from("profiles")
                .update(XPUpdate(total_xp: totalXP))
                .eq("id", value: userId).execute()
        } catch { print("❌ XP Sync Failed: \(error)") }
    }

    // Called by ProgressDataManager.recordXPEvent — syncs XP delta to Supabase
    func syncXPEvent(reason: String, amount: Int) async {
        guard let userId = client.auth.currentUser?.id else { return }
        struct XPUpdate: Encodable { let total_xp: Int }
        do {
            struct Row: Decodable { let total_xp: Int? }
            let rows: [Row] = try await client.from("profiles")
                .select("total_xp").eq("id", value: userId).limit(1).execute().value
            let current = rows.first?.total_xp ?? 0
            try await client.from("profiles")
                .update(XPUpdate(total_xp: current + amount))
                .eq("id", value: userId).execute()
        } catch { print("❌ syncXPEvent failed: \(error)") }
    }

    // MARK: - 2. Backup Topic
    func backupTopic(_ topic: Topic) async {
        guard let userId = client.auth.currentUser?.id else { return }
        struct TopicDTO: Encodable {
            let id: UUID; let user_id: UUID; let name: String
            let subject: String; let type: String; let content: Topic
        }
        let dto = TopicDTO(id: topic.id, user_id: userId, name: topic.name,
                           subject: topic.parentSubjectName, type: topic.materialType, content: topic)
        do { try await client.from("topics").upsert(dto).execute() }
        catch { print("❌ Topic Backup Failed: \(error)") }
    }

    // MARK: - 3. Fetch Messages
    func fetchMessages(for groupId: String) async throws -> [Message] {
        let response: [Message] = try await client
            .from("messages").select()
            .eq("group_id", value: groupId)
            .order("created_at", ascending: true)
            .execute().value
        return response
    }

    // MARK: - 4. Send plain text / link message
    func sendMessage(groupId: String, senderId: String, text: String) async throws {
        guard let gid = UUID(uuidString: groupId),
              let sid = UUID(uuidString: senderId) else { return }

        let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range   = NSRange(text.startIndex..., in: text)
        let matches = detector?.matches(in: text, options: [], range: range) ?? []

        if !matches.isEmpty {
            struct LinkInsert: Encodable {
                let group_id: UUID; let sender_id: UUID; let content: String
                let file_url: String; let file_name: String; let file_type: String
            }
            let urlString   = text.hasPrefix("http") ? text : "https://\(text)"
            let displayName = URL(string: urlString)?.host ?? text
            try await client.from("messages")
                .insert(LinkInsert(group_id: gid, sender_id: sid, content: text,
                                   file_url: urlString, file_name: displayName,
                                   file_type: "link"))
                .execute()
        } else {
            struct MessageInsert: Encodable {
                let group_id: UUID; let sender_id: UUID; let content: String
            }
            try await client.from("messages")
                .insert(MessageInsert(group_id: gid, sender_id: sid, content: text))
                .execute()
        }
    }

    // MARK: - 5. Send Attachment (study material or file from document/photo picker)
    // file_type: "document" | "image" | "link"
    // For Topics:   file_url = "revisio://material/<materialType>/<topicId>"
    // For Sources:  file_url = source.name (no actual URL stored locally)
    // For real uploads (photo/doc) the caller builds the insert directly after uploading to Storage
    func sendAttachment(groupId: String,
                        senderId: String,
                        attachment: SentAttachment) async throws {
        guard let gid = UUID(uuidString: groupId),
              let sid = UUID(uuidString: senderId) else { return }

        let fileUrl: String
        if let topic = attachment.topic {
            let encoded = topic.materialType
                .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? topic.materialType
            fileUrl = "revisio://material/\(encoded)/\(topic.id.uuidString)"
        } else {
            fileUrl = attachment.displayName
        }

        struct AttachInsert: Encodable {
            let group_id: UUID; let sender_id: UUID; let content: String
            let file_url: String; let file_name: String; let file_type: String
        }
        try await client.from("messages")
            .insert(AttachInsert(group_id: gid, sender_id: sid,
                                 content:   attachment.content,
                                 file_url:  fileUrl,
                                 file_name: attachment.displayName,
                                 file_type: attachment.fileType))
            .execute()
    }

    // MARK: - 6. Upload file to Supabase Storage
    // bucket: "group-media" for chat attachments, "group-avatars" for group photos
    func uploadFile(bucket: String,
                    path: String,
                    data: Data,
                    contentType: String) async throws -> String {
        try await client.storage
            .from(bucket)
            .upload(path, data: data,
                    options: FileOptions(contentType: contentType, upsert: true))
        let url = try client.storage.from(bucket).getPublicURL(path: path)
        return url.absoluteString
    }

    // MARK: - 7. Fetch Groups for current user
    func fetchGroups() async throws -> [Group] {
        guard let userId = client.auth.currentUser?.id else { return [] }
        struct MemberRow: Decodable {
            let group_id: UUID
            let study_groups: GroupRow
            struct GroupRow: Decodable {
                let id: UUID; let name: String; let avatar_url: String?
            }
        }
        let result: [MemberRow] = try await client
            .from("group_members")
            .select("group_id, study_groups(id, name, avatar_url)")
            .eq("user_id", value: userId)
            .execute().value
        return result.map {
            Group(id: $0.study_groups.id.uuidString,
                  name: $0.study_groups.name,
                  avatarUrl: $0.study_groups.avatar_url)
        }
    }

    // MARK: - 8. Create Group
    func createGroup(name: String, inviteCode: String) async throws -> Group {
        guard let userId = client.auth.currentUser?.id else {
            throw NSError(domain: "Auth", code: 401)
        }
        struct GroupInsert: Encodable {
            let name: String; let invite_code: String; let creator_id: UUID
        }
        struct GroupRow: Decodable { let id: UUID; let name: String }
        let inserted: [GroupRow] = try await client
            .from("study_groups")
            .insert(GroupInsert(name: name, invite_code: inviteCode, creator_id: userId))
            .select().execute().value
        guard let row = inserted.first else { throw NSError(domain: "Groups", code: 500) }
        struct MemberInsert: Encodable { let group_id: UUID; let user_id: UUID }
        try await client.from("group_members")
            .insert(MemberInsert(group_id: row.id, user_id: userId)).execute()
        return Group(id: row.id.uuidString, name: row.name, avatarUrl: nil)
    }

    // MARK: - 9. Join Group
    func joinGroup(code: String) async throws -> Group {
        guard let userId = client.auth.currentUser?.id else {
            throw NSError(domain: "Auth", code: 401)
        }
        struct GroupRow: Decodable { let id: UUID; let name: String; let avatar_url: String? }
        let groups: [GroupRow] = try await client
            .from("study_groups")
            .select("id, name, avatar_url")
            .eq("invite_code", value: code)
            .limit(1).execute().value
        guard let group = groups.first else {
            throw NSError(domain: "Groups", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid invite code"])
        }
        struct MemberInsert: Encodable { let group_id: UUID; let user_id: UUID }
        try await client.from("group_members")
            .upsert(MemberInsert(group_id: group.id, user_id: userId)).execute()
        return Group(id: group.id.uuidString, name: group.name, avatarUrl: group.avatar_url)
    }

    // MARK: - 10. Delete Group
    func deleteGroup(id: String) async throws {
        guard let uuid = UUID(uuidString: id) else { return }
        try await client.from("study_groups").delete().eq("id", value: uuid).execute()
    }

    // MARK: - 11. Update Group Name
    func updateGroup(id: String, newName: String) async throws {
        guard let uuid = UUID(uuidString: id) else { return }
        struct NameUpdate: Encodable { let name: String }
        try await client.from("study_groups")
            .update(NameUpdate(name: newName)).eq("id", value: uuid).execute()
    }

    // MARK: - 12. Update Group Avatar URL in DB
    func updateGroupAvatar(id: String, avatarUrl: String?) async throws {
        guard let uuid = UUID(uuidString: id) else { return }
        struct AvatarUpdate: Encodable { let avatar_url: String? }
        try await client.from("study_groups")
            .update(AvatarUpdate(avatar_url: avatarUrl)).eq("id", value: uuid).execute()
    }

    // MARK: - 13. Upload Group Avatar Image → Storage → returns public URL
    func uploadGroupAvatar(groupId: String, imageData: Data) async throws -> String {
        let path = "\(groupId)/avatar.jpg"
        return try await uploadFile(bucket: "group-avatars",
                                    path: path,
                                    data: imageData,
                                    contentType: "image/jpeg")
    }

    // MARK: - 14. Fetch Last Message preview
    func fetchLastMessage(for groupId: String) async -> String {
        guard let uuid = UUID(uuidString: groupId) else { return "No messages yet" }
        do {
            let result: [Message] = try await client
                .from("messages").select()
                .eq("group_id", value: uuid)
                .order("created_at", ascending: false)
                .limit(1).execute().value
            if let msg = result.first {
                if let fn = msg.fileName, !fn.isEmpty { return "📎 \(fn)" }
                return msg.content.isEmpty ? "No messages yet" : msg.content
            }
        } catch {}
        return "No messages yet"
    }

    // MARK: - 15. Fetch Members
    struct GroupMember {
        let userId: String
        let username: String
        let avatarUrl: String?
    }

    func fetchMembers(for groupId: String) async throws -> [GroupMember] {
        guard let uuid = UUID(uuidString: groupId) else { return [] }
        struct Row: Decodable {
            let user_id: UUID
            let profiles: ProfileRow
            struct ProfileRow: Decodable { let username: String?; let avatar_url: String? }
        }
        let result: [Row] = try await client
            .from("group_members")
            .select("user_id, profiles(username, avatar_url)")
            .eq("group_id", value: uuid).execute().value
        return result.map {
            GroupMember(userId: $0.user_id.uuidString,
                        username: $0.profiles.username ?? "User",
                        avatarUrl: $0.profiles.avatar_url)
        }
    }

    // MARK: - 16. Fetch Invite Code
    func fetchInviteCode(for groupId: String) async throws -> String {
        guard let uuid = UUID(uuidString: groupId) else { return "" }
        struct Row: Decodable { let invite_code: String }
        let result: [Row] = try await client
            .from("study_groups").select("invite_code")
            .eq("id", value: uuid).limit(1).execute().value
        return result.first?.invite_code ?? ""
    }

    // MARK: - 17. Fetch Group Files (docs/media/links for GroupSettings tabs)
    struct GroupFile {
        let fileUrl: String
        let fileName: String
        let fileType: String   // "image" | "document" | "link"
    }

    func fetchGroupFiles(for groupId: String) async throws -> [GroupFile] {
        guard let uuid = UUID(uuidString: groupId) else { return [] }
        struct Row: Decodable {
            let file_url: String?; let file_name: String?; let file_type: String?
        }
        // Use in() with the three known file types — avoids null-filter SDK inconsistencies
        let result: [Row] = try await client
            .from("messages")
            .select("file_url, file_name, file_type")
            .eq("group_id", value: uuid)
            .in("file_type", values: ["document", "image", "link"])
            .execute().value
        return result.compactMap {
            guard let url  = $0.file_url,
                  let name = $0.file_name,
                  let type = $0.file_type else { return nil }
            return GroupFile(fileUrl: url, fileName: name, fileType: type)
        }
    }
}

// ✅ Global shortcut used by Auth screens
let supabase = SupabaseManager.shared.client
