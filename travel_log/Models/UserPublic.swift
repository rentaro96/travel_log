import Foundation
import FirebaseFirestore

struct UserPublic: Identifiable, Codable {
    @DocumentID var uid: String?   // ← docIdから入る
    var displayName: String?
    var friendCode: String
    var id: String { uid ?? UUID().uuidString }
}

