//
//  FriendRequestsViewModel.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2025/12/24.
//

import Foundation
internal import Combine
import FirebaseFirestore

struct FriendRequest: Identifiable {
    let id: String          // requestId = fromUid_toUid
    let fromUid: String
    let toUid: String
    let fromFriendCode: String?
}

@MainActor
final class FriendRequestsViewModel: ObservableObject {
    @Published var received: [FriendRequest] = []
    @Published var message: String = ""

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening(myUid: String) {
        stopListening()
        guard !myUid.isEmpty else { return }

        listener = db.collection("friend_requests")
            .whereField("toUid", isEqualTo: myUid)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error = error {
                    self.message = "受信取得失敗: \(error.localizedDescription)"
                    return
                }

                let docs = snapshot?.documents ?? []
                self.received = docs.compactMap { doc in
                    let data = doc.data()
                    let fromUid = data["fromUid"] as? String ?? ""
                    let toUid = data["toUid"] as? String ?? ""
                    let fromFriendCode = data["fromFriendCode"] as? String  // nilでもOK

                    return FriendRequest(
                        id: doc.documentID,
                        fromUid: fromUid,
                        toUid: toUid,
                        fromFriendCode: fromFriendCode
                    )
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func accept(request: FriendRequest, myUid: String) async {
        message = ""

        guard !myUid.isEmpty else { message = "ログインできてない"; return }
        guard request.toUid == myUid else { message = "宛先が違う"; return }

        do {
            let batch = db.batch()

            // friends サブコレクションに相互追加
            let myFriendRef = db.collection("users")
                .document(myUid)
                .collection("friends")
                .document(request.fromUid)

            let friendFriendRef = db.collection("users")
                .document(request.fromUid)
                .collection("friends")
                .document(myUid)

            batch.setData(["createdAt": FieldValue.serverTimestamp()], forDocument: myFriendRef)
            batch.setData(["createdAt": FieldValue.serverTimestamp()], forDocument: friendFriendRef)

            // 申請は削除（承認済み扱い）
            let requestRef = db.collection("friend_requests").document(request.id)
            batch.deleteDocument(requestRef)

            try await batch.commit()
            message = "承認した！"
        } catch {
            message = "承認失敗: \(error.localizedDescription)"
            print(error)
        }
    }

    func reject(request: FriendRequest, myUid: String) async {
        message = ""
        guard !myUid.isEmpty else { message = "ログインできてない"; return }
        guard request.toUid == myUid else { message = "宛先が違う"; return }

        do {
            try await db.collection("friend_requests").document(request.id).delete()
            message = "拒否した"
        } catch {
            message = "拒否失敗: \(error.localizedDescription)"
            print(error)
        }
    }
}
