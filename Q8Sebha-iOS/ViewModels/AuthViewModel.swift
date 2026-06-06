import Foundation
import SwiftUI

enum AppState { case splash, auth, main, guest }

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var appState: AppState = .splash
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIService.shared
    private let ws  = WebSocketService.shared

    init() { Task { await checkSession() } }

    // ─── فحص الجلسة عند فتح التطبيق ──────────────────────────────────────
    func checkSession() async {
        try? await Task.sleep(nanoseconds: 1_500_000_000) // Splash 1.5s
        guard TokenStore.access != nil else { appState = .auth; return }
        do {
            let r = try await api.me()
            if let u = r.data {
                currentUser = u
                ws.connect(userId: u.id)
                appState = .main
            } else { appState = .auth }
        } catch { appState = .auth }
    }

    // ─── تسجيل الدخول ────────────────────────────────────────────────────
    func login(phone: String, password: String) async {
        isLoading = true; errorMessage = nil
        do {
            let r = try await api.login(phone: phone, password: password)
            guard let d = r.data else { errorMessage = r.message ?? "خطأ"; isLoading = false; return }
            TokenStore.access  = d.accessToken
            TokenStore.refresh = d.refreshToken
            currentUser        = d.user
            ws.connect(userId: d.user.id)
            appState = .main
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    // ─── إنشاء حساب ──────────────────────────────────────────────────────
    func register(name: String, phone: String, password: String, email: String?) async {
        isLoading = true; errorMessage = nil
        do {
            let r = try await api.register(name: name, phone: phone, password: password, email: email)
            guard let d = r.data else { errorMessage = r.message ?? "خطأ"; isLoading = false; return }
            TokenStore.access  = d.accessToken
            TokenStore.refresh = d.refreshToken
            currentUser        = d.user
            ws.connect(userId: d.user.id)
            appState = .main
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    // ─── دخول كضيف ───────────────────────────────────────────────────────
    func continueAsGuest() {
        currentUser = nil
        appState    = .guest
    }

    // ─── تسجيل الخروج ────────────────────────────────────────────────────
    func logout() {
        Task { await api.logout() }
        ws.disconnect()
        currentUser = nil
        appState    = .auth
    }

    var isAdmin: Bool   { currentUser?.role == "admin" }
    var isGuest: Bool   { appState == .guest }
    var isLoggedIn: Bool { currentUser != nil }
}
