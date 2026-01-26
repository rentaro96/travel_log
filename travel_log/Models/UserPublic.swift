import Foundation
import FirebaseFirestore

struct UserPublic: Codable, Identifiable {
    @DocumentID var docId: String?
    let uid: String               // ✅ 必須
    let friendCode: String
    let displayName: String?
    let createdAt: Date?

    var id: String { uid }
}

