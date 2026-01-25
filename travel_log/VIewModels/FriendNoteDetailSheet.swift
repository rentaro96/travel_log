//
//  FriendNoteDetailSheet.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/25.
//

import SwiftUI

struct FriendNoteDetailSheet: View {
    let note: TravelNote
    @EnvironmentObject var friendTripStore: FriendTripStore
    @State private var image: UIImage? = nil

    var body: some View {
        VStack(spacing: 12) {
            Text(note.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)

            if note.type == .memo {
                Text(note.text ?? "")
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if let path = note.photoFilename {
                Group {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        ProgressView()
                            .task {
                                do { image = try await friendTripStore.loadPhoto(path: path) }
                                catch { }
                            }
                    }
                }
            }
            Spacer()
        }
        .padding()
        .presentationDetents([.medium, .large])
    }
}

