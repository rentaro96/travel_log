//
//  LocalPhotoThumbnail.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/26.
//

import SwiftUI
import UIKit

struct LocalPhotoThumbnail: View {
    let filename: String
    @State private var image: UIImage? = nil

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.thinMaterial)
                    ProgressView()
                }
            }
        }
        .task {
            image = try? LocalPhotoStore.loadImage(filename: filename)
        }
    }
}
