import Foundation

// ─── مفاتيح التخزين المحلي ────────────────────────────────────────────────
enum TokenStore {
    static let accessKey  = "q8s_access_token"
    static let refreshKey = "q8s_refresh_token"
    static var access: String?  {
        get { UserDefaults.standard.string(forKey: accessKey) }
        set { UserDefaults.standard.set(newValue, forKey: accessKey) }
    }
    static var refresh: String? {
        get { UserDefaults.standard.string(forKey: refreshKey) }
        set { UserDefaults.standard.set(newValue, forKey: refreshKey) }
    }
    static func clear() { access = nil; refresh = nil }
}

// ─── Errors ───────────────────────────────────────────────────────────────
enum APIError: LocalizedError {
    case invalidURL, noData
    case serverError(String)
    case unauthorized
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:         return "رابط غير صحيح"
        case .noData:             return "لا توجد بيانات"
        case .serverError(let m): return m
        case .unauthorized:       return "انتهت جلستك، سجّل دخولك مجدداً"
        case .decodingError(let e): return "خطأ في البيانات: \(e.localizedDescription)"
        }
    }
}

// ─── APIService ───────────────────────────────────────────────────────────
final class APIService {
    static let shared = APIService()
    private init() {}

    // غيّر هذا للـ IP الخاص بك عند التطوير
    let baseURL = "http://localhost:3000/api"

    // ─── Generic Request ──────────────────────────────────────────────────
    func request<T: Codable>(
        _ method:  String = "GET",
        path:      String,
        body:      [String: Any]? = nil,
        auth:      Bool = true
    ) async throws -> T {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }

        var req         = URLRequest(url: url, timeoutInterval: 20)
        req.httpMethod  = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if auth, let token = TokenStore.access {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await URLSession.shared.data(for: req)

        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            // حاول تجديد التوكن
            if let refreshed: T = try? await refreshAndRetry(req: req) { return refreshed }
            throw APIError.unauthorized
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // ─── Refresh Token ────────────────────────────────────────────────────
    private func refreshAndRetry<T: Codable>(req: URLRequest) async throws -> T {
        guard let rt = TokenStore.refresh else { throw APIError.unauthorized }
        guard let url = URL(string: baseURL + "/auth/refresh") else { throw APIError.invalidURL }

        var rReq = URLRequest(url: url)
        rReq.httpMethod = "POST"
        rReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        rReq.httpBody = try JSONSerialization.data(withJSONObject: ["refresh_token": rt])

        let (data, _) = try await URLSession.shared.data(for: rReq)
        let auth = try JSONDecoder().decode(AuthResponse.self, from: data)
        guard let d = auth.data else { throw APIError.unauthorized }

        TokenStore.access  = d.accessToken
        TokenStore.refresh = d.refreshToken

        var retried = req
        retried.setValue("Bearer \(d.accessToken)", forHTTPHeaderField: "Authorization")
        let (data2, _) = try await URLSession.shared.data(for: retried)
        return try JSONDecoder().decode(T.self, from: data2)
    }

    // ─── Auth ─────────────────────────────────────────────────────────────
    func login(phone: String, password: String) async throws -> AuthResponse {
        try await request("POST", path: "/auth/login", body: ["phone": phone, "password": password], auth: false)
    }

    func register(name: String, phone: String, password: String, email: String?) async throws -> AuthResponse {
        var body: [String:Any] = ["name": name, "phone": phone, "password": password]
        if let email { body["email"] = email }
        return try await request("POST", path: "/auth/register", body: body, auth: false)
    }

    func logout() async {
        guard let rt = TokenStore.refresh else { return }
        _ = try? await request("POST", path: "/auth/logout", body: ["refresh_token": rt]) as APIResponse<String>
        TokenStore.clear()
    }

    func me() async throws -> APIResponse<User> {
        try await request("GET", path: "/auth/me")
    }

    func updateProfile(_ body: [String:Any]) async throws -> APIResponse<User> {
        try await request("PUT", path: "/auth/profile", body: body)
    }

    // ─── Products ─────────────────────────────────────────────────────────
    func products(category: String? = nil, search: String? = nil, page: Int = 1) async throws -> PaginatedResponse<Product> {
        var q = "?page=\(page)"
        if let c = category { q += "&category=\(c)" }
        if let s = search    { q += "&search=\(s.addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed) ?? "")" }
        return try await request("GET", path: "/products\(q)", auth: false)
    }

    func product(_ id: Int) async throws -> APIResponse<Product> {
        try await request("GET", path: "/products/\(id)", auth: false)
    }

    // ─── Auctions ─────────────────────────────────────────────────────────
    func auctions(status: String? = nil, page: Int = 1) async throws -> PaginatedResponse<Auction> {
        var q = "?page=\(page)"
        if let s = status { q += "&status=\(s)" }
        return try await request("GET", path: "/auctions\(q)", auth: false)
    }

    func auction(_ id: Int) async throws -> APIResponse<AuctionDetail> {
        try await request("GET", path: "/auctions/\(id)", auth: false)
    }

    func createAuction(_ body: [String:Any]) async throws -> APIResponse<Auction> {
        try await request("POST", path: "/auctions", body: body)
    }

    func placeBid(auctionId: Int, amount: Double) async throws -> APIResponse<BidResult> {
        try await request("POST", path: "/auctions/\(auctionId)/bid", body: ["amount": amount])
    }

    func sendPaymentLink(auctionId: Int, link: String) async throws -> APIResponse<String> {
        try await request("POST", path: "/auctions/\(auctionId)/payment-link", body: ["payment_link": link])
    }

    func reportNonPayment(auctionId: Int) async throws -> APIResponse<String> {
        try await request("POST", path: "/auctions/\(auctionId)/report")
    }

    // ─── Orders ───────────────────────────────────────────────────────────
    func createOrder(productId: Int, notes: String? = nil) async throws -> APIResponse<Order> {
        var body: [String:Any] = ["product_id": productId]
        if let n = notes { body["notes"] = n }
        return try await request("POST", path: "/orders", body: body)
    }

    func myOrders() async throws -> PaginatedResponse<Order> {
        try await request("GET", path: "/orders")
    }

    // ─── Notifications ────────────────────────────────────────────────────
    func notifications(page: Int = 1) async throws -> PaginatedResponse<AppNotification> {
        try await request("GET", path: "/notifications?page=\(page)")
    }

    func markRead(_ id: Int) async throws {
        _ = try? await request("PATCH", path: "/notifications/\(id)/read") as APIResponse<String>
    }

    func markAllRead() async throws {
        _ = try? await request("POST", path: "/notifications/read-all") as APIResponse<String>
    }
}

// ─── Extra decodable types ────────────────────────────────────────────────
struct AuctionDetail: Codable {
    var auction: Auction
    var bids: [Bid]
}

struct BidResult: Codable {
    var bid: Bid
    var auction: Auction
}
