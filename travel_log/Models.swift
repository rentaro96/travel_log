//
//  Models.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/08.
//

import Foundation
import CoreLocation

// MARK: - Note

enum TravelNoteType: String, Codable {
    case photo
    case memo
}

struct TravelNote: Identifiable, Codable, Equatable {
    let id: UUID
    let type: TravelNoteType
    let latitude: Double
    let longitude: Double
    let date: Date

    // ✅ 追加したなら init でも必ず埋める
    let steps: Int
    let distanceMeters: Double

    var text: String?
    var photoFilename: String?

    init(
        type: TravelNoteType,
        latitude: Double,
        longitude: Double,
        date: Date,
        steps: Int = 0,
        distanceMeters: Double = 0,
        text: String? = nil,
        photoFilename: String? = nil,
        id: UUID = UUID()
    ) {
        self.id = id
        self.type = type
        self.latitude = latitude
        self.longitude = longitude
        self.date = date
        self.steps = steps
        self.distanceMeters = distanceMeters
        self.text = text
        self.photoFilename = photoFilename
    }

    var coordinate: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Trip

struct Trip: Identifiable, Codable {
    let id: UUID
    var title: String
    let startedAt: Date
    let endedAt: Date
    // ルートは軽量保存（[[lat, lon], ...]）
    let routeLatLons: [[Double]]

    let notes: [TravelNote]

    // ✅ 旅全体の歩数と距離
    let steps: Int
    let distanceMeters: Double

    init(
        title: String,
        startedAt: Date,
        endedAt: Date,
        route: [CLLocationCoordinate2D],
        notes: [TravelNote],
        steps: Int = 0,
        distanceMeters: Double = 0,
        id: UUID = UUID()
    ) {
        self.id = id
        self.title = title
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.routeLatLons = route.map { [$0.latitude, $0.longitude] }
        self.notes = notes
        self.steps = steps
        self.distanceMeters = distanceMeters
    }

    var route: [CLLocationCoordinate2D] {
        routeLatLons.compactMap { arr in
            guard arr.count == 2 else { return nil }
            return .init(latitude: arr[0], longitude: arr[1])
        }
    }
}
