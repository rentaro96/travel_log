//
//  HistoryMapView.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2025/11/30.
//

import SwiftUI

struct HistoryMapView: View {
    @EnvironmentObject var tripStore: TripStore

    var body: some View {
        List {
            ForEach(tripStore.trips) { trip in
                NavigationLink {
                    TripDetailView(trip: trip)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(trip.title)
                            .font(.headline)

                        Text(
                            "\(trip.startedAt.formatted(date: .abbreviated, time: .shortened)) 〜 \(trip.endedAt.formatted(date: .abbreviated, time: .shortened))"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        Text("ルート: \(trip.route.count)点 / 写真・メモ: \(trip.notes.count)件")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { indexSet in
                Task {
                    for i in indexSet {
                        let trip = tripStore.trips[i]
                        do {
                            try await tripStore.deleteTrip(trip)
                        } catch {
                            print("deleteTrip error:", error)
                        }
                    }
                }
            }
        }
        .navigationTitle("思い出")
    }
}
