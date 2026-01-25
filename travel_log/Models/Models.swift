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

    // ルートはアプリ内では [[lat, lon], ...] で持つ
    let routeLatLons: [[Double]]

    let notes: [TravelNote]
    let steps: Int
    let distanceMeters: Double

    enum CodingKeys: String, CodingKey {
        case id, title, startedAt, endedAt, routeLatLons, notes, steps, distanceMeters
    }

    // ✅ 通常init（あなたの今のままでOK）
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

    // ✅ ここが重要：Firestoreの「フラット配列」でも「二重配列」でも読める
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        startedAt = try c.decode(Date.self, forKey: .startedAt)
        endedAt = try c.decode(Date.self, forKey: .endedAt)
        notes = try c.decode([TravelNote].self, forKey: .notes)
        steps = try c.decode(Int.self, forKey: .steps)
        distanceMeters = try c.decode(Double.self, forKey: .distanceMeters)

        // ① まず [[Double]] を試す（昔の形式）
        if let nested = try? c.decode([[Double]].self, forKey: .routeLatLons) {
            routeLatLons = nested
            return
        }

        // ② ダメなら [Double]（今のFirestore形式）を読み、[[Double]]に戻す
        let flat = (try? c.decode([Double].self, forKey: .routeLatLons)) ?? []
        var rebuilt: [[Double]] = []
        var i = 0
        while i + 1 < flat.count {
            rebuilt.append([flat[i], flat[i + 1]])
            i += 2
        }
        routeLatLons = rebuilt
    }

    var route: [CLLocationCoordinate2D] {
        routeLatLons.compactMap { arr in
            guard arr.count == 2 else { return nil }
            return .init(latitude: arr[0], longitude: arr[1])
        }
    }
}


extension Trip: CustomStringConvertible {
    var description: String {
        """
        Trip(
          title: \(title),
          startedAt: \(startedAt),
          endedAt: \(endedAt),
          steps: \(steps),
          distanceMeters: \(distanceMeters),
          routeCount: \(route.count),
          notesCount: \(notes.count)
        )
        """
    }
}

