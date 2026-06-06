import Foundation
import Combine

@MainActor
final class AuctionViewModel: ObservableObject {
    @Published var auctions: [Auction] = []
    @Published var selectedAuction: Auction?
    @Published var bids: [Bid] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var bidSuccess = false

    private let api = APIService.shared
    private let ws  = WebSocketService.shared
    private var cancellables = Set<AnyCancellable>()

    init() { subscribeWS() }

    // ─── جلب المزادات ─────────────────────────────────────────────────────
    func fetchAuctions(status: String? = "active") async {
        isLoading = true
        do {
            let r = try await api.auctions(status: status)
            auctions = r.data
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    // ─── تفاصيل مزاد ──────────────────────────────────────────────────────
    func fetchAuction(_ id: Int) async {
        isLoading = true
        do {
            let r = try await api.auction(id)
            selectedAuction = r.data?.auction
            bids            = r.data?.bids ?? []
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    // ─── المزايدة ─────────────────────────────────────────────────────────
    func placeBid(auctionId: Int, amount: Double) async {
        isLoading = true; errorMessage = nil; bidSuccess = false
        do {
            let r = try await api.placeBid(auctionId: auctionId, amount: amount)
            if let result = r.data {
                bids.insert(result.bid, at: 0)
                // تحديث المزاد
                if let idx = auctions.firstIndex(where: { $0.id == auctionId }) {
                    auctions[idx] = result.auction
                }
                selectedAuction = result.auction
                bidSuccess = true
            } else {
                errorMessage = r.message ?? "فشلت المزايدة"
            }
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    // ─── إرسال رابط الدفع (بائع) ──────────────────────────────────────────
    func sendPaymentLink(auctionId: Int, link: String) async -> Bool {
        do {
            let r = try await api.sendPaymentLink(auctionId: auctionId, link: link)
            return r.success
        } catch { return false }
    }

    // ─── الإبلاغ عن عدم الدفع ─────────────────────────────────────────────
    func reportNonPayment(auctionId: Int) async -> Bool {
        do {
            let r = try await api.reportNonPayment(auctionId: auctionId)
            return r.success
        } catch { return false }
    }

    // ─── WebSocket Live Updates ────────────────────────────────────────────
    private func subscribeWS() {
        ws.newBid.sink { [weak self] msg in
            guard let self, let id = msg.payload?.auctionId, let amount = msg.payload?.amount else { return }
            if let idx = auctions.firstIndex(where: { $0.id == id }) {
                auctions[idx].currentPrice = amount
                auctions[idx].bidsCount   += 1
            }
            if selectedAuction?.id == id { selectedAuction?.currentPrice = amount }
        }.store(in: &cancellables)

        ws.auctionEnded.sink { [weak self] id in
            guard let self else { return }
            if let idx = auctions.firstIndex(where: { $0.id == id }) {
                auctions[idx].status = .ended
            }
            Task { await self.fetchAuctions() }
        }.store(in: &cancellables)
    }

    // ─── عداد تنازلي ──────────────────────────────────────────────────────
    func countdownString(for auction: Auction) -> String {
        let secs = Int(auction.timeRemaining)
        if secs <= 0 { return "انتهى" }
        let h = secs / 3600, m = (secs % 3600) / 60, s = secs % 60
        if h > 0 { return String(format: "%02d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}
