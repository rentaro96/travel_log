//
//  FriendRemotePhotoThumbnail.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/25.
//

import SwiftUI

struct FriendRemotePhotoThumbnail: View {
    let path: String
    @EnvironmentObject var friendTripStore: FriendTripStore
    @State private var image: UIImage? = nil

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                ProgressView()
                    .task {
                        do { image = try await friendTripStore.loadPhoto(path: path) }
                        catch { /* 失敗時は空 */ }
                    }
            }
        }
    }
}

