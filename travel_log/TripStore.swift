//
//  TripStore.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/08.
//

import Foundation
import UIKit
internal import Combine

@MainActor
final class TripStore: ObservableObject {
    // Removed: var objectWillChange: ObservableObjectPublisher

    // 🔴 これが無いと全部壊れる
    @Published private(set) var trips: [Trip] = []

    private let tripsFilename = "trips.json"
    private let photosFolder = "TripPhotos"

    // MARK: - Init
    init() {
        load()
    }

    // MARK: - Public API

    func addTrip(_ trip: Trip) {
        trips.insert(trip, at: 0)
        save()
    }

    func deleteTrip(_ trip: Trip) {
        for note in trip.notes {
            if let filename = note.photoFilename {
                try? deletePhoto(filename: filename)
            }
        }
        trips.removeAll { $0.id == trip.id }
        save()
    }

    func savePhotoJPEG(_ data: Data) throws -> String {
        let folderURL = try photosFolderURL()
        let filename = UUID().uuidString + ".jpg"
        let url = folderURL.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return filename
    }

    func loadPhoto(filename: String) -> UIImage? {
        let url = try? photosFolderURL().appendingPathComponent(filename)
        guard let path = url?.path else { return nil }
        return UIImage(contentsOfFile: path)
    }

    // MARK: - Persistence

    private func tripsFileURL() throws -> URL {
        let docs = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return docs.appendingPathComponent(tripsFilename)
    }

    private func photosFolderURL() throws -> URL {
        let docs = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folder = docs.appendingPathComponent(photosFolder, isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try FileManager.default.createDirectory(
                at: folder,
                withIntermediateDirectories: true
            )
        }
        return folder
    }

    private func deletePhoto(filename: String) throws {
        let url = try photosFolderURL().appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    private func save() {
        do {
            let url = try tripsFileURL()
            let data = try JSONEncoder().encode(trips)
            try data.write(to: url, options: .atomic)
        } catch {
            print("TripStore save error:", error)
        }
    }

    private func load() {
        do {
            let url = try tripsFileURL()
            guard FileManager.default.fileExists(atPath: url.path) else {
                trips = []
                return
            }
            let data = try Data(contentsOf: url)
            trips = try JSONDecoder().decode([Trip].self, from: data)
        } catch {
            print("TripStore load error:", error)
            trips = []
        }
    }
}
