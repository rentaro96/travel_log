//
//  ContentView.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2025/11/30.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            StartView()
                .tabItem {
                    Label("", systemImage: "airplane")
                }
            HomeView()
                .tabItem {
                    Label("", systemImage: "house.fill")
                }
            HistoryView()
                .tabItem {
                    Label("", systemImage: "clock.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
