//
//  ContentView.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2025/11/30.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var selectedTab = 1
    @AppStorage("agreedTerms") var agreedTerms = false
    @State private var showTerms = false
    
    let tripStore = TripStore()
    
    var body: some View {
        if !agreedTerms {

                    VStack(spacing: 20) {
                        Spacer()

                        Text("利用規約に同意してください")
                            .font(.title3)

                        Text("本アプリではユーザー投稿機能があります。不適切な内容は禁止されています。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding()

                        Button("同意して開始") {
                            agreedTerms = true
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: 240)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)

                        Spacer()
                    }
                    .toolbar {
                                    ToolbarItem(placement: .topBarTrailing) {
                                        Button("利用規約を見る") {
                                            showTerms = true
                                        }
                                    }
                                }

        }else{
            TabView(selection: $selectedTab) {
                StartView()
                    .tabItem { Label("", systemImage: "airplane") }
                    .tag(0)
                
                HomeView()
                    .tabItem { Label("", systemImage: "house.fill") }
                    .tag(1)
                    .task {
                        await authStore.signInIfNeeded()   // ✅ ここだけ
                    }
                
                NavigationStack {
                    HistoryView()
                }
                .tabItem { Label("", systemImage: "clock.fill") }
                .tag(2)
            }
            
            .task {
                await authStore.signInIfNeeded()
                tripStore.setUID(authStore.uid.isEmpty ? nil : authStore.uid)
            }
        }
            }
        }




#Preview {
    ContentView()
}
