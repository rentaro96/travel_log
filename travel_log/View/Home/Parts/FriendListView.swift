//
//  FriendListView.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/25.
//

import SwiftUI

struct FriendListView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var userStore: UserStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(userStore.friends) { user in
                NavigationLink {
                    FriendProfileView(user: user)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.displayName?.isEmpty == false
                             ? user.displayName!
                             : "名前未設定")
                            .font(.headline)

                        Text("ID: \(user.friendCode)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }


            .navigationTitle("フレンド")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
            .task {
                // ここで一覧監視開始（すでにどこかでbindしてるなら不要）
                guard !authStore.uid.isEmpty else { return }
                userStore.bindUser(uid: authStore.uid)
            }
        }
    }
}

