//
//  FriendLink.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/25.
//

import Foundation
import FirebaseFirestore

struct FriendLink: Codable, Identifiable {
    @DocumentID var id: String?     // ← friendsのdocIdが入る（= friend uid）
    let createdAt: Date?
    
    // uid フィールドは不要にする
    var uid: String { id ?? "" }
}


