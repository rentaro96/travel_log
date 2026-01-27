//
//  ReportView.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/26.
//

import SwiftUI
import FirebaseFirestore

struct ReportView: View {
    let target: UserPublic
    let reporterUid: String
    @Environment(\.dismiss) private var dismiss

    @State private var reason: String = "spam"
    @State private var detail: String = ""
    @State private var isSending = false
    @State private var message: String = ""

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            Form {
                Section("対象") {
                    Text(target.displayName?.isEmpty == false ? target.displayName! : "名前未設定")
                    Text("ID: \(target.friendCode)")
                        .foregroundStyle(.secondary)
                }

                Section("理由") {
                    Picker("理由", selection: $reason) {
                        Text("スパム").tag("spam")
                        Text("迷惑行為").tag("abuse")
                        Text("なりすまし").tag("impersonation")
                        Text("その他").tag("other")
                    }
                    .pickerStyle(.segmented)
                }

                Section("詳細（任意）") {
                    TextField("状態、状況を書いてください", text: $detail, axis: .vertical)
                        .lineLimit(3...6)
                }

                if !message.isEmpty {
                    Text(message).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("報告")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSending ? "送信中…" : "送信") {
                        Task { await send() }
                    }
                    .disabled(isSending)
                }
            }
        }
    }

    private func send() async {
        guard !reporterUid.isEmpty,
              let targetUid = target.uid, !targetUid.isEmpty
        else { return }

        isSending = true
        defer { isSending = false }

        do {
            try await db.collection("reports").addDocument(data: [
                "reporterUid": reporterUid,
                "targetUid": targetUid,             // ✅ ここはString
                "reason": reason,
                "detail": detail,
                "createdAt": FieldValue.serverTimestamp(),
                "targetFriendCode": target.friendCode
            ])
            message = "送信しました。ご協力ありがとうございます。"
            dismiss()
        } catch {
            message = "送信に失敗しました: \(error.localizedDescription)"
        }
    }

}
