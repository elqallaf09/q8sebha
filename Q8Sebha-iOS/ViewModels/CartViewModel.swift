import Foundation

@MainActor
final class CartViewModel: ObservableObject {
    @Published var notificationsCount = 0

    private let api = APIService.shared
    private let ws  = WebSocketService.shared

    init() {
        ws.notification.sink { [weak self] _ in
            self?.notificationsCount += 1
        }.receive(on: DispatchQueue.main).assign(to: nil)
        Task { await refreshBadge() }
    }

    func refreshBadge() async {
        do {
            let r = try await api.notifications()
            notificationsCount = r.meta?.unread ?? 0
        } catch {}
    }
}
