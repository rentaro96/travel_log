//
//  TripStore.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/08.
//

import Foundation
import UIKit
internal import Combine
import FirebaseFirestore
import FirebaseStorage

@MainActor
final class TripStore: ObservableObject {

    @Published private(set) var trips: [Trip] = []

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private var listener: ListenerRegistration?

    // ✅ AuthStore の uid を使う（外から渡す）
    private var uid: String?

    deinit {
        listener?.remove()
    }

    func setUID(_ uid: String?) {
        self.uid = uid
        // ここで listener 開始してるなら、uidセット後に startListening() とか呼ぶ
    }

    // MARK: - Public

    /// ✅ ログイン後に必ず呼ぶ：Firestoreと接続開始
    func bindUser(uid: String) {
        self.uid = uid

        // 既存listenerがあれば外す
        listener?.remove()

        // users/{uid}/trips を監視（リアルタイム）
        listener = db.collection("users")
          .document(uid)
          .collection("trips")
          .order(by: "startedAt", descending: true)
          .addSnapshotListener { [weak self] snapshot, error in
              guard let self else { return }
              if let error {
                  print("TripStore listen error:", error)
                  return
              }
              guard let snapshot else { return }

              self.trips = snapshot.documents.compactMap { doc in
                  do {
                      return try doc.data(as: Trip.self)
                  } catch {
                      print("❌ decode failed docId=\(doc.documentID):", error)
                      print("📦 raw data:", doc.data())   // これが超重要
                      return nil
                  }
              }
          }
    }
    
    func updateTripVisibility(tripId: UUID, isPublic: Bool) async throws {
        guard let uid else {
            throw NSError(domain: "TripStore", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "uidが未設定"])
        }

        try await db.collection("users")
            .document(uid)
            .collection("trips")
            .document(tripId.uuidString)
            .setData(["isPublic": isPublic], merge: true)
    }


    /// ✅ Firestoreへ追加（終了ボタンで呼ぶ）
    func addTrip(_ trip: Trip) async throws {
        guard let uid else {
            throw NSError(domain: "TripStore", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "uidが未設定"])
        }

        let ref = db.collection("users")
            .document(uid)
            .collection("trips")
            .document(trip.id.uuidString)

        do {
            var dict = try Firestore.Encoder().encode(trip)

            // ✅ 二重配列対策：routeLatLons を Firestore に通る形に変換して上書き
            // - routeLatLons が [[Double]] / [[Any]] になっても落ちないようにする
            if let nested = dict["routeLatLons"] as? [[Double]] {
                dict["routeLatLons"] = nested.flatMap { $0 }   // [Double]
            }
            else if let nested = dict["routeLatLons"] as? [[Double]] {
                let flat = nested.flatMap { $0 }
                dict["routeLatLons"] = flat
            }
            
            print("🔥 encoded trip =", dict)
            try await ref.setData(dict, merge: true)
            print("✅ Firestore保存OK")

            if !self.trips.contains(where: { $0.id == trip.id }) {
                self.trips.insert(trip, at: 0)
            }
        } catch {
            print("❌ encode/setData error:", error)
            throw error
        }
    }

    /// ✅ Firestoreから削除（＋写真も消す）
    func deleteTrip(_ trip: Trip) async throws {
        guard let uid else {
            throw NSError(domain: "TripStore", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "uidが未設定"])
        }

        // 先にStorageの写真削除（photoPathがある前提）
        for note in trip.notes {
            if let path = note.photoFilename {
                try? await deletePhoto(path: path)
            }
        }

        try await db.collection("users")
            .document(uid)
            .collection("trips")
            .document(trip.id.uuidString)
            .delete()
    }

    // MARK: - Photos (Firebase Storage)

    /// ✅ 写真アップロードして path を返す
    func uploadPhotoJPEG(_ data: Data, tripId: UUID, noteId: UUID) async throws -> String {
        guard let uid else {
            throw NSError(domain: "TripStore", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "uidが未設定"])
        }

        let path = "users/\(uid)/photos/\(tripId.uuidString)/\(noteId.uuidString).jpg"
        let ref = storage.reference(withPath: path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        // ✅ アップロードだけする（ここで404は出ない）
        _ = try await ref.putDataAsync(data, metadata: metadata)

        print("✅ uploaded path =", path)
        return path
    }

    func loadPhoto(path: String) async throws -> UIImage? {
        let ref = storage.reference(withPath: path)
        let data = try await ref.data(maxSize: 8 * 1024 * 1024) // 8MB
        return UIImage(data: data)
    }

    private func deletePhoto(path: String) async throws {
        let ref = storage.reference(withPath: path)
        try await ref.delete()
    }
}
