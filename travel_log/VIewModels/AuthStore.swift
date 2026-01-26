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
    @Published var blockedUids: Set<String> = []


    private let db = Firestore.firestore()

    func signInIfNeeded() async {
        print("✅ signInIfNeeded called")
        status = "ログイン確認中…"

        // ✅ 既にログインしてるなら、その uid を使う（再ログインしない）
        if let current = Auth.auth().currentUser {
            uid = current.uid
            await createUserIfNeeded()
            status = "ログイン済み"
            return
        }

        // ✅ いない時だけ匿名ログイン
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

    // 機能は同じ（users/{uid} があれば friendCode 取得、なければ作成）
    private func createUserIfNeeded() async {
        guard !uid.isEmpty else { return }

        let ref = db.collection("users").document(uid)

        do {
            let snapshot = try await ref.getDocument()

            // ✅ 既に users/{uid} がある → friendCode を読む（固定）
            if snapshot.exists {
                let data = snapshot.data() ?? [:]

                if let code = data["friendCode"] as? String, !code.isEmpty {
                    friendCode = code
                }

                // ✅ blockedUids 読み込み
                if let arr = data["blockedUids"] as? [String] {
                    blockedUids = Set(arr)
                } else {
                    blockedUids = []
                }

                return
            }


            // ✅ 無ければ生成して保存（1回だけ）
            let code = generateFriendCode(length: 6)
            friendCode = code
            
            let initialDisplayName = code

            let data: [String: Any] = [
                "friendCode": code,
                "displayName": initialDisplayName,
                "blockedUids": [],
                "createdAt": FieldValue.serverTimestamp()
                
            ]

            try await ref.setData(data, merge: true) // merge true の方が安全
            print("✅ users/\(uid) を作成しました friendCode=\(code) displayName=\(initialDisplayName)")

        } catch {
            // ✅ ここが見えるようになるのが重要（ルール弾き/設定ミスが分かる）
            status = "Firestore失敗: \(error.localizedDescription)"
            print("❌ Firestore create/read 失敗:", error)
        }
    }
    
    func block(uid targetUid: String) async throws {
        guard !uid.isEmpty else { return }
        let ref = db.collection("users").document(uid)
        try await ref.setData([
            "blockedUids": FieldValue.arrayUnion([targetUid]),
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)

        blockedUids.insert(targetUid)
    }

    func unblock(uid targetUid: String) async throws {
        guard !uid.isEmpty else { return }
        let ref = db.collection("users").document(uid)
        try await ref.setData([
            "blockedUids": FieldValue.arrayRemove([targetUid]),
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)

        blockedUids.remove(targetUid)
    }

    func isBlocked(_ otherUid: String) -> Bool {
        blockedUids.contains(otherUid)
    }


    private func generateFriendCode(length: Int = 6) -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789") // 0/O,1/I除外
        return String((0..<length).compactMap { _ in chars.randomElement() })
    }
}
