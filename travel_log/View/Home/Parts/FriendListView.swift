import SwiftUI

struct FriendListView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var userStore: UserStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedUser: UserPublic? = nil
    @State private var showReportSheet = false
    @State private var pendingFriendCode: String? = nil
    @State private var showFriendAddSheet = false
    @State private var toastMessage = ""
    @State private var showToast = false

    private var blockedUidSet: Set<String> {
        Set(userStore.blockedUsers.compactMap { $0.uid }.filter { !$0.isEmpty })
    }

    private var visibleFriends: [UserPublic] {
        userStore.friends.filter { !blockedUidSet.contains($0.uid ?? "") }
    }



    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
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
                                                
                                                await MainActor.run {
                                                            pendingFriendCode = user.friendCode   // ✅ ここが自動入力の元
                                                            toastMessage = "ブロック解除しました。フレンドに戻すには追加してください"
                                                            withAnimation { showToast = true }
                                                    pendingFriendCode = user.friendCode
                                                    showFriendAddSheet = true

                                                        }
                                            }
                                        }
                                        
                                    }
                            }
                        }
                    }
                }
                
                if showToast {
                    HStack(spacing: 12) {
                        Text(toastMessage)
                            .font(.callout)
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        Button("フレンド追加へ") {
                            showToast = false
                            showFriendAddSheet = true
                        }
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.bottom, 18)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
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
                
                try? await Task.sleep(nanoseconds: 4_000_000_000) // 4秒で消す（ボタン押す猶予）
                            await MainActor.run { withAnimation { showToast = false } }

            }
            .sheet(isPresented: $showFriendAddSheet, onDismiss: {
                pendingFriendCode = nil
            }) {
                FriendAddView(initialFriendCode: pendingFriendCode ?? "")
                    .environmentObject(authStore)
                    .environmentObject(userStore)
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
//
//    @MainActor
//    private func reloadBlocked() async {
//        await userStore.fetchBlockedUsers(blockedUids: Array(authStore.blockedUids))
//    }
    @MainActor
    private func showToast(_ message: String) {
        toastMessage = message
        withAnimation(.easeOut(duration: 0.2)) {
            showToast = true
        }

        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒
            withAnimation(.easeIn(duration: 0.2)) {
                showToast = false
            }
        }
    }

}
