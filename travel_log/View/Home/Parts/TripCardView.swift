//
//  TripCardView.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/25.
//

import SwiftUI

struct TripCardView: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text(trip.title)
                .font(.headline)

            HStack {
                Text(trip.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(trip.distanceMeters))m")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("📍 \(trip.route.count)地点 / 👣 \(trip.steps)歩")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
                .shadow(radius: 3)
        )
        .padding(.horizontal)
    }
}

