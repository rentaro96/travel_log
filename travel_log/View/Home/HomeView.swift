import SwiftUI

struct HomeView: View {

    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var userStore: UserStore

    @State private var showSettings = false
    @Environment(\.horizontalSizeClass) private var hSize

    var body: some View {
        NavigationStack {
            ZStack {
                Color.customBackgroundColor
                    .ignoresSafeArea(edges: [.horizontal])

                ScrollView {
                    VStack(spacing: 30) {
                        Spacer(minLength: 20)


                        Image("tabirogu")
                            .resizable()
                            .scaledToFit()
                           // .frame(maxWidth: 350)   // ✅ iPadでもデカくなりすぎない
                            .padding(.top, 10)

                        CustomButton(title: "使い方！", action: { print("とろろ") })

                        CustomNavButton(
                            title: "友達を追加",
                            destination: FriendAddView(initialFriendCode: "")
                        )

                        CustomButton(title: "設定", action: {
                            showSettings = true
                        })

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 20)
                    // ✅ iPadは中央に「スマホ幅」っぽく寄せる
                    .frame(maxWidth: (hSize == .regular ? 460 : .infinity))
                    .frame(maxWidth: .infinity) // 中央寄せ
                    // ✅ 下のタブバー等に被らないように保険
                    .padding(.bottom, 30)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingView()
                    .environmentObject(authStore)
                    .environmentObject(userStore)
                    .presentationDetents([.medium])
            }
        }
    }
}

#Preview {
    HomeView()
}
