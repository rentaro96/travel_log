//
//  TripDetailView.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/08.
//

import SwiftUI
import MapKit
import CoreLocation

struct TripDetailView: View {
    let trip: Trip
    @EnvironmentObject var tripStore: TripStore

    @State private var position: MapCameraPosition = .automatic
    @State private var hasCenteredOnce = false
    @State private var selectedNote: TravelNote? = nil
    @State private var isPublicState: Bool = false


    // ✅ 表示用に軽量化したデータ（UIは同じ、描画だけ軽くなる）
    private var routeForMap: [CLLocationCoordinate2D] {
        trip.route.downsample(maxCount: 900) // 300〜1200で調整OK
    }

    private var notesForMap: [TravelNote] {
        // ピンが多いとMapが重いので上限
        // たくさんある場合は新しい順で最大150個だけ表示
        let sorted = trip.notes.sorted { $0.date > $1.date }
        return Array(sorted.prefix(150))
    }

    private var sortedNotesForList: [TravelNote] {
        // List用はソートを1回だけ
        trip.notes.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(spacing: 0) {
            Map(position: $position, interactionModes: .all) {
                mapPolyline
                mapAnnotations
            }
            .frame(height: 320)
            .onAppear { centerMapIfNeeded() }

            Divider()

            List {
                Section {
                        Toggle("この旅を公開する", isOn: $isPublicState)
                            .onAppear {
                                isPublicState = trip.isPublic
                            }
                            .onChange(of: isPublicState) { newValue in
                                Task {
                                    try? await tripStore.updateTripVisibility(
                                        tripId: trip.id,
                                        isPublic: newValue
                                    )
                                }
                            }
                    }
                Section {
                    HStack {
                        Text("ルート点数")
                        Spacer()
                        Text("\(trip.route.count)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("メモ・写真")
                        Spacer()
                        Text("\(trip.notes.count)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("歩数")
                        Spacer()
                        Text("\(trip.steps)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("距離")
                        Spacer()
                        Text(String(format: "%.2f km", trip.distanceMeters / 1000))
                            .foregroundStyle(.secondary)
                    }
                }

                Section("写真・メモ（時系列）") {
                    notesList
                }
            }
        }
        .navigationTitle(trip.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedNote) { note in
            NoteDetailSheet(note: note)
                .environmentObject(tripStore)
        }
    }

    // MARK: - Map Content

    @MapContentBuilder
    private var mapPolyline: some MapContent {
        if routeForMap.count >= 2 {
            MapPolyline(coordinates: routeForMap)
                .stroke(.blue, lineWidth: 8)
        }
    }

    @MapContentBuilder
    private var mapAnnotations: some MapContent {
        // ✅ ピンは最大150個に制限（多すぎるとMapが固まる）
        ForEach(notesForMap) { note in
            Annotation(
                note.type == .photo ? "Photo" : "Memo",
                coordinate: CLLocationCoordinate2D(latitude: note.latitude, longitude: note.longitude)
            ) {
                Button {
                    selectedNote = note
                } label: {
                    Image(systemName: note.type == .photo ? "camera.fill" : "text.bubble.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(note.type == .photo ? Color.blue : Color.orange)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }
            }
        }
    }

    // MARK: - Notes List

    @ViewBuilder
    private var notesList: some View {
        // ✅ body内で毎回 sort しない（sortedNotesForList を使う）
        ForEach(sortedNotesForList) { note in
            Button {
                selectedNote = note
            } label: {
                HStack(spacing: 12) {
                    if note.type == .photo,
                       let fn = note.photoFilename {
                        RemotePhotoThumbnail(path: fn)
                            .frame(width: 56, height: 56)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Image(systemName: note.type == .photo ? "camera.fill" : "text.bubble.fill")
                            .frame(width: 56, height: 56)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if note.type == .memo {
                            Text(note.text ?? "")
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                        } else {
                            Text("写真")
                                .foregroundStyle(.primary)
                        }
                    }

                    Spacer()
                }
            }
        }
    }

    // MARK: - Center Map

    private func centerMapIfNeeded() {
        guard !hasCenteredOnce else { return }
        hasCenteredOnce = true

        if let first = routeForMap.first {
            position = .region(MKCoordinateRegion(
                center: first,
                latitudinalMeters: 1500,
                longitudinalMeters: 1500
            ))
        } else if let firstNote = trip.notes.first {
            position = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: firstNote.latitude, longitude: firstNote.longitude),
                latitudinalMeters: 1500,
                longitudinalMeters: 1500
            ))
        }
    }
}

// MARK: - Downsample helper

private extension Array {
    func downsample(maxCount: Int) -> [Element] {
        guard maxCount > 0, count > maxCount else { return self }
        let strideVal = Swift.max(1, count / maxCount)
        return self.enumerated().compactMap { (i, e) in
            i % strideVal == 0 ? e : nil
        }
    }
}
