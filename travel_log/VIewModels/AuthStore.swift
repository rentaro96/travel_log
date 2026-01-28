//
//  AuthStore.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2025/12/24.
//

import Foundation
internal import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AuthStore: ObservableObject {
    @Published var uid: String = ""
    @Published var friendCode: String = ""
    @Published var status: String = "未ログイン"

    private let db = Firestore.firestore()

    func signInIfNeeded() async {
        print("✅ signInIfNeeded called")
        print("Auth current uid =", Auth.auth().currentUser?.uid ?? "nil")
        print("authStore.uid     =", uid)

        status = "ログイン確認中…"

        if let current = Auth.auth().currentUser {
            uid = current.uid
            await createUserIfNeeded()
            status = "ログイン済み"
            return
        }

        status = "匿名ログイン中…"
        do {
            let result = try await Auth.auth().signInAnonymously()
            uid = result.user.uid
            await createUserIfNeeded()
            status = "匿名ログイン成功"
        } catch {
            status = "ログイン失敗: \(error.localizedDescription)"
            print("❌ 匿名ログイン失敗:", error)
        }
    }

    private func createUserIfNeeded() async {
        guard !uid.isEmpty else { return }

        let ref = db.collection("users").document(uid)

        do {
            let snapshot = try await ref.getDocument()

            // ===== 既存ユーザー =====
            if snapshot.exists {
                let data = snapshot.data() ?? [:]

                if let code = data["friendCode"] as? String, !code.isEmpty {
                    friendCode = code
                }

                // ✅ users_public を同期（docId = uid）
                try await db.collection("users_public")
                    .document(uid)
                    .setData([
                        "uid": uid,
                        "friendCode": friendCode,
                        "displayName": data["displayName"] as? String ?? friendCode,
                        "updatedAt": FieldValue.serverTimestamp()
                    ], merge: true)

                return
            }

            // ===== 新規ユーザー =====
            let code = generateFriendCode(length: 6)
            friendCode = code
            let initialDisplayName = code

            let data: [String: Any] = [
                "friendCode": code,
                "displayName": initialDisplayName,
                "createdAt": FieldValue.serverTimestamp()
            ]

            try await ref.setData(data, merge: true)

            // ✅ 公開プロフィール作成
            try await db.collection("users_public")
                .document(uid)
                .setData([
                    "uid": uid,
                    "friendCode": code,
                    "displayName": initialDisplayName,
                    "createdAt": FieldValue.serverTimestamp()
                ], merge: true)

            print("✅ users & users_public created for uid =", uid)

        } catch {
            status = "Firestore失敗: \(error.localizedDescription)"
            print("❌ Firestore create/read 失敗:", error)
        }
    }

    // ✅ サブコレ方式でブロック
    func block(uid targetUid: String) async throws {
        guard !uid.isEmpty, !targetUid.isEmpty, uid != targetUid else { return }

        let ref = db.collection("users")
            .document(uid)
            .collection("blocked")
            .document(targetUid)

        try await ref.setData([
            "createdAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

    // ✅ サブコレ方式で解除
    func unblock(uid targetUid: String) async throws {
        guard !uid.isEmpty, !targetUid.isEmpty, uid != targetUid else { return }

        let ref = db.collection("users")
            .document(uid)
            .collection("blocked")
            .document(targetUid)

        try await ref.delete()
    }

    private func generateFriendCode(length: Int = 6) -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<length).compactMap { _ in chars.randomElement() })
    }
}
