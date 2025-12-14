//
//  CustomButton2.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2025/12/14.
//

import Foundation
import SwiftUI
import AudioToolbox

struct CustomButton2: View {
    let title: LocalizedStringKey
    let action: () -> Void
    let imagename: String
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        })
        {
            VStack(spacing: 8){
                Image(systemName: imagename)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 55, height: 55)
                    .foregroundStyle(.black)
                Text(title)
                    .foregroundStyle(.black)
                    .font(Font.buttonFont(size: 20))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 170, height: 120)
        }
    }
}

#Preview {
    CustomButton2(title: "あいうえお", action: {
        // Placeholder for preview action
    }, imagename: "star")
}
