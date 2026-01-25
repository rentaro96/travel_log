//
//  UserStore.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/25.
//

import Foundation
internal import Combine
import FirebaseFirestore

@MainActor
final class UserStore: ObservableObject {

    @Published private(set) var friends: [UserPublic] = []
    @Published private(set) var friendLinks: [FriendLink] = []

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var uid: String?

    deinit { listener?.remove() }
    
    func updateDisplayName(myUid: String, displayName: String) async throws {
        try await db.collection("users")
            .document(myUid)
            .setData([
                "displayName": displayName,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
    }

    func bindUser(uid: String) {
        self.uid = uid

        // 既存listener解除
        listener?.remove()

        // users/{uid}/friends をリアルタイム監視
        listener = db.collection("users")
            .document(uid)
            .collection("friends")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    print("UserStore friends listen error:", error)
                    return
                }
                guard let snapshot else { return }

                let links: [FriendLink] = snapshot.documents.compactMap { doc in
                    do {
                        return try doc.data(as: FriendLink.self)
                    } catch {
                        print("❌ FriendLink decode failed docId=\(doc.documentID):", error)
                        print("📦 raw data:", doc.data())
                        return nil
                    }
                }

                self.friendLinks = links

                // friend uid 一覧を作る
                let friendUIDs = links.compactMap { $0.id }  // ✅ docIdを使う
                Task { await self.fetchFriendUsers(friendUIDs: friendUIDs) }

            }
    }

    private func fetchFriendUsers(friendUIDs: [String]) async {
        // 空ならクリア
        guard !friendUIDs.isEmpty else {
            self.friends = []
            return
        }

        do {
            var result: [UserPublic] = []

            // Firestore "in" は10個まで → 10件ずつ分割
            for chunk in friendUIDs.chunked(into: 10) {
                let snap = try await db.collection("users")
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()

                let users = snap.documents.compactMap { doc -> UserPublic? in
                    do { return try doc.data(as: UserPublic.self) }
                    catch {
                        print("❌ UserPublic decode failed docId=\(doc.documentID):", error)
                        print("📦 raw data:", doc.data())
                        return nil
                    }
                }

                result.append(contentsOf: users)
            }

            // friendLinksの順番に合わせて並び替え（表示が安定する）
            let map: [String: UserPublic] = Dictionary(
                uniqueKeysWithValues: result.compactMap { u -> (String, UserPublic)? in
                    // id が nil の時に備えて uid をキーに使う（確実にString）
                    return (u.uid, u)
                }
            )

            self.friends = friendUIDs.compactMap { map[$0] }


        } catch {
            print("❌ fetchFriendUsers error:", error)
        }
    }
}


// MARK: - helper
private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
