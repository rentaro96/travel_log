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
    @State private var didStartLoad = false
    @State private var failed = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if failed {
                // ✅ 失敗時：無限ロードしない（UIはほぼ変わらない）
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .padding(12)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
        }
        .task(id: path) {
            // ✅ path が変わった時だけロード
            guard !didStartLoad else { return }
            didStartLoad = true
            await loadOnce()
        }
    }

    private func loadOnce() async {
        do {
            // ✅ すでに取得できてたら何もしない
            if image != nil { return }

            image = try await tripStore.loadPhoto(path: path)
        } catch {
            // ✅ 404などは「画像が無い」だけ。ここで止める（リトライしない）
            failed = true
            print("loadPhoto error:", error)
        }
    }
}
