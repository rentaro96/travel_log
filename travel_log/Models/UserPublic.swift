//
//  UserPublic.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/25.
//

import Foundation
import FirebaseFirestore

struct UserPublic: Codable, Identifiable {
    @DocumentID var id: String?   // = uid
    let uid: String
    let friendCode: String
    let createdAt: Date?
    
    // 例：表示名を持ってるなら追加
    // let displayName: String?
}

