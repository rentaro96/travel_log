//
//  LocalPhotoStore.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/26.
//

import Foundation
import UIKit

enum LocalPhotoStore {
    static func saveJPEG(_ data: Data, filename: String) throws {
        let url = try fileURL(filename: filename)
        try data.write(to: url, options: .atomic)
    }

    static func loadImage(filename: String) throws -> UIImage? {
        let url = try fileURL(filename: filename)
        let data = try Data(contentsOf: url)
        return UIImage(data: data)
    }

    static func delete(filename: String) throws {
        let url = try fileURL(filename: filename)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    static func fileURL(filename: String) throws -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(filename)
    }
}

