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

struct StartView: View {
    @StateObject var locationManager = LocationManager()
    @State private var pedometer: CMPedometer? = CMPedometer()

    @State private var isRunning = false
    @State private var isPaused  = false
    @State private var showActionButtons = false

    // Map camera
    @State private var position: MapCameraPosition = .automatic
    @State private var hasCenteredOnce = false
    @State private var isFollowingUser = true

    // Sheets
    @State private var showInfoSheet = false

    var body: some View {
        VStack(spacing: 12) {

            // ====== Map + Overlay ======
            ZStack {
                // ✅ Map（中には地図に描くものだけ）
                Map(position: $position, interactionModes: .all) {
                    UserAnnotation()

                    if locationManager.route.count >= 2 {
                        MapPolyline(coordinates: locationManager.route)
                            .stroke(.blue, lineWidth: 8)
                    }
                }
                .mapControls {
                    MapCompass()
                    MapScaleView()
                    // MapUserLocationButton() は標準の追従を変えるので、
                    // 今回の「記録中のみ追従」挙動と競合しやすい。
                    // 使いたいなら入れてOKだけど、まずは外して安定させる。
                    // MapUserLocationButton()
                }
                .ignoresSafeArea()

                // ✅ ユーザーが地図を触ったら追従OFF（記録中だけ）
                .onMapCameraChange { _ in
                    if locationManager.isRecording {
                        isFollowingUser = false
                    }
                }

                // ✅ 位置更新：初回センタリング + 記録中&追従ONで追いかける
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

                // ✅ 現在地に戻るボタン（Mapの上に重ねる）
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
                            isFollowingUser = true  // ついでに追従も復帰（好み）
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

                    pedometer?.startUpdates(from: Date()) { data, error in
                        if let steps = data?.numberOfSteps {
                            print("steps:", steps)
                        }
                    }

                    locationManager.startRecording(reset: true)

                    // ✅ 記録開始したら追従ONに戻す（旅中は迷子になりにくい）
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
                                  action: { print("camera tapped") },
                                  imagename: "camera.fill")
                    Spacer()
                    CustomButton2(title: "書き残す",
                                  action: { print("memo tapped") },
                                  imagename: "text.bubble")
                    Spacer()
                    CustomButton2(title: "情報",
                                  action: { showInfoSheet = true },
                                  imagename: "info.circle")
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
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
    }
}
