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
    var body: some View {
        TabView(selection: $selectedTab) {
            StartView()
                .tabItem {
                    Label("", systemImage: "airplane")
                }
                .tag(0)
            HomeView()
                .tabItem {
                    Label("", systemImage: "house.fill")
                }
                .tag(1)
            HistoryView()
                .tabItem {
                    Label("", systemImage: "clock.fill")
                }
                .tag(2)
        }
        .task {
            await authStore.signInIfNeeded()
        }
    }
}

#Preview {
    ContentView()
}
