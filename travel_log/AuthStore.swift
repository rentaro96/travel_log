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
            print("匿名ログイン失敗:", error)
        }
    }

    private func createUserIfNeeded() async {
        guard !uid.isEmpty else { return }

        let ref = db.collection("users").document(uid)
        let snapshot = try? await ref.getDocument()

        if snapshot?.exists == true {
            friendCode = snapshot?.data()?["friendCode"] as? String ?? ""
            return
        }

        let code = generateFriendCode()
        friendCode = code

        let data: [String: Any] = [
            "friendCode": code,
            "createdAt": FieldValue.serverTimestamp()
        ]
        try? await ref.setData(data)
    }

    private func generateFriendCode(length: Int = 6) -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<length).compactMap { _ in chars.randomElement() })
    }
}

