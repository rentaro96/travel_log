//
//  SettingView.swift
//  travel_log
//
//  Created by 鈴木廉太郎 on 2025/11/30.
//

import SwiftUI

struct SettingView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var userStore: UserStore
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var message: String = ""

    var body: some View {
        Form {
            Section("表示名") {
                TextField("例：たかし", text: $displayName)

                Button("保存") {
                    Task {
                        do {
                            try await userStore.updateDisplayName(
                                myUid: authStore.uid,
                                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                            message = "保存しました"
                        } catch {
                            message = "保存失敗: \(error.localizedDescription)"
                        }
                    }
                }
            }

            if !message.isEmpty {
                Text(message).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .onAppear {
            // 既存の表示名を初期表示したい場合は、authStoreに持たせる or users/{uid} を読んで入れる
            
        }
        .scrollContentBackground(.hidden)   // Formの半透明を消す
                .navigationTitle("設定")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("閉じる") {
                            dismiss()
                        }
                    }
                }

    }
}


#Preview {
    SettingView()
}
