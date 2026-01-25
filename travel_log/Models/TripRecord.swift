//
//  File.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/15.
//

import Foundation
import SwiftData

@Model
final class TripRecord {
    var id: String
    var startedAt: Date
    var endedAt: Date
    var title: String

    @Attribute(.externalStorage)
    var tripJSON: Data

    init(trip: Trip) throws {
        self.id = trip.id.uuidString
        self.startedAt = trip.startedAt
        self.endedAt = trip.endedAt
        self.title = trip.title
        self.tripJSON = try JSONEncoder().encode(trip)
    }

    func trip() throws -> Trip {
        try JSONDecoder().decode(Trip.self, from: tripJSON)
    }
}
