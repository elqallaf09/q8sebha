import Foundation
import Combine

// ─── رسائل WebSocket الواردة ──────────────────────────────────────────────
struct WSMessage: Decodable {
    let type: String
    let payload: WSPayload?
    struct WSPayload: Decodable {
        let title: String?
        let body:  String?
        let icon:  String?
        let auctionId: Int?
        let amount:    Double?
        let bidderName: String?
        enum CodingKeys: String, CodingKey {
            case title, body, icon, amount
            case auctionId  = "auction_id"
            case bidderName = "bidder_name"
        }
    }
}

// ─── WebSocketService ─────────────────────────────────────────────────────
final class WebSocketService: NSObject, ObservableObject {
    static let shared = WebSocketService()
    private var task: URLSessionWebSocketTask?
    private var pingTimer: Timer?

    // Publishers
    let newBid         = PassthroughSubject<WSMessage, Never>()
    let notification   = PassthroughSubject<WSMessage, Never>()
    let auctionEnded   = PassthroughSubject<Int, Never>() // auctionId

    func connect(userId: Int) {
        guard let url = URL(string: "ws://localhost:3000/ws?user_id=\(userId)") else { return }
        task = URLSession.shared.webSocketTask(with: url)
        task?.resume()
        receive()
        startPing()
    }

    func disconnect() {
        task?.cancel(with: .normalClosure, reason: nil)
        pingTimer?.invalidate()
    }

    private func receive() {
        task?.receive { [weak self] result in
            switch result {
            case .success(let msg):
                if case .string(let text) = msg, let data = text.data(using: .utf8) {
                    if let ws = try? JSONDecoder().decode(WSMessage.self, from: data) {
                        DispatchQueue.main.async { self?.handle(ws) }
                    }
                }
                self?.receive()
            case .failure: break
            }
        }
    }

    private func handle(_ msg: WSMessage) {
        switch msg.type {
        case "notification":     notification.send(msg)
        case "bid_placed":       newBid.send(msg)
        case "auction_ended":
            if let id = msg.payload?.auctionId { auctionEnded.send(id) }
        default: break
        }
    }

    private func startPing() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { [weak self] _ in
            self?.task?.send(.string(#"{"type":"ping"}"#)) { _ in }
        }
    }
}
