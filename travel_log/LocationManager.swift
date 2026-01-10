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
    
    @Published private(set) var isAutoPaused: Bool = false

    // 旅中に追加する写真/メモ（Models.swift の TravelNote を使う）
    @Published var notes: [TravelNote] = []

    private let manager = CLLocationManager()
    private var lastRecordedLocation: CLLocation?
    
    private let stationarySeconds: TimeInterval = 90        // 例：1分
    private let stationaryRadiusMeters: Double = 10         // 例：12m以内なら「同じ場所」

    /// 「動き出した」とみなして再開する閾値
    private let resumeDistanceMeters: Double = 11           // 例：18m以上離れたら再開（半径より少し大きめ）

    /// 直近の位置履歴（時間窓で使う）
    private var recentLocations: [CLLocation] = []

    override init() {
        super.init()
        manager.delegate = self

        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5 // 5m動いたら更新（必要なら調整）

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
        print("startRecording called")
        if reset {
            route.removeAll()
            lastRecordedLocation = nil
            notes.removeAll() // 必要なら
        }
        recentLocations.removeAll()
        isAutoPaused = false

        isRecording = true
        startUpdatingLocationIfPossible()
    }

    func pauseRecording() {
        isRecording = false
        isAutoPaused = false
        recentLocations.removeAll()
    }

    func resumeRecording() {
        isRecording = true
        isAutoPaused = false
        recentLocations.removeAll()
        startUpdatingLocationIfPossible()
    }

    func stopRecording() -> [CLLocationCoordinate2D] {
        isRecording = false
        isAutoPaused = false
        recentLocations.removeAll()
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

        // 記録してない時はルート処理しない
        guard isRecording else { return }

        // ===== 外れ値フィルタ（前に話したやつ）=====
        if latest.horizontalAccuracy < 0 || latest.horizontalAccuracy > 35 { return }

        // ===== 自動停止/再開 判定用に「直近履歴」を更新 =====
        recentLocations.append(latest)

        // 古い履歴を捨てる（stationarySeconds より前は捨てる）
        let cutoff = Date().addingTimeInterval(-stationarySeconds)
        recentLocations.removeAll { $0.timestamp < cutoff }

        // 履歴が少なすぎるなら判定しない（開始直後）
        if recentLocations.count >= 3 {
            // 直近窓の中で「中心っぽい点」を基準に半径を見る
            // 一番シンプルに「最初の点」を基準にする（十分強い）
            let base = recentLocations.first!

            // base からの最大距離
            let maxD = recentLocations.map { $0.distance(from: base) }.max() ?? 0

            // ✅ 1分間ずっと半径12m以内なら「止まってる」→ 自動停止
            let windowSpan = (recentLocations.last!.timestamp.timeIntervalSince(recentLocations.first!.timestamp))
            let isStationaryWindow = windowSpan >= stationarySeconds && maxD <= stationaryRadiusMeters

            if isStationaryWindow {
                isAutoPaused = true
            } else {
                // ✅ 止まってた状態から、十分動いたら復帰
                if isAutoPaused {
                    let movedFromBase = latest.distance(from: base)
                    if movedFromBase >= resumeDistanceMeters {
                        isAutoPaused = false
                        recentLocations.removeAll() // 再開時は窓をリセット（判定が早くなる）
                        recentLocations.append(latest)
                    }
                }
            }
        }

        // ===== 自動停止中なら「ルート追加しない」=====
        if isAutoPaused { return }

        // ===== ここから下は、ルート追加 =====
        if let last = lastRecordedLocation {
            let d = latest.distance(from: last)
            if d < 5 { return }       // 揺れ対策
            if d > 80 { return }      // ワープ対策（必要なら）
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
