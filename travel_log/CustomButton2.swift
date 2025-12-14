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
            VStack{
                Image(systemName: imagename)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(.black)
                Text(title)
                    .foregroundStyle(.black)
                    .font(Font.buttonFont(size: 28))
            }
            .frame(width: 120, height: 120)
        }
    }
}

#Preview {
    CustomButton2(title: "あいうえお", action: {
        // Placeholder for preview action
    }, imagename: "star")
}
