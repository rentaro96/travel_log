//
//  StartView.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2025/11/30.
//

import SwiftUI
import MapKit
import CoreLocation
internal import Combine
import CoreMotion
import PhotosUI

struct StartView: View {
    @StateObject var locationManager = LocationManager()
    @State private var pedometer: CMPedometer? = CMPedometer()
    
    @EnvironmentObject var tripStore: TripStore
    @State private var tripStartedAt: Date? = nil
    
    @State private var isRunning = false
    @State private var isPaused  = false
    @State private var showActionButtons = false
    
    // Map camera
    @State private var position: MapCameraPosition = .automatic
    @State private var hasCenteredOnce = false
    @State private var isFollowingUser = true
    
    // Sheets
    @State private var showInfoSheet = false
    
    // 写真用
    @State private var showPhotoDialog = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    // メモ用
    @State private var showMemoSheet = false
    
    @State private var selectedNote: TravelNote? = nil
    @State private var showNoteSheet = false
    
    @State private var steps: Int = 0
    @State private var pedometerDistance: Double = 0 // pedometerの距離（取れたら）
    
    var body: some View {
        VStack(spacing: 12) {
            
            // ====== Map + Overlay ======
            ZStack {
                Map(position: $position, interactionModes: .all) {
                    UserAnnotation()
                    
                    if locationManager.route.count >= 2 {
                        MapPolyline(coordinates: locationManager.route)
                            .stroke(.blue, lineWidth: 8)
                    }
                    notesAnnotations
                }
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .ignoresSafeArea()
                .onMapCameraChange { _ in
                    if locationManager.isRecording {
                        isFollowingUser = false
                    }
                }
                .onChange(of: locationManager.location) { loc in
                    guard let loc else { return }
                    
                    if !hasCenteredOnce {
                        hasCenteredOnce = true
                        position = .region(MKCoordinateRegion(
                            center: loc.coordinate,
                            latitudinalMeters: 800,
                            longitudinalMeters: 800
                        ))
                        return
                    }
                    
                    if locationManager.isRecording && isFollowingUser {
                        position = .region(MKCoordinateRegion(
                            center: loc.coordinate,
                            latitudinalMeters: 800,
                            longitudinalMeters: 800
                        ))
                    }
                }
                .onAppear {
                    locationManager.requestAlwaysAuthorizationIfNeeded()
                    locationManager.startUpdatingLocationIfPossible()
                }
                
                // 現在地に戻るボタン
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            isFollowingUser = true
                            if let loc = locationManager.location {
                                position = .region(MKCoordinateRegion(
                                    center: loc.coordinate,
                                    latitudinalMeters: 800,
                                    longitudinalMeters: 800
                                ))
                            }
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.black)
                                .padding(12)
                                .background(.white.opacity(0.9))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            
            // ====== 操作ボタン群 ======
            if isRunning {
                HStack(spacing: 20) {
                    
                    CustomButton3(title: "終了") {
                        pedometer?.stopUpdates()
                        
                        let recordedRoute = locationManager.stopRecording()
                        print("recorded points:", recordedRoute.count)
                        let route = locationManager.stopRecording()
                        let notes = locationManager.notes

                        let started = tripStartedAt ?? Date()
                        let ended = Date()

                        let title = started.formatted(date: .abbreviated, time: .shortened)
                       

                        let trip = Trip(title: title, startedAt: started, endedAt: ended, route: route, notes: notes)
                        
                        tripStore.addTrip(trip)
                        tripStartedAt = nil
                        locationManager.notes.removeAll()
                        
                        isRunning = false
                        isPaused = false
                        showActionButtons = false
                    }
                    
                    if isPaused {
                        CustomButton3(title: "再開") {
                            guard CMPedometer.isStepCountingAvailable() else { return }
                            
                            pedometer?.startUpdates(from: Date()) { data, error in
                                if let steps = data?.numberOfSteps {
                                    print("steps:", steps)
                                }
                            }
                            
                            locationManager.resumeRecording()
                            isFollowingUser = true
                            isPaused = false
                        }
                    } else {
                        CustomButton3(title: "停止") {
                            pedometer?.stopUpdates()
                            locationManager.pauseRecording()
                            isPaused = true
                        }
                    }
                }
                
            } else {
                CustomButton(title: "旅を始める！") {
                    guard CMPedometer.isStepCountingAvailable() else { return }
                    
                    steps = 0
                    pedometerDistance = 0
                    pedometer?.startUpdates(from: Date()) { data, error in
                        guard error == nil, let data else { return }
                        DispatchQueue.main.async {
                            steps = data.numberOfSteps.intValue
                            if let d = data.distance?.doubleValue {
                                pedometerDistance = d
                            }
                        }
                    }
                    
                    tripStartedAt = Date()
                    locationManager.startRecording(reset: true)
                    locationManager.notes.removeAll()
                    
                    locationManager.startRecording(reset: true)
                    
                    isFollowingUser = true
                    
                    isRunning = true
                    isPaused = false
                    showActionButtons = true
                }
            }
            
            // ====== 追加アクション ======
            if showActionButtons {
                HStack {
                    Spacer()
                    CustomButton2(title: "写真を残す",
                                  action: { showPhotoDialog = true },
                                  imagename: "camera.fill")
                    Spacer()
                    CustomButton2(title: "書き残す",
                                  action: { showMemoSheet = true },
                                  imagename: "text.bubble")
                    Spacer()
                    CustomButton2(
                        title: "情報",
                        action: { showInfoSheet = true },
                        imagename: "info.circle"
                    )
                    Spacer()
                }
            }
        }
        .padding(.bottom, 100)
        .background(Color.customBackgroundColor)
        .ignoresSafeArea()
        .sheet(isPresented: $showInfoSheet) {
            InformationView()
        }
        .sheet(isPresented: $showNoteSheet) {
            if let note = selectedNote {
                NoteDetailSheet(note: note)
            }
        }
        .confirmationDialog("写真を追加", isPresented: $showPhotoDialog) {
            Button("写真を撮る") {
                showCamera = true
            }
            Button("フォルダから選択") {
                showPhotoPicker = true
            }
            Button("キャンセル", role: .cancel) {}
        }
        .sheet(isPresented: $showCamera) {
            CameraView { image in
                if let data = image.jpegData(compressionQuality: 0.8) {
                    addPhotoNote(imageData: data)
                }
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            InformationView(
                steps: steps,
                distanceMeters: routeDistanceMeters()
            )
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem)
        .onChange(of: selectedPhotoItem) { item in
            guard let item else { return }

            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    addPhotoNote(imageData: data)
                }
                selectedPhotoItem = nil
            }
        }
        .sheet(isPresented: $showMemoSheet) {
            MemoInputView { text in
                locationManager.saveMemo(text)
            }
        }
    }
    
    /// Extracted annotation views for notes to reduce Map complexity
    @ViewBuilder
    private var notesAnnotations: some View {
        ForEach(locationManager.notes) { note in
            NoteAnnotationView(note: note) {
                selectedNote = note
                showNoteSheet = true
            }
        }
    }
    
    private func routeDistanceMeters() -> Double {
        let coords = locationManager.route
        guard coords.count >= 2 else { return 0 }

        var total: Double = 0
        for i in 1..<coords.count {
            let a = CLLocation(latitude: coords[i-1].latitude, longitude: coords[i-1].longitude)
            let b = CLLocation(latitude: coords[i].latitude, longitude: coords[i].longitude)
            total += b.distance(from: a)
        }
        return total
    }

    private func addPhotoNote(imageData: Data) {
        guard let loc = locationManager.location else { return }
        do {
            let filename = try tripStore.savePhotoJPEG(imageData)
            locationManager.notes.append(
                TravelNote(type: .photo,
                           latitude: loc.coordinate.latitude,
                           longitude: loc.coordinate.longitude,
                           date: Date(),
                           photoFilename: filename)
            )
        } catch {
            print("savePhotoJPEG error:", error)
        }
    }
}

/// Extracted annotation button view for a single note
private struct NoteAnnotationView: View {
    let note: TravelNote
    let onTap: () -> Void

    var body: some View {
        Annotation(
            note.type == .photo ? "Photo" : "Memo",
            coordinate: note.coordinate
        ) {
            Button(action: onTap) {
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

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
    }
}
