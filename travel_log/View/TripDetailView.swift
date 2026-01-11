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
    
    // Map camera
    @State private var position: MapCameraPosition = .automatic
    @State private var hasCenteredOnce = false
    
    // ✅ sheet(item:) 用（これだけ）
    @State private var selectedNote: TravelNote? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // ===== Map（ルート線＋ピン）=====
            Map(position: $position, interactionModes: .all) {
                mapPolyline
                mapAnnotations
            }
            .frame(height: 320)
            .onAppear { centerMapIfNeeded() }
            
            Divider()
            
            // ===== 下：ノート一覧（サムネ付き）=====
            List {
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
        
        // ✅ ここが本命：nilじゃない時だけ開くので白くならない
        .sheet(item: $selectedNote) { note in
            NoteDetailSheet(note: note)
                .environmentObject(tripStore)
        }
    }
    
    // MARK: - View Builders
    
    @MapContentBuilder
    private var mapPolyline: some MapContent {
        if trip.route.count >= 2 {
            MapPolyline(coordinates: trip.route)
                .stroke(.blue, lineWidth: 8)
        }
    }

    // Mapの中で使う：ピン
    @MapContentBuilder
    private var mapAnnotations: some MapContent {
        ForEach(trip.notes) { note in
            Annotation(
                note.type == .photo ? "Photo" : "Memo",
                coordinate: note.coordinate
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
    
    @ViewBuilder
    private var notesList: some View {
        ForEach(trip.notes.sorted { $0.date < $1.date }) { note in
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
                    }
                        else {
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
    
    private func centerMapIfNeeded() {
        guard !hasCenteredOnce else { return }
        hasCenteredOnce = true

        if let first = trip.route.first {
            position = .region(MKCoordinateRegion(
                center: first,
                latitudinalMeters: 1500,
                longitudinalMeters: 1500
            ))
        } else if let firstNote = trip.notes.first {
            position = .region(MKCoordinateRegion(
                center: firstNote.coordinate,
                latitudinalMeters: 1500,
                longitudinalMeters: 1500
            ))
        }
    }
}
