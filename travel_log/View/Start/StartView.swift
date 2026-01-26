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
import SwiftData

struct StartView: View {
    // MARK: - Stores / Managers
    @StateObject var locationManager = LocationManager()
    @State private var pedometer: CMPedometer? = CMPedometer()
    
    @State private var isStopping = false

    @EnvironmentObject var tripStore: TripStore
    @EnvironmentObject var authStore: AuthStore
    @Environment(\.modelContext) private var modelContext

    // MARK: - Trip State
    @State private var tripStartedAt: Date? = nil
    @State private var isRunning = false
    @State private var isPaused  = false
    @State private var showActionButtons = false

    // MARK: - Map
    @State private var position: MapCameraPosition = .automatic
    @State private var hasCenteredOnce = false
    @State private var isFollowingUser = true

    // MARK: - Sheets / Dialog
    @State private var showInfoSheet = false
    @State private var showNoteSheet = false
    @State private var showPhotoDialog = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showMemoSheet = false
    @State private var selectedNote: TravelNote? = nil

    // MARK: - Pedometer
    @State private var steps: Int = 0
    @State private var pedometerDistance: Double = 0
    
    
    @State private var currentTripId: UUID? = nil
    
    @State private var showVisibilityAlert = false
    @State private var pendingTrip: Trip? = nil

    
    

    // MARK: - Body
    var body: some View {
        VStack(spacing: 12) {
            mapSection
            controlSection
            actionSection
        }
        .padding(.bottom, 100)
        .background(Color.customBackgroundColor)
        .ignoresSafeArea()
        .applyStartViewSheets(
            showPhotoDialog: $showPhotoDialog,
            showCamera: $showCamera,
            showPhotoPicker: $showPhotoPicker,
            selectedPhotoItem: $selectedPhotoItem,
            showMemoSheet: $showMemoSheet,
            showInfoSheet: $showInfoSheet,
            showNoteSheet: $showNoteSheet,
            selectedNote: $selectedNote,
            tripStore: tripStore,
            onAddPhotoNote: { data in
                addPhotoNote(imageData: data)
            },
            onMemoSaved: { text in
                locationManager.saveMemo(text)
            },
            steps: steps,
            distanceMeters: currentDistance
        )
        .alert("この旅を公開しますか？", isPresented: $showVisibilityAlert) {
            Button("非公開で保存", role: .cancel) {
                savePendingTrip(isPublic: false)
            }
            Button("公開して保存") {
                savePendingTrip(isPublic: true)
            }
        } message: {
            Text("公開にするとフレンドがこの旅を見られます。")
        }

    }

    // MARK: - Sections

    private var mapSection: some View {
        ZStack {
            Map(position: $position, interactionModes: .all) {
                mapContent()
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
                handleLocationChange(loc)
            }
            .onAppear {
                locationManager.requestAlwaysAuthorizationIfNeeded()
                locationManager.startUpdatingLocationIfPossible()
            }

            followButtonOverlay
        }
        .onAppear {
            tripStore.setUID(authStore.uid)
        }
        .onChange(of: authStore.uid) { _, newValue in
            tripStore.setUID(newValue)
        }
    }

    private var controlSection: some View {
        Group {
            if isRunning {
                HStack(spacing: 20) {
                    CustomButton3(title: "終了") {
                        stopTrip()
                        
                    }

                    if isPaused {
                        CustomButton3(title: "再開") {
                            resumeTrip()
                        }
                    } else {
                        CustomButton3(title: "停止") {
                            pauseTrip()
                        }
                    }
                }
            } else {
                CustomButton(title: "旅を始める！") {
                    print("なぜ")
                    startTrip()
                    currentTripId = UUID()
                }
            }
        }
    }

