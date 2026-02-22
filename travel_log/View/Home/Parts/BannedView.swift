import SwiftUI

struct BannedView: View {
    @EnvironmentObject var authStore: AuthStore

    let reason: String
    @State private var showContact = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Text("このアカウントは利用停止されています")
                .font(.title3)
                .bold()

            // ✅ フレンドコード表示
            if !authStore.friendCode.isEmpty {
                VStack(spacing: 6) {
                    Text("フレンドコード")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(authStore.friendCode)
                        .font(.title2)
                        .monospaced()
                        .bold()

                    Button("コピー") {
                        UIPasteboard.general.string = authStore.friendCode
                    }
                    .font(.footnote)
                }
                .padding(.top, 6)
            }

            if !reason.isEmpty {
                Text("理由: \(reason)")
                    .foregroundStyle(.secondary)
            }

            Button("お問い合わせフォームを開く") {
                showContact = true
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: 260)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(14)

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showContact) {
            SafariView(url: URL(string: "https://forms.gle/pwWTLvx4DKGJdw7o7")!)
        }
    }
}
