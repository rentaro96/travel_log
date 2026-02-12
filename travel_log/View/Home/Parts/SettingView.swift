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
    @EnvironmentObject var adminMode: AdminMode


    @State private var displayName: String = ""
    @State private var message: String = ""
    @State private var showDemoButton: Bool = false
    @State private var showTerms = false
    @State private var showContact = false

    // 🔐 管理者だけが知っているパスワード（仮）
    private let adminPassword = "ADMIN-96"


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
            
            Button("利用規約") {
                showTerms = true
            }
            Button("お問い合わせ") {
                showContact = true
            }

            if !message.isEmpty {
                Text(message).font(.footnote).foregroundStyle(.secondary)
            }
            // ✅ 正しいパスワードが入力されたら表示
            if showDemoButton {
                Section("管理者") {
                    Button {
                        adminMode.setEnabled(true)
                        message = "デモモードを有効にしました"
                        dismiss()
                    } label: {
                        Label("デモモードを実行", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            
            // ✅ デモモード中だけ表示：解除ボタン
            if adminMode.enabled {
                Section("管理者") {
                    Button(role: .destructive) {
                        adminMode.setEnabled(false)
                        showDemoButton = false
                        message = "デモモードを解除しました"
                        dismiss()
                    } label: {
                        Label("デモモードを解除", systemImage: "xmark.seal")
                    }
                }
            }


        }
        .onAppear {
            // 既存の表示名を初期表示したい場合は、authStoreに持たせる or users/{uid} を読んで入れる
            
        }
        
        .sheet(isPresented: $showTerms) {
            SafariView(url: URL(string: "https://www.notion.so/12be9fd05ecc8080b8b8e8a99c3a0886?source=copy_link")!)
        }
        
        .sheet(isPresented: $showContact) {
            SafariView(url: URL(string: "https://forms.gle/pwWTLvx4DKGJdw7o7")!)
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
                .onChange(of: displayName) { newValue in
                    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    showDemoButton = (trimmed == adminPassword)
                }


    }
}


#Preview {
    SettingView()
}
