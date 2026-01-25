//
//  travel_logApp.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2025/10/05.
//

import SwiftUI
import FirebaseCore
import SwiftData


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct YourApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authStore = AuthStore()
    
    @StateObject private var tripStore = TripStore()
    
    @StateObject private var userStore = UserStore()
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tripStore)
                .environmentObject(authStore)
                .environmentObject(userStore)
                .task {
                    await authStore.signInIfNeeded()
                }
            
        }
        //.modelContainer(for: [TripRecord.self])
    }
}
