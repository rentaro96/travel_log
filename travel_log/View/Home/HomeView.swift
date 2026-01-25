//
//  HomeView.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2025/11/30.
//

import SwiftUI

struct HomeView: View {

    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var userStore: UserStore

    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 30) {
                    Spacer(minLength: 50)
                    Color.clear

                    Image("tabirogu")
                        .resizable()
                        .frame(width: 350, height: 350)

                    CustomButton(title: "使い方！", action: { print("とろろ") })

                    CustomNavButton(title: "友達を追加", destination: FriendAddView())

                    // ✅ ここを「設定シートを開く」に変更
                    CustomButton(title: "設定", action: {
                        showSettings = true
                    })


                    Spacer(minLength: 80)
                }
                .background(Color.customBackgroundColor)
                .ignoresSafeArea()
            }
            // ✅ HomeViewからSettingViewをsheetで出す
            .sheet(isPresented: $showSettings) {
                SettingView()
                    .environmentObject(authStore)
                    .environmentObject(userStore)
                    .presentationDetents([.medium]) // 軽い設定ならおすすめ
            }
        }
    }
}

#Preview {
    HomeView()
}


    

