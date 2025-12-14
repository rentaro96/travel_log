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
import CoreMotion

struct StartView: View {
    @StateObject var locationManager = LocationManager()
    @State private var pedometer: CMPedometer? = CMPedometer()
    @State private var isRunning = false
    @State private var isPaused  = false   // 起動時は false
    @State private var steps: Int = 0
    @State private var baselineSteps: Int = 0

    @State private var coordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6895468, longitude: 139.7673068),
        latitudinalMeters: 10000,
        longitudinalMeters: 10000
    )

    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var hasCenteredOnce = false
    

    var body: some View {
        VStack(spacing: 12) {
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
            }
            
            
            if isRunning {
                HStack(spacing: 20) {
                    CustomButton3(title: "終了") {
                        pedometer?.stopUpdates()
                        isRunning = false
                        isPaused = false
                    }
                    
                    if isPaused {
                        CustomButton3(title: "再開") {
                            guard CMPedometer.isStepCountingAvailable() else { return }
                            
                            pedometer?.startUpdates(from: Date()) { data, error in
                                if let steps = data?.numberOfSteps {
                                    print("steps:", steps)
                                }
                            }
                            
                            isPaused = false
                        }
                    } else {
                        CustomButton3(title: "停止") {
                            pedometer?.stopUpdates()
                            isPaused = true
                        }
                    }
                }
                
            } else {
                // 旅を始める
                CustomButton(title: "旅を始める！") {
                    guard CMPedometer.isStepCountingAvailable() else { return }
                    
                    pedometer?.startUpdates(from: Date()) { data, error in
                        if let steps = data?.numberOfSteps {
                            print("steps:", steps)
                        }
                    }
                    
                    isRunning = true
                    isPaused = false  // ← 念のため初期化
                }
            }
            
            
            
            
            HStack{
                Spacer()
                CustomButton2(title:"写真を残す",action:{print("hello")}, imagename:"camera.fill")
                Spacer()
                CustomButton2(title:"書き残す",action:{print("hello")}, imagename:"text.bubble")
                Spacer()
                CustomButton2(title:"情報",action:{print("hello")}, imagename:"info.circle")
                Spacer()
            }
            Spacer(minLength:100)
            
        }
        .background(Color.customBackgroundColor)
        .ignoresSafeArea()
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
    }
}