    private var actionSection: some View {
        Group {
            if showActionButtons {
                HStack {
                    Spacer()
                    CustomButton2(
                        title: "写真を残す",
                        action: { showPhotoDialog = true },
                        imagename: "camera.fill"
                    )
                    Spacer()
                    CustomButton2(
                        title: "書き残す",
                        action: { showMemoSheet = true },
                        imagename: "text.bubble"
                    )
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
    }

    // MARK: - Map Content (軽量化の要)

    @MapContentBuilder
    private func mapContent() -> some MapContent {
        UserAnnotation()

        if locationManager.route.count >= 2 {
            MapPolyline(coordinates: locationManager.route)
                .stroke(.blue, lineWidth: 8)
        }

        ForEach(locationManager.notes) { note in
            Annotation(
                note.type == .photo ? "Photo" : "Memo",
                coordinate: note.coordinate
            ) {
                notePin(note)
            }
        }
    }

    private func notePin(_ note: TravelNote) -> some View {
        Button {
            selectedNote = note
            showNoteSheet = true
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

    private var followButtonOverlay: some View {
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

    // MARK: - Computed

    private var currentDistance: Double {
        routeDistanceMeters()
    }

    // MARK: - Actions
    /// ルート確定＆Trip生成（ここで trip が「代入」される）
    private func finalizeTrip() -> Trip {
        pedometer?.stopUpdates()

        // stopRecording は1回だけ
        let route = locationManager.stopRecording()
        let notes = locationManager.notes

        let started = tripStartedAt ?? Date()
        let ended = Date()
        let title = started.formatted(date: .abbreviated, time: .shortened)

        let distance = routeDistanceMeters()

        return Trip(
            title: title,
            startedAt: started,
            endedAt: ended,
            route: route,
            notes: notes,
            steps: steps,
            distanceMeters: distance
        )
    }
    private func startTrip() {
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

        locationManager.notes.removeAll()
        locationManager.startRecording(reset: true)

        isFollowingUser = true
        isRunning = true
        isPaused = false
        showActionButtons = true
    }

    private func pauseTrip() {
        pedometer?.stopUpdates()
        locationManager.pauseRecording()
        isPaused = true
    }

    private func resumeTrip() {
        guard CMPedometer.isStepCountingAvailable() else { return }

        pedometer?.startUpdates(from: Date()) { data, error in
            guard error == nil, let data else { return }
            DispatchQueue.main.async {
                steps = data.numberOfSteps.intValue
                if let d = data.distance?.doubleValue {
                    pedometerDistance = d
                }
            }
        }

        locationManager.resumeRecording()
        isFollowingUser = true
        isPaused = false
    }

    private func stopTrip() {
        guard !isStopping else { return }
        isStopping = true

        pedometer?.stopUpdates()

        let route = locationManager.stopRecording()
        let notes = locationManager.notes

        let started = tripStartedAt ?? Date()
        let ended = Date()
        let title = started.formatted(date: .abbreviated, time: .shortened)
        let distance = routeDistanceMeters()

        let trip = Trip(
            title: title,
            startedAt: started,
            endedAt: ended,
            route: route,
            notes: notes,
            steps: steps,
            distanceMeters: distance,
            isPublic: false
        )
        
        pendingTrip = trip
            showVisibilityAlert = true

        Task {
            defer { isStopping = false } // ここで解除

            do {
                try await tripStore.addTrip(trip)
            } catch {
                print("Firestore保存失敗:", error)
            }

            tripStartedAt = nil
            locationManager.notes.removeAll()
            isRunning = false
            isPaused = false
            showActionButtons = false
        }
    }
    
    private func savePendingTrip(isPublic: Bool) {
        guard var trip = pendingTrip else { return }

        trip.isPublic = isPublic

        Task {
            do {
                try await tripStore.addTrip(trip)

                // ✅ 保存成功したら後始末
                tripStartedAt = nil
                locationManager.notes.removeAll()

                isRunning = false
                isPaused = false
                showActionButtons = false

                pendingTrip = nil
            } catch {
                print("Firestore保存失敗:", error)
            }
        }
    }



    // MARK: - Helpers

    private func handleLocationChange(_ loc: CLLocation?) {
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

    private func routeDistanceMeters() -> Double {
        let coords = locationManager.route
        guard coords.count >= 2 else { return 0 }

        var total: Double = 0
        for i in 1..<coords.count {
            let a = CLLocation(latitude: coords[i - 1].latitude, longitude: coords[i - 1].longitude)
            let b = CLLocation(latitude: coords[i].latitude, longitude: coords[i].longitude)
            total += b.distance(from: a)
        }
        return total
    }

    private func addPhotoNote(imageData: Data) {

        // ✅ trip中じゃないと保存しない
        guard let _ = currentTripId else {
            print("❌ tripIdが無い（旅開始前）")
            return
        }

        // ✅ 位置が無いとピンが立たない
        guard let loc = locationManager.location else {
            print("❌ locationが無い")
            return
        }

        let noteId = UUID()
        let filename = "photo_\(noteId.uuidString).jpg"

        // ✅ ローカル保存（ここが本体）
        do {
            try LocalPhotoStore.saveJPEG(imageData, filename: filename)
            print("✅ saved local photo =", filename)
        } catch {
            print("❌ save local photo error:", error)
            return
        }

        // ✅ ノート追加（Firestoreには“ファイル名”だけ保存される）
        locationManager.notes.append(
            TravelNote(
                type: .photo,
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude,
                date: Date(),
                steps: steps,
                distanceMeters: currentDistance,
                text: nil,
                photoFilename: filename,
                id: noteId
            )
        )

        print("📍 photo note lat/lon =", loc.coordinate.latitude, loc.coordinate.longitude)
        print("🧾 notes.count =", locationManager.notes.count)
    }

}

// MARK: - Sheets / Dialog をまとめて軽量化
private extension View {
    func applyStartViewSheets(
        showPhotoDialog: Binding<Bool>,
        showCamera: Binding<Bool>,
        showPhotoPicker: Binding<Bool>,
        selectedPhotoItem: Binding<PhotosPickerItem?>,
        showMemoSheet: Binding<Bool>,
        showInfoSheet: Binding<Bool>,
        showNoteSheet: Binding<Bool>,
        selectedNote: Binding<TravelNote?>,
        tripStore: TripStore,
        onAddPhotoNote: @escaping (Data) -> Void,
        onMemoSaved: @escaping (String) -> Void,
        steps: Int,
        distanceMeters: Double
    ) -> some View {
        self
            .confirmationDialog("写真を追加", isPresented: showPhotoDialog) {
                Button("写真を撮る") { showCamera.wrappedValue = true }
                Button("フォルダから選択") { showPhotoPicker.wrappedValue = true }
                Button("キャンセル", role: .cancel) {}
            }

            .sheet(isPresented: showCamera) {
                CameraView { image in
                    if let data = image.jpegData(compressionQuality: 0.8) {
                        onAddPhotoNote(data)
                    }
                }
            }

            .photosPicker(isPresented: showPhotoPicker, selection: selectedPhotoItem)

            .onChange(of: selectedPhotoItem.wrappedValue) { item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        onAddPhotoNote(data)
                    }
                    selectedPhotoItem.wrappedValue = nil
                }
            }

            .sheet(isPresented: showMemoSheet) {
                MemoInputView { text in
                    onMemoSaved(text)
                }
            }

            .sheet(isPresented: showInfoSheet) {
                InformationView(
                    steps: steps,
                    distanceMeters: distanceMeters
                )
            }

            .sheet(isPresented: showNoteSheet) {
                if let note = selectedNote.wrappedValue {
                    NoteDetailSheet(note: note)
                        .environmentObject(tripStore)
                }
            }
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
        // Previewで落ちるなら下を有効化（あなたの環境に合わせて）
        // .environmentObject(TripStore())
        // .environmentObject(AuthStore())
    }
}

