//
//  NoteDetailSheet.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/08.
//

import SwiftUI
import UIKit

struct NoteDetailSheet: View {
    let note: TravelNote
    @Environment(\.dismiss) private var dismiss
    
    
    @State private var image: UIImage? = nil
    @State private var loadError: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    if note.type == .photo {
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                ProgressView("読み込み中…")
                                if let loadError {
                                    Text(loadError)
                                        .font(.footnote)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }

                    if note.type == .memo, let text = note.text {
                        Text(text)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Text("📍 \(note.latitude), \(note.longitude)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text("🕒 \(note.date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle(note.type == .photo ? "写真" : "メモ")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
            .onAppear {
                guard note.type == .photo,
                      let filename = note.photoFilename else { return }

                do {
                    image = try LocalPhotoStore.loadImage(filename: filename)
                } catch {
                    loadError = "画像の読み込みに失敗しました: \(error.localizedDescription)"
                }
            }

        }
    }
}

