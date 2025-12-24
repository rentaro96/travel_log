//
//  CustomButton4.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2025/12/25.
//

import Foundation
import SwiftUI
import AudioToolbox


struct CustomNavButton<Destination: View>: View {
    let title: LocalizedStringKey
    let destination: Destination

    var body: some View {
        NavigationLink {
            destination
        } label: {
            Text(title)
                .foregroundStyle(.black)
                .padding()
                .frame(width: 330, height: 75)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black, lineWidth: 7)
                )
                .font(Font.buttonFont(size: 28))
                .background {
                    RoundedRectangle(
                        cornerSize: .init(width: 26, height: 26),
                        style: .continuous
                    )
                    .fill(Color.customButtonColor)
                }
        }
        
        .simultaneousGesture(TapGesture().onEnded {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        })
    }
}
