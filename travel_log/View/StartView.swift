//
//  StartView.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2025/11/30.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct StartView: View {

    @StateObject var locationManager = LocationManager()

    @State private var coordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6895468, longitude: 139.7673068),
        latitudinalMeters: 10000,
        longitudinalMeters: 10000
    )

    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var hasCenteredOnce = false

    var body: some View {
        ZStack(alignment: .bottom) {

            // Map（骨子そのまま）
            Map(
                coordinateRegion: $coordinateRegion,
                interactionModes: .all,
                showsUserLocation: true,
                userTrackingMode: $userTrackingMode
            )
            .ignoresSafeArea()
            .onAppear {
                locationManager.requestWhenInUseAuthorization()
                locationManager.startUpdatingLocationIfPossible()
            }
            .onChange(of: locationManager.location) { loc in
                guard let loc else { return }

                // 最初の一回だけ現在地へ寄せる（以降はユーザー操作を邪魔しない）
                if !hasCenteredOnce {
                    hasCenteredOnce = true
                    coordinateRegion = MKCoordinateRegion(
                        center: loc.coordinate,
                        latitudinalMeters: 800,
                        longitudinalMeters: 800
                    )
                }
            }

            // 下部UI（CustomButton + Spacer をZStack内へ）
            VStack(spacing: 12) {
                CustomButton(title: "旅を始める！", action: { print("hello") })
                Spacer(minLength: 80)
            }
            .padding(.bottom, 12)
        }
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
    }
}
