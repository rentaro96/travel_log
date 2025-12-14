import Foundation
import Combine
import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation? = nil
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
//        self.manager.requestWhenInUseAuthorization()
//        self.manager.startUpdatingLocation()
    }
    
    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }
    
    // Optionally handle authorization status updates
    func locationManager(_ manager: CLLocationManager, didUpdateLoactions locations: [CLLocation]) {
        // Handle changes if needed
        if let location = locations.last {
            self.location = location
        }
    }
}
