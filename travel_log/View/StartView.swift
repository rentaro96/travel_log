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
    @State private var locationManager = CLLocationManager()//デバイスの位置情報や方向を管理するクラス
        @State private var coordinateRegion = MKCoordinateRegion(//地図の表示領域を指定するための状態変数
            center: CLLocationCoordinate2D(
                latitude: 35.6809591,
                longitude: 139.7673068
            ), //東京の座標
            latitudinalMeters: 10000, //表示範囲。緯度10km
            longitudinalMeters: 10000 //表示範囲。経度10km
        )
        @State private var userTrackingMode: MapUserTrackingMode = .follow
    
    var body: some View {
        ZStack {
            VStack {
                Color.clear
                
                Map( //Mapビュー
                            coordinateRegion: $coordinateRegion, //MKCoordinateRegionの状態を指定（必須）
                            interactionModes: .all, //パンとズームの許可
                            showsUserLocation: true, //現在位置の表示
                            userTrackingMode: $userTrackingMode //現在位置を追跡
                        )
                        .edgesIgnoringSafeArea(.all) //セーフエリアを除外
                        .onAppear{
                            locationManager.requestWhenInUseAuthorization() //位置情報を使用する許可を求める為に使用
                            locationManager.startUpdatingLocation() //デバイスの現在位置の更新を開始するために使用
                        }
                    }
                }

                CustomButton(title: "旅を始める！", action: { print("hello") })
                Spacer(minLength: 80)
            }
        }
struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
