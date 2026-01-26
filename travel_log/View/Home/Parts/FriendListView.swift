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
    
    @State private var showActionDialog = false
    @State private var selectedUser: UserPublic? = nil

    @State private var showReportSheet = false

    
    private var visibleFriends: [UserPublic] {
            userStore.friends.filter { !authStore.isBlocked($0.uid) }
        }

    var body: some View {
        NavigationStack {
            List(userStore.friends) { user in
                NavigationLink {
                    FriendProfileView(user: user)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.displayName?.isEmpty == false ? user.displayName! : "名前未設定")
                            .font(.headline)

                        Text("ID: \(user.friendCode)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle()) // 空白もタップ判定
                }
                .contextMenu { // ← ここが「user」が生きてる場所
                    Button("報告") {
                        selectedUser = user
                        showReportSheet = true
                    }

                    Button("削除", role: .destructive) {
                        Task {
                            try? await userStore.removeFriend(myUid: authStore.uid, friendUid: user.uid)
                        }
                    }

                    Button("ブロック", role: .destructive) {
                        Task {
                            try? await userStore.blockUser(myUid: authStore.uid, targetUid: user.uid)
                        }
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
            .sheet(isPresented: $showReportSheet) {
                if let user = selectedUser {
                    ReportView(target: user, reporterUid: authStore.uid)
                }
            }

        }
    }
}

