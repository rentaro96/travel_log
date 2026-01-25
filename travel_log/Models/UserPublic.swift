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
    let createdAt: Date?

    // uidはdocIdから作る
    var uid: String { id ?? "" }
}


