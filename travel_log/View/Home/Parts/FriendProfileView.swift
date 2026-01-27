//
//  FriendProfileView.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/25.
//

import SwiftUI

struct FriendProfileView: View {

    let user: UserPublic

    @StateObject private var tripStore = FriendTripStore()
    @StateObject private var friendTripStore = FriendTripStore()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // ===== プロフィールヘッダー =====
                VStack(spacing: 6) {
                    // 大：表示名
                    Text(user.displayName?.isEmpty == false
                         ? user.displayName!
                         : "名前未設定")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    // 中：ユーザーID（friendCode）
                    Text("@\(user.friendCode)")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    // 小：uid
                    Text(user.uid ?? "")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 2)

                }
                .padding(.top, 20)

                Divider()

                // ===== 旅ログ =====
                VStack(alignment: .leading, spacing: 10) {
                    Text("旅の記録")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal)

                    if tripStore.trips.isEmpty {
                        Text("まだ旅の記録はありません")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    } else {
                        ForEach(tripStore.trips) { trip in
                            NavigationLink {
                                FriendTripDetailView(trip: trip)
                                    .environmentObject(friendTripStore)
                            } label: {
                                TripCardView(trip: trip) // 今のカード見た目をそのまま使える
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("プロフィール")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard let uid = user.uid, !uid.isEmpty else { return }
            tripStore.bind(friendUid: uid)
        }

    }
}
