//
//  HistoryView.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2025/11/30.
//

import SwiftUI

struct HistoryView: View {
    @State private var navigateToHistoryMap = false
    @State private var showAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 20) {
                    Color.clear
                    Image("tabirogu2")
                        .resizable()
                        .frame(width: 390, height: 200)
                    
                    // NavigationLink is activated by state variable.
                    NavigationLink(
                        destination: HistoryMapView(),
                        isActive: $navigateToHistoryMap
                    ) {
                        EmptyView()
                    }
                    .hidden()
                    
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        navigateToHistoryMap = true
                    }) {
                        Image("tabirogu3")
                            .resizable()
                            .frame(width: 350, height: 180)
                    }
                    
                    
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        showAlert = true
                    }) {
                        Image("tabirogu4")
                            .resizable()
                            .frame(width: 350, height: 180)
                    }
                    .alert("現在利用できません", isPresented: $showAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("この機能は現在準備中です。次のアップデートで追加予定です。")
                    }
                    
                    Spacer(minLength: 120)
                }
                .background(Color.customBackgroundColor)
                .ignoresSafeArea()
            }
        }
    }
}


#Preview {
    HistoryView()
}
