//
//  FriendViewModel.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2025/12/24.
//

import Foundation
internal import Combine
import FirebaseFirestore

@MainActor
final class FriendViewModel: ObservableObject {
    @Published var message: String = ""
    private let db = Firestore.firestore()

    func sendFriendRequest(myUid: String, myFriendCode: String, friendCode: String) async {
        message = ""

        let code = friendCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !myUid.isEmpty else { message = "ログインできてない"; return }
        guard !myFriendCode.isEmpty else { message = "自分のID生成中…"; return }
        guard code.count >= 6 else { message = "IDが短い"; return }

        do {
            let query = try await db.collection("users")
                .whereField("friendCode", isEqualTo: code)
                .getDocuments()

            guard let doc = query.documents.first else {
                message = "そのIDのユーザーが見つからない"
                return
            }

            let toUid = doc.documentID
            if toUid == myUid { message = "自分には送れない"; return }

            let requestId = "\(myUid)_\(toUid)"
            let data: [String: Any] = [
                "fromUid": myUid,
                "fromFriendCode": myFriendCode, // ← 追加
                "toUid": toUid,
                "status": "pending",
                "createdAt": FieldValue.serverTimestamp()
            ]

            try await db.collection("friend_requests")
                .document(requestId)
                .setData(data)

            message = "申請を送った！"
        } catch {
            message = "送信失敗: \(error.localizedDescription)"
            print(error)
        }
    }
}
