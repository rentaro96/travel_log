//
//  UserPublic.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/25.
//

import Foundation
import FirebaseFirestore

struct UserPublic: Codable, Identifiable {
    @DocumentID var id: String?      // = uid
    let friendCode: String
        let displayName: String?     // ✅ これが「ユーザーが設定する名前」
        let createdAt: Date?

        var uid: String { id ?? "" }
}


