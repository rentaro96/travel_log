//
//  FriendAddView.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2025/12/24.
//

import SwiftUI

struct FriendAddView: View {
    //@StateObject private var authStore = AuthStore()
    @EnvironmentObject var authStore: AuthStore
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userStore: UserStore
    @StateObject private var friendVM = FriendViewModel()
    @StateObject private var requestsVM = FriendRequestsViewModel()
    @State private var showFriendList = false
    @EnvironmentObject var adminMode: AdminMode
    
    let initialFriendCode: String


    @State private var inputCode: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Spacer(minLength: 25)

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
                            friendVM.message = "コピーしました"
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

                    Button(adminMode.enabled ? "デモ：即友達になる" : "フレンド申請を送る") {
                        Task {
                            let myUid = authStore.uid

                            if adminMode.enabled {
                                // ✅ デモモード：即友達成立
                                await requestsVM.addFriendInstantly(
                                    myUid: myUid,
                                    friendCode: inputCode
                                )
                            } else {
                                // ✅ 通常モード：申請送信
                                await friendVM.sendFriendRequest(
                                    myUid: myUid,
                                    myFriendCode: authStore.friendCode,
                                    friendCode: inputCode
                                )
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(adminMode.enabled ? .green : .blue)
                    
                    if adminMode.enabled {
                        Text("🧪 デモモード中：承認なしで即友達になります")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }



                }

                if !friendVM.message.isEmpty {
                    Text("送信できませんでした")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                else{
                    Text(friendVM.message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("受信した申請")
                        .font(.footnote)
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
                Spacer(minLength: 40)
            }
            .padding()
            .navigationTitle("フレンド追加")
            
            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button {
                                        showFriendList = true
                                    } label: {
                                        Image(systemName: "person.2")
                                    }
                                }
                            }

                            // ✅sheet
                            .sheet(isPresented: $showFriendList) {
                                FriendListView()
                                    .environmentObject(authStore)   // 念のため
                                    // userStoreはEnvironmentObjectで流してるなら不要だけど、
                                    // もし事故るなら .environmentObject(userStore) を足す
                            }
                            .onAppear {
                                // ✅ トーストから来た場合、最初から入力しておく
                                if inputCode.isEmpty, !initialFriendCode.isEmpty {
                                    inputCode = initialFriendCode
                                }
                            }

            .task {
                guard !authStore.uid.isEmpty else { return }
                requestsVM.startListening(myUid: authStore.uid)
            }
            .onDisappear {
                requestsVM.stopListening()
            }
            }
            .onDisappear {
                requestsVM.stopListening()
            }
            .toolbar(.hidden, for: .navigationBar)
                    .ignoresSafeArea()
        }
        
        
    }
    


#Preview {
    FriendAddView(initialFriendCode: "A7K9Q2")
        .environmentObject(AuthStore())
        .environmentObject(UserStore())
}

