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
    @EnvironmentObject var tripStore: TripStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    if note.type == .photo,
                       let filename = note.photoFilename,
                       let uiImage = tripStore.loadPhoto(filename: filename) {

                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
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
        }
    }
}
