//
//  HistoryView.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2025/11/30.
//

import SwiftUI

struct HistoryView: View {
    var body: some View {
        ZStack {
            VStack(spacing:20) {
                Color.clear
                Image("tabirogu2")
                    .resizable()
                    .frame(width:390, height:200)
                Button(action: { let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
 }) {
                    Image("tabirogu3")
                        .resizable()
                    .frame(width:350, height:180)}
                
                    
                    Button(action: { let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
 }) {
                        Image("tabirogu4")
                            .resizable()
                            .frame(width:350, height:180)
                    }
                    Spacer(minLength: 120)
                }
                .background(Color.customBackgroundColor)
                .ignoresSafeArea()
            }
        }
    }


#Preview {
    HistoryView()
}
