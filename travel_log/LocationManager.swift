import Foundation
import CoreLocation
internal import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var locationServicesEnabled: Bool = CLLocationManager.locationServicesEnabled()
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var location: CLLocation?

    // 記録状態とルート
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var route: [CLLocationCoordinate2D] = []

    // 旅中に追加する写真/メモ（Models.swift の TravelNote を使う）
    @Published var notes: [TravelNote] = []

    private let manager = CLLocationManager()
    private var lastRecordedLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self

        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10 // 10m動いたら更新（必要なら調整）

        // バックグラウンド記録を本気でやるなら後でON（※注意あり）
        // manager.allowsBackgroundLocationUpdates = true
        // manager.pausesLocationUpdatesAutomatically = false
        // manager.activityType = .fitness

        refreshStatus()
    }

    // MARK: - Notes (photo/memo)

    /// メモを現在地に紐付けて追加
    func saveMemo(_ text: String) {
        guard let loc = location else { return }
        notes.append(
            TravelNote(type: .memo,
                       latitude: loc.coordinate.latitude,
                       longitude: loc.coordinate.longitude,
                       date: Date(),
                       text: text,
                       photoFilename: nil)
        )
    }

    /// 写真ファイル名（TripStoreで保存したやつ）を現在地に紐付けて追加
    func addPhotoFilenameNote(_ filename: String) {
        guard let loc = location else { return }
        notes.append(
            TravelNote(type: .photo,
                       latitude: loc.coordinate.latitude,
                       longitude: loc.coordinate.longitude,
                       date: Date(),
                       text: nil,
                       photoFilename: filename)
        )
    }

    // MARK: - Authorization / Updates

    func refreshStatus() {
        locationServicesEnabled = CLLocationManager.locationServicesEnabled()
        authorizationStatus = manager.authorizationStatus
    }

    func requestWhenInUseAuthorization() {
        refreshStatus()

        guard locationServicesEnabled else {
            lastErrorMessage = "端末の「位置情報サービス」がOFFです。設定でONにしてください。"
            return
        }

        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func startUpdatingLocationIfPossible() {
        refreshStatus()
        guard locationServicesEnabled else { return }

        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }

    // MARK: - Recording

    func startRecording(reset: Bool = true) {
        if reset {
            route.removeAll()
            lastRecordedLocation = nil
            notes.removeAll()
        }
        isRecording = true
        startUpdatingLocationIfPossible()
    }

    func pauseRecording() {
        isRecording = false
    }

    func resumeRecording() {
        isRecording = true
        startUpdatingLocationIfPossible()
    }

    func stopRecording() -> [CLLocationCoordinate2D] {
        isRecording = false
        stopUpdatingLocation()
        return route
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        location = latest
        lastErrorMessage = nil

        guard isRecording else { return }

        // 追加フィルタ（distanceFilterの補強）
        if let last = lastRecordedLocation {
            let d = latest.distance(from: last)
            if d < 5 { return }   // 5m未満は無視（好みで調整）
        }

        route.append(latest.coordinate)
        lastRecordedLocation = latest
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastErrorMessage = error.localizedDescription
    }

    // MARK: - Always Authorization (必要なら)

    /// Alwaysにしたい場合に使う（Info.plistと設定が必要）
    func requestAlwaysAuthorizationIfNeeded() {
        refreshStatus()
        guard locationServicesEnabled else { return }

        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        case .authorizedAlways:
            break
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }
}
