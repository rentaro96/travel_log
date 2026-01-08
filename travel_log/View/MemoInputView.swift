//
//  MemoInputView.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2026/01/08.
//

import SwiftUI

struct MemoInputView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    let onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextEditor(text: $text)
                    .frame(height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.gray)
                    )

                Button("保存") {
                    onSave(text)
                    dismiss()
                }
                .disabled(text.isEmpty)

                Spacer()
            }
            .padding()
            .navigationTitle("この場所でのメモ")
        }
    }
}
