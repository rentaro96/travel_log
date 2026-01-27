import SwiftUI

struct FriendListView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var userStore: UserStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedUser: UserPublic? = nil
    @State private var showReportSheet = false

    // ✅ UserStoreのblockedUsersを正にする（uidが空のものは除外）
    private var blockedUidSet: Set<String> {
        Set(userStore.blockedUsers.compactMap { $0.uid }.filter { !$0.isEmpty })
    }


    private var visibleFriends: [UserPublic] {
        userStore.friends.filter { friend in
            guard let uid = friend.uid, !uid.isEmpty else { return false }
            return !blockedUidSet.contains(uid)
        }
    }


    var body: some View {
        NavigationStack {
            List {
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
                                        guard let uid = user.uid, !uid.isEmpty else { return }
                                        try? await authStore.block(uid: uid)
                                    }
                                }


                                Button("報告") {
                                    selectedUser = user
                                    showReportSheet = true
                                }

                                Button("削除", role: .destructive) {
                                    Task {
                                        guard let uid = user.uid, !uid.isEmpty else { return }
                                        try? await userStore.removeFriend(myUid: authStore.uid, friendUid: uid)
                                    }
                                }

                            }
                        }
                    }
                }

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
                                            guard let uid = user.uid, !uid.isEmpty else { return }
                                            try? await authStore.unblock(uid: uid)
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
                
                userStore.bindBlockedUsers(myUid: authStore.uid)

                // ✅ 初回だけは即1回フェッチして表示を早くする（任意）
                await reloadBlocked()
            }
            .sheet(isPresented: $showReportSheet) {
                if let user = selectedUser {
                    ReportView(target: user, reporterUid: authStore.uid)
                }
            }
        }
    }

    @ViewBuilder
    private func friendRow(user: UserPublic) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(user.displayName?.isEmpty == false ? user.displayName! : "名前未設定")
                .font(.headline)

            Text("ID: \(user.friendCode)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @MainActor
    private func reloadBlocked() async {
        await userStore.fetchBlockedUsers(blockedUids: Array(authStore.blockedUids))
    }
}
