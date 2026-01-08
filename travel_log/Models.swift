//
//  Models.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/08.
//

import Foundation
import CoreLocation

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

    // memo用
    var text: String?

    // photo用（アプリ内Documentsに保存したファイル名）
    var photoFilename: String?

    init(type: TravelNoteType,
         latitude: Double,
         longitude: Double,
         date: Date,
         text: String? = nil,
         photoFilename: String? = nil,
         id: UUID = UUID()) {
        self.id = id
        self.type = type
        self.latitude = latitude
        self.longitude = longitude
        self.date = date
        self.text = text
        self.photoFilename = photoFilename
    }

    var coordinate: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }
}

struct Trip: Identifiable, Codable {
    let id: UUID
    var title: String
    let startedAt: Date
    let endedAt: Date

    // ルートは軽量に（Doubleの配列で保存）
    let routeLatLons: [[Double]]   // [[lat, lon], ...]

    let notes: [TravelNote]

    init(title: String,
         startedAt: Date,
         endedAt: Date,
         route: [CLLocationCoordinate2D],
         notes: [TravelNote],
         id: UUID = UUID()) {
        self.id = id
        self.title = title
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.routeLatLons = route.map { [$0.latitude, $0.longitude] }
        self.notes = notes
    }

    var route: [CLLocationCoordinate2D] {
        routeLatLons.compactMap { arr in
            guard arr.count == 2 else { return nil }
            return .init(latitude: arr[0], longitude: arr[1])
        }
    }
}
