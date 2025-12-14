//
//  CustomButton3.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2025/12/14.
//

import Foundation
import SwiftUI
import AudioToolbox

struct CustomButton3: View {
    let title: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }, label: {
            Text(title)
                .foregroundStyle(.black)
                .padding()
                .frame(width: 165, height: 75)
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
        })
    }
}

#Preview {
    CustomButton3(title: "あいうえお", action: executeSomething)
}

private func executeSomething() {
    // Placeholder for preview action
}
