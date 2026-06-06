import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var cartVM: CartViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // 1 - المسابيح والمنتجات
            ProductsHomeView()
                .tabItem { Label("المنتجات", systemImage: "bag.fill") }
                .tag(0)

            // 2 - المزاد
            AuctionListView()
                .tabItem { Label("المزاد", systemImage: "hammer.fill") }
                .tag(1)

            // 3 - الإشعارات
            NotificationsView()
                .tabItem {
                    ZStack {
                        Label("الإشعارات", systemImage: "bell.fill")
                        if cartVM.notificationsCount > 0 {
                            Badge(count: cartVM.notificationsCount)
                        }
                    }
                }
                .tag(2)

            // 4 - الملف الشخصي
            ProfileView()
                .tabItem { Label("حسابي", systemImage: "person.fill") }
                .tag(3)
        }
        .accentColor(Color("Primary"))
        .environment(\.layoutDirection, .rightToLeft)
    }
}

struct Badge: View {
    let count: Int
    var body: some View {
        Text("\(min(count,99))")
            .font(.system(size:9,weight:.bold)).foregroundColor(.white)
            .padding(3).background(Color.red).clipShape(Circle())
            .offset(x:9, y:-9)
    }
}
