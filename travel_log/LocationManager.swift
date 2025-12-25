import Foundation
import CoreLocation
internal import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var locationServicesEnabled: Bool = CLLocationManager.locationServicesEnabled()
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var location: CLLocation?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10 // 10m動いたら更新
        refreshStatus()
    }

    func refreshStatus() {
        locationServicesEnabled = CLLocationManager.locationServicesEnabled()
        authorizationStatus = manager.authorizationStatus
    }

    /// 権限が未決定ならダイアログを出す。拒否なら何もしない（設定へ誘導はView側で行う）。
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

    /// 許可があるときだけ更新開始
    func startUpdatingLocationIfPossible() {
        refreshStatus()

        guard locationServicesEnabled else { return }

        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .notDetermined:
            // まず権限要求
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // 設定での許可が必要
            break
        @unknown default:
            break
        }
    }

    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }

    // iOS 14+
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        // 許可された瞬間に更新開始
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        location = latest
        lastErrorMessage = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastErrorMessage = error.localizedDescription
    }
}

