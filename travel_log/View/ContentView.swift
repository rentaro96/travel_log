import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var selectedTab = 1
    @AppStorage("agreedTerms") private var agreedTerms = false
    @State private var showTerms = false

    @State private var didStartAuth = false   // ✅ 起動時の二重実行防止
    let tripStore = TripStore()

    var body: some View {
        Group {
            if !agreedTerms {
                termsGateView
            } else if authStore.isBanned {
                BannedView(reason: authStore.banReason)
            } else if authStore.uid.isEmpty {
                loadingView
            } else {
                mainTabView
            }
        }
        .task {
            // ✅ 利用規約に同意してからログイン（BAN判定もここで走る）
            guard agreedTerms else { return }
            guard !didStartAuth else { return }
            didStartAuth = true

            await authStore.signInIfNeeded()

            // ✅ uid が確定したあとに TripStore に反映
            tripStore.setUID(authStore.uid.isEmpty ? nil : authStore.uid)
        }
        .onChange(of: agreedTerms) { newValue in
            // 同意した瞬間に .task を走らせたいのでフラグをリセット
            if newValue == true {
                didStartAuth = false
            }
        }
    }

    // MARK: - Subviews

    private var termsGateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("利用規約に同意してください")
                .font(.title3)

            Text("本アプリではユーザー投稿機能があります。不適切な内容は禁止されています。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()

            Button("同意して開始") {
                agreedTerms = true
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: 240)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)

            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("利用規約を見る") {
                    showTerms = true
                }
            }
        }
        // もし利用規約のシートを出してるならここで
        // .sheet(isPresented: $showTerms) { TermsView() }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(authStore.status.isEmpty ? "起動中…" : authStore.status)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            StartView()
                .tabItem { Label("", systemImage: "airplane") }
                .tag(0)

            HomeView()
                .tabItem { Label("", systemImage: "house.fill") }
                .tag(1)

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label("", systemImage: "clock.fill") }
            .tag(2)
        }
    }
}

#Preview {
    ContentView()
}
