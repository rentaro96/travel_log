//
//  Report.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/26.
//

import Foundation

enum ReportReason: String, CaseIterable, Identifiable {
    case spam
    case abuse
    case impersonation
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spam: return "スパム"
        case .abuse: return "迷惑行為"
        case .impersonation: return "なりすまし"
        case .other: return "その他"
        }
    }
}

