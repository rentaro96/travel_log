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
            .order(by: "startedAt", descending: true)
            .addSnapshotListener { [weak self] snap, error in
                guard let self else { return }
                if let error {
                    print("❌ FriendTrip listen error:", error)
                    return
                }

                self.trips = snap?.documents.compactMap { doc in
                    try? doc.data(as: Trip.self)
                } ?? []
            }
    }
}
