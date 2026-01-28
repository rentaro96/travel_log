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
    @Published var blockedUsers: [UserPublic] = []

    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var uid: String?
    
    private var blockedListener: ListenerRegistration?

    deinit {
        listener?.remove()
        blockedListener?.remove()
    }

    func bindBlockedUsers(myUid: String) {
        blockedListener?.remove()

        let ref = db.collection("users").document(myUid).collection("blocked")
        blockedListener = ref.addSnapshotListener { [weak self] snap, err in
            if let err = err {
                print("❌ bindBlockedUsers error:", err)
                return
            }
            let ids = snap?.documents.map { $0.documentID } ?? []
            Task { [weak self] in
                await self?.fetchBlockedUsers(blockedUids: ids)
            }
        }
    }


    func fetchBlockedUsers(blockedUids: [String]) async {
        print("✅ fetchBlockedUsers called blockedUids =", blockedUids)

        guard !blockedUids.isEmpty else {
            blockedUsers = []
            return
        }

        do {
            var results: [UserPublic] = []

            for chunk in blockedUids.chunked(into: 10) {
                print("🔎 querying users docID in:", chunk)

                let snap = try await db.collection("users")
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()

                print("📄 snap.count =", snap.documents.count)
                print("📄 docIDs =", snap.documents.map { $0.documentID })

                let users: [UserPublic] = snap.documents.compactMap { doc in
                    do {
                        return try doc.data(as: UserPublic.self) // uidは@DocumentIDで入る
                    } catch {
                        print("❌ decode failed docId=\(doc.documentID):", error)
                        print("📦 raw data:", doc.data())
                        return nil
                    }
                }

                results.append(contentsOf: users)
            }

            let map: [String: UserPublic] = Dictionary(
                uniqueKeysWithValues: results.compactMap { u -> (String, UserPublic)? in
                    guard let uid = u.uid else { return nil }
                    return (uid, u)
                }
            )

            blockedUsers = blockedUids.compactMap { map[$0] }
            print("✅ blockedUsers.count =", blockedUsers.count)

        } catch {
            print("❌ fetchBlockedUsers error:", error)
        }
    }





    


    
    func blockUser(myUid: String, targetUid: String) async throws {
        guard !myUid.isEmpty, !targetUid.isEmpty else { return }
        guard myUid != targetUid else { return }
        
        let myBlockedRef = db.collection("users").document(myUid)
            .collection("blocked").document(targetUid)
        
        let targetBlockedMeRef = db.collection("users").document(targetUid)
            .collection("blockedBy").document(myUid) // 任意（管理用）
        
        // フレンド相互解除（あなたのフレンド構造に合わせてパス調整）
        let myFriendRef = db.collection("users").document(myUid)
            .collection("friends").document(targetUid)
        
        let targetFriendRef = db.collection("users").document(targetUid)
            .collection("friends").document(myUid)
        
        let batch = db.batch()
        
        // ブロック登録
        batch.setData([
            "createdAt": FieldValue.serverTimestamp()
        ], forDocument: myBlockedRef, merge: true)
        
        // 任意：相手側に「ブロックされた記録」を残す（なくてもOK）
        batch.setData([
            "createdAt": FieldValue.serverTimestamp()
        ], forDocument: targetBlockedMeRef, merge: true)
        
        // 相互フレンド解除
        batch.deleteDocument(myFriendRef)
        batch.deleteDocument(targetFriendRef)
        
        try await batch.commit()
    }

    
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
    
    func submitReport(
        reporterUid: String,
        targetUid: String,
        targetFriendCode: String?,
        reason: ReportReason,
        detail: String?
    ) async throws {
        guard !reporterUid.isEmpty, !targetUid.isEmpty else { return }

        var data: [String: Any] = [
            "reporterUid": reporterUid,
            "targetUid": targetUid,
            "reason": reason.rawValue,
            "createdAt": FieldValue.serverTimestamp()
        ]

        if let targetFriendCode { data["targetFriendCode"] = targetFriendCode }
        if let detail, !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            data["detail"] = detail
        }

        try await db.collection("reports").addDocument(data: data)
    }

    
    func removeFriend(myUid: String, friendUid: String) async throws {
            guard !myUid.isEmpty, !friendUid.isEmpty else { return }

            // 自分側: users/{myUid}/friends/{friendUid}
            let myFriendRef = db.collection("users")
                .document(myUid)
                .collection("friends")
                .document(friendUid)

            // 相手側: users/{friendUid}/friends/{myUid}
            let theirFriendRef = db.collection("users")
                .document(friendUid)
                .collection("friends")
                .document(myUid)

            // ✅ 2つ同時に削除（片方失敗したらエラーで分かる）
            async let a: Void = myFriendRef.delete()
            async let b: Void = theirFriendRef.delete()
            _ = try await (a, b)

            // UI上でも即消す（listenerがあるなら後で同期されるけど体感が良い）
            friends.removeAll { $0.uid == friendUid }
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
                uniqueKeysWithValues: result.compactMap { u in
                    guard let uid = u.uid else { return nil }
                    return (uid, u)
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
        var res: [[Element]] = []
        var i = 0
        while i < count {
            res.append(Array(self[i..<Swift.min(i + size, count)]))
            i += size
        }
        return res
    }
}

