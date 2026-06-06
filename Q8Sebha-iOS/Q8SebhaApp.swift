import SwiftUI

@main
struct Q8SebhaApp: App {
    @StateObject private var authVM   = AuthViewModel()
    @StateObject private var cartVM   = CartViewModel()

    init() {
        // عربي من اليمين لليسار
        UIView.appearance().semanticContentAttribute = .forceRightToLeft
        UITextField.appearance().textAlignment = .right
        UITextView.appearance().textAlignment  = .right

        // شريط التنقل
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor          = UIColor(named: "PrimaryColor") ?? .systemGreen
        nav.titleTextAttributes      = [.foregroundColor: UIColor.white, .font: UIFont(name: "Tajawal-Bold", size: 18)!]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance   = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav

        // شريط التبويب
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().standardAppearance   = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
                .environmentObject(cartVM)
                .environment(\.layoutDirection, .rightToLeft)
        }
    }
}

// ─── RootView: التوجيه بين الشاشات ───────────────────────────────────────
struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            switch authVM.appState {
            case .splash:   SplashView()
            case .auth:     AuthFlowView()
            case .main:     MainTabView()
            case .guest:    MainTabView()
            }
        }
        .animation(.easeInOut, value: authVM.appState)
    }
}
