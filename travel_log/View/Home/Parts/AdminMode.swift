//
//  AdminMode.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/02/02.
//

import Foundation
internal import Combine

@MainActor
final class AdminMode: ObservableObject {
    @Published var enabled: Bool

    private let key = "adminModeEnabled"

    init() {
        self.enabled = UserDefaults.standard.bool(forKey: key)
    }

    func setEnabled(_ value: Bool) {
        enabled = value
        UserDefaults.standard.set(value, forKey: key)
    }
}

