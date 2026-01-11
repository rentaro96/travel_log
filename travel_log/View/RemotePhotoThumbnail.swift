//
//  RemotePhotoThumbnail.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/11.
//

import SwiftUI

struct RemotePhotoThumbnail: View {
    let path: String
    @EnvironmentObject var tripStore: TripStore

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
            }
        }
        .task {
            await load()
        }
    }

    private func load() async {
        do {
            image = try await tripStore.loadPhoto(path: path)
        } catch {
            print("loadPhoto error:", error)
        }
    }
}
