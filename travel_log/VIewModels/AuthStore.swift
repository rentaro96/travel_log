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
    @Published var isBanned: Bool = false
    @Published var banReason: String = ""

    private let db = Firestore.firestore()

    func signInIfNeeded() async {
        print("✅ signInIfNeeded called")
        print("Auth current uid =", Auth.auth().currentUser?.uid ?? "nil")
        print("authStore.uid     =", uid)

        status = "ログイン確認中…"
        isBanned = false
        banReason = ""
        
        // ✅ 端末BAN中ならログイン処理を止める（新規アカ作成を防ぐ）
        if deviceBanned {
            isBanned = true
            banReason = deviceBanReason
            status = "この端末は利用停止中です"

            // ✅ BAN画面用に friendCode も復元
            friendCode = deviceBanFriendCode

            return
        }

        if let current = Auth.auth().currentUser {
            uid = current.uid

            // ✅ BANチェック（最優先）
            if await checkAndHandleBanIfNeeded() { return }

            await createUserIfNeeded()
            status = "ログイン済み"
            return
        }

        status = "匿名ログイン中…"
        do {
            let result = try await Auth.auth().signInAnonymously()
            uid = result.user.uid

            // ✅ BANチェック（最優先）
            if await checkAndHandleBanIfNeeded() { return }

            await createUserIfNeeded()
            status = "匿名ログイン成功"
        } catch {
            status = "ログイン失敗: \(error.localizedDescription)"
            print("❌ 匿名ログイン失敗:", error)
        }
    }

    private func createUserIfNeeded() async {
        guard !uid.isEmpty else { return }
        guard !isBanned else { return }

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
    
    // ✅ サブコレ方式でBAN（自分の画面から非表示）
    func ban(uid targetUid: String) async throws {
        guard !uid.isEmpty, !targetUid.isEmpty, uid != targetUid else { return }

        let ref = db.collection("users")
            .document(uid)
            .collection("banned")
            .document(targetUid)

        try await ref.setData([
            "createdAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

    // ✅ BAN解除
    func unban(uid targetUid: String) async throws {
        guard !uid.isEmpty, !targetUid.isEmpty, uid != targetUid else { return }

        let ref = db.collection("users")
            .document(uid)
            .collection("banned")
            .document(targetUid)

        try await ref.delete()
    }

    private func generateFriendCode(length: Int = 6) -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<length).compactMap { _ in chars.randomElement() })
    }
    
    private func checkAndHandleBanIfNeeded() async -> Bool {
        guard !uid.isEmpty else { return false }

        do {
            let snap = try await db.collection("banned_users").document(uid).getDocument()
            if snap.exists {
                isBanned = true
                let data = snap.data() ?? [:]
                banReason = data["reason"] as? String ?? ""

                // ✅ friendCode を確実に取る → 端末に保存
                await fetchMyFriendCodeIfNeeded()
                deviceBanFriendCode = friendCode

                // ✅ 端末BAN保存
                deviceBanned = true
                deviceBanReason = banReason
                deviceBanUid = uid

                // ✅ 強制ログアウト
                do { try Auth.auth().signOut() } catch { }
                uid = ""
                // friendCodeは画面表示用に残してもいいけど、気になるなら消してOK
                // friendCode = ""

                status = "このアカウントは利用停止中です"
                return true
            } else {
                isBanned = false
                banReason = ""
                return false
            }
        } catch {
            // ネット不安定時にどうするかは好みだけど、
            // “安全側”に倒すならBAN扱いで止めるのもあり
            print("❌ BANチェック失敗:", error)
            return false
        }
    }
    
    private enum LocalBanKeys {
        static let deviceBanned = "deviceBanned"
        static let deviceBanReason = "deviceBanReason"
        static let deviceBanUid = "deviceBanUid"
        static let deviceBanFriendCode = "deviceBanFriendCode"
    }

    private var deviceBanned: Bool {
        get { UserDefaults.standard.bool(forKey: LocalBanKeys.deviceBanned) }
        set { UserDefaults.standard.set(newValue, forKey: LocalBanKeys.deviceBanned) }
    }

    private var deviceBanReason: String {
        get { UserDefaults.standard.string(forKey: LocalBanKeys.deviceBanReason) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: LocalBanKeys.deviceBanReason) }
    }

    private var deviceBanUid: String {
        get { UserDefaults.standard.string(forKey: LocalBanKeys.deviceBanUid) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: LocalBanKeys.deviceBanUid) }
    }
    
    private var deviceBanFriendCode: String {
        get { UserDefaults.standard.string(forKey: LocalBanKeys.deviceBanFriendCode) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: LocalBanKeys.deviceBanFriendCode) }
    }

    private func fetchMyFriendCodeIfNeeded() async {
        guard !uid.isEmpty else { return }
        if !friendCode.isEmpty { return }

        do {
            let userSnap = try await db.collection("users").document(uid).getDocument()
            let data = userSnap.data() ?? [:]
            if let code = data["friendCode"] as? String, !code.isEmpty {
                friendCode = code
            }
        } catch {
            print("❌ friendCode取得失敗:", error)
        }
    }
    // ✅ デモ用：端末BANを解除（本番では基本使わない）
    func clearLocalBanForDebug() {
        deviceBanned = false
        deviceBanReason = ""
        deviceBanUid = ""
        isBanned = false
        banReason = ""
        status = "利用停止を解除しました（端末）"
    }
    
    // ✅ 管理者BAN（banned_usersに直接登録）
    func adminBan(uid targetUid: String, reason: String = "admin ban") async throws {
        guard !targetUid.isEmpty else { return }

        try await db.collection("banned_users")
            .document(targetUid)
            .setData([
                "reason": reason,
                "createdAt": FieldValue.serverTimestamp()
            ], merge: true)

        print("🔥 BAN実行:", targetUid)

        if targetUid == uid {
            _ = await checkAndHandleBanIfNeeded()
        }
    }

    // ✅ 管理者BAN解除
    func adminUnban(uid targetUid: String) async throws {
        guard !targetUid.isEmpty else { return }

        try await db.collection("banned_users")
            .document(targetUid)
            .delete()

        print("🟢 BAN解除:", targetUid)

        // ✅ もし自分なら端末BANも解除
        if targetUid == deviceBanUid {
            deviceBanned = false
            deviceBanReason = ""
            deviceBanUid = ""
            deviceBanFriendCode = ""

            isBanned = false
            banReason = ""
            status = "利用停止が解除されました"
        }
    }
    
    // ✅ friendCode から uid を引いて BAN（デモ/管理者用）
    func adminBanByFriendCode(friendCode: String, reason: String = "admin ban") async throws {
        let code = friendCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !code.isEmpty else { return }

        // users_public から friendCode一致を探す
        let snap = try await db.collection("users_public")
            .whereField("friendCode", isEqualTo: code)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snap.documents.first else {
            throw NSError(domain: "AuthStore", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "そのfriendCodeのユーザーが見つかりません"
            ])
        }

        // ✅ uid はフィールドが無くても docID を使える（ここ超重要）
        let targetUid = (doc.data()["uid"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? doc.documentID

        try await db.collection("banned_users")
            .document(targetUid)
            .setData([
                "reason": reason,
                "friendCode": code,
                "createdAt": FieldValue.serverTimestamp()
            ], merge: true)

        print("🔥 BAN(friendCode):", code, "-> uid:", targetUid)

        // 自分をBANした場合は即反映
        if targetUid == uid {
            _ = await checkAndHandleBanIfNeeded()
        }
    }

    // ✅ friendCode から uid を引いて BAN解除
    func adminUnbanByFriendCode(friendCode: String) async throws {
        let code = friendCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !code.isEmpty else { return }

        let snap = try await db.collection("users_public")
            .whereField("friendCode", isEqualTo: code)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snap.documents.first else {
            throw NSError(domain: "AuthStore", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "そのfriendCodeのユーザーが見つかりません"
            ])
        }

        let targetUid = (doc.data()["uid"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? doc.documentID

        try await db.collection("banned_users")
            .document(targetUid)
            .delete()

        print("🟢 UNBAN(friendCode):", code, "-> uid:", targetUid)
        
        if targetUid == deviceBanUid {
            deviceBanned = false
            deviceBanReason = ""
            deviceBanUid = ""
            deviceBanFriendCode = ""

            isBanned = false
            banReason = ""
            status = "利用停止が解除されました"
        }
    }
}
