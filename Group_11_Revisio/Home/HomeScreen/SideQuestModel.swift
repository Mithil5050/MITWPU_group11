import UIKit

struct SideQuest: Codable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
    var isExpired: Bool = false
    var dateCreated: Date = Date()
}
