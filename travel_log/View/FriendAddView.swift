//
//  FriendAddView.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2025/12/24.
//

import SwiftUI

struct FriendAddView: View {
    @StateObject private var authStore = AuthStore()
    @StateObject private var friendVM = FriendViewModel()
    @StateObject private var requestsVM = FriendRequestsViewModel()

    @State private var inputCode: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {

                // 自分のID表示
                VStack(spacing: 6) {
                    Text("あなたのフレンドID")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        Text(authStore.friendCode.isEmpty ? "生成中…" : authStore.friendCode)
                            .font(.title2)
                            .fontWeight(.bold)
                            .tracking(2)

                        Button {
                            UIPasteboard.general.string = authStore.friendCode
                            friendVM.message = "コピーした"
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .disabled(authStore.friendCode.isEmpty)
                    }

                    Text(authStore.status)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // 申請送信
                VStack(alignment: .leading, spacing: 8) {
                    Text("相手のフレンドIDを入力")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("例：A7K9Q2", text: $inputCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled(true)
                        .textFieldStyle(.roundedBorder)

                    Button("フレンド申請を送る") {
                        Task {
                            await friendVM.sendFriendRequest(
                                myUid: authStore.uid,
                                myFriendCode: authStore.friendCode,
                                friendCode: inputCode
                            )
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                if !friendVM.message.isEmpty {
                    Text(friendVM.message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("受信した申請")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if requestsVM.received.isEmpty {
                        Text("まだ申請はない")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(requestsVM.received) { req in
                            HStack {
                                VStack(alignment: .leading) {
                                    
                                    Text("from: \(req.fromFriendCode ?? "不明")")
                                        .font(.footnote)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Button("承認") {
                                    Task { await requestsVM.accept(request: req, myUid: authStore.uid) }
                                }
                                .buttonStyle(.borderedProminent)

                                Button("拒否") {
                                    Task { await requestsVM.reject(request: req, myUid: authStore.uid) }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }

                    if !requestsVM.message.isEmpty {
                        Text(requestsVM.message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .navigationTitle("フレンド追加")
            .task {
                await authStore.signInIfNeeded()
                requestsVM.startListening(myUid: authStore.uid)
            }
            .onDisappear {
                requestsVM.stopListening()
            }
            .toolbar(.hidden, for: .navigationBar)
                    .ignoresSafeArea()
        }
    }
}

#Preview {
    FriendAddView()
}
