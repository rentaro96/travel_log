import Foundation
import CoreLocation
internal import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var locationServicesEnabled: Bool = CLLocationManager.locationServicesEnabled()
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var location: CLLocation?

    // 追加：記録状態とルート
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var route: [CLLocationCoordinate2D] = []

    private let manager = CLLocationManager()
    private var lastRecordedLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10 // 10m動いたら更新
        
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.activityType = .fitness
        
        refreshStatus()
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

    // 追加：記録の開始/停止
    func startRecording(reset: Bool = true) {
        print("startRecording called")
        if reset {
            route.removeAll()
            lastRecordedLocation = nil
        }
        isRecording = true
        startUpdatingLocationIfPossible()
    }
    func pauseRecording() {
        // ルートは残したまま、記録だけ止める
        isRecording = false
    }

    func resumeRecording() {
        // 途中から続きとして記録再開（resetしない）
        isRecording = true
        startUpdatingLocationIfPossible()
    }
    func stopRecording() -> [CLLocationCoordinate2D] {
        isRecording = false
        stopUpdatingLocation()
        return route
    }

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

        // ここが重要：記録中だけルートに追加
        guard isRecording else { return }

        // 連続で同じ点が入りすぎないようにガード（距離フィルタ補強）
        if let last = lastRecordedLocation {
            let d = latest.distance(from: last)
            if d < 5 { return } // 5m未満は無視（好みで調整）
        }

        route.append(latest.coordinate)
        lastRecordedLocation = latest
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastErrorMessage = error.localizedDescription
    }

    func refreshStatus() {
        locationServicesEnabled = CLLocationManager.locationServicesEnabled()
        authorizationStatus = manager.authorizationStatus
    }

    func requestAlwaysAuthorizationIfNeeded() {
        refreshStatus()

        guard locationServicesEnabled else { return }

        switch authorizationStatus {
        case .notDetermined:
            // まず使用中の許可を取る（いきなりAlwaysは出せない）
            manager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse:
            // 使用中が許可された後に、Alwaysを要求
            manager.requestAlwaysAuthorization()

        case .authorizedAlways:
            // すでにOK、何もしない
            break

        case .denied, .restricted:
            break

        @unknown default:
            break
        }
    }
}
