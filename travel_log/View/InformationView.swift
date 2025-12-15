//
//  InformationView.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2025/12/15.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine
import CoreMotion

struct InformationView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack {
            Color.yellow.edgesIgnoringSafeArea(.all)
            Button("閉じる") {
                dismiss()
            }
        }
    }
}

#Preview {
    InformationView()
}
