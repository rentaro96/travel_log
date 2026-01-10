//
//  InformationView.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2025/12/15.
//

import SwiftUI

struct InformationView: View {
    let steps: Int
    let distanceMeters: Double

    var body: some View {
        VStack(spacing: 16) {

            HStack {
                Text("歩数")
                Spacer()
                Text("\(steps) 歩")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("距離")
                Spacer()
                Text(String(format: "%.2f km", distanceMeters / 1000))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    InformationView(steps: 1234, distanceMeters: 1567) // ✅値を入れる
}
