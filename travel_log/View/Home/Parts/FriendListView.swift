import SwiftUI

struct FriendListView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var userStore: UserStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedUser: UserPublic? = nil
    @State private var showReportSheet = false

    // フレンド一覧（ブロック対象は除外）
    private var visibleFriends: [UserPublic] {
        userStore.friends.filter { !authStore.isBlocked($0.uid) }
    }

    var body: some View {
        NavigationStack {
            List {

                // ===== フレンド =====
                Section("フレンド") {
                    if visibleFriends.isEmpty {
                        Text("フレンドがいません")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(visibleFriends) { user in
                            NavigationLink {
                                FriendProfileView(user: user)
                            } label: {
                                friendRow(user: user)
                            }
                            .contextMenu {
                                Button("ブロック", role: .destructive) {
                                    Task {
                                        try? await authStore.block(uid: user.uid)
                                        await reloadBlocked()
                                    }
                                }

                                Button("報告") {
                                    selectedUser = user
                                    showReportSheet = true
                                }

                                Button("削除", role: .destructive) {
                                    Task {
                                        try? await userStore.removeFriend(
                                            myUid: authStore.uid,
                                            friendUid: user.uid
                                        )
                                    }
                                }
                            }
                        }
                    }
                }

                // ===== ブロック中 =====
                Section("ブロック中") {
                    if userStore.blockedUsers.isEmpty {
                        Text("ブロック中のユーザーはいません")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(userStore.blockedUsers) { user in
                            friendRow(user: user)
                                .contextMenu {
                                    Button("ブロック解除") {
                                        Task {
                                            try? await authStore.unblock(uid: user.uid)
                                            await reloadBlocked()
                                        }
                                    }
                                }
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
                guard !authStore.uid.isEmpty else { return }
                userStore.bindUser(uid: authStore.uid)
                await reloadBlocked()
            }
            // blockedUids が変わったら再取得
            .onChange(of: authStore.blockedUids) { _, _ in
                Task {
                    await reloadBlocked()
                }
            }
            .sheet(isPresented: $showReportSheet) {
                if let user = selectedUser {
                    ReportView(target: user, reporterUid: authStore.uid)
                }
            }
        }
    }

    // ===== 共通行UI =====
    @ViewBuilder
    private func friendRow(user: UserPublic) -> some View {
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

    // ===== ブロック一覧再取得 =====
    @MainActor
    private func reloadBlocked() async {
        await userStore.fetchBlockedUsers(
            blockedUids: Array(authStore.blockedUids)
        )
    }
}
