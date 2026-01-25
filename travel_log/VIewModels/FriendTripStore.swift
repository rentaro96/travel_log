//
//  FriendTripStore.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/25.
//

import Foundation
import FirebaseFirestore
internal import Combine
import SwiftUI
import FirebaseStorage

@MainActor
final class FriendTripStore: ObservableObject {

    @Published private(set) var trips: [Trip] = []

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private let storage = Storage.storage()

    deinit { listener?.remove() }
    
    func loadPhoto(path: String) async throws -> UIImage? {
            let ref = storage.reference(withPath: path)
            let data = try await ref.data(maxSize: 8 * 1024 * 1024)
            return UIImage(data: data)
        }

    func bind(friendUid: String) {
        listener?.remove()

        listener = db.collection("users")
            .document(friendUid)
            .collection("trips")
            .whereField("isPublic", isEqualTo: true)
            .addSnapshotListener { [weak self] snap, error in
                guard let self else { return }
                if let error {
                    print("❌ FriendTrip listen error:", error)
                    return
                }

                let trips = snap?.documents.compactMap { try? $0.data(as: Trip.self) } ?? []
                self.trips = trips.sorted { $0.startedAt > $1.startedAt } // ✅ 端末で並べ替え
            }

    }
}
