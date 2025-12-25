//
//  travel_logApp.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2025/10/05.
//

import SwiftUI
import FirebaseCore


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
    



  var body: some Scene {
    WindowGroup {
        ContentView()
                        .environmentObject(authStore)
                        .task {
                            await authStore.signInIfNeeded()
                        }
      
    }
  }
}
