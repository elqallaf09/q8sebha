import Foundation

// ─── User ─────────────────────────────────────────────────────────────────
struct User: Codable, Identifiable {
    let id: Int
    var name: String
    var phone: String
    var email: String?
    var role: String             // user | seller | admin
    var isBanned: Bool
    var contactMethod: String?   // whatsapp | phone | both
    var deliveryMethod: String?  // delivery | pickup
    var deliveryAddress: String?
    var deliveryArea: String?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, phone, email, role
        case isBanned       = "is_banned"
        case contactMethod  = "contact_method"
        case deliveryMethod = "delivery_method"
        case deliveryAddress = "delivery_address"
        case deliveryArea   = "delivery_area"
        case createdAt      = "created_at"
    }
}

// ─── Product ──────────────────────────────────────────────────────────────
struct Product: Codable, Identifiable {
    let id: Int
    var name: String
    var description: String?
    var price: Double
    var stock: Int
    var categoryName: String?
    var beadCount: Int?
    var beadSizeMm: Double?
    var weightGrams: Double?
    var material: String?
    var originCountry: String?
    var emoji: String
    var badge: String?
    var imageUrls: [String]
    var isAvailable: Bool
    var viewsCount: Int
    var salesCount: Int

    enum CodingKeys: String, CodingKey {
        case id, name, description, price, stock, material, emoji, badge
        case categoryName  = "category_name"
        case beadCount     = "bead_count"
        case beadSizeMm    = "bead_size_mm"
        case weightGrams   = "weight_grams"
        case originCountry = "origin_country"
        case imageUrls     = "image_urls"
        case isAvailable   = "is_available"
        case viewsCount    = "views_count"
        case salesCount    = "sales_count"
    }

    var primaryImage: String { imageUrls.first ?? "" }
    var priceFormatted: String { String(format: "%.3f د.ك", price) }
}

// ─── Auction ──────────────────────────────────────────────────────────────
struct Auction: Codable, Identifiable {
    let id: Int
    var sellerId: Int
    var title: String
    var description: String?
    var startingPrice: Double
    var maxPrice: Double
    var bidIncrement: Double
    var currentPrice: Double
    var bidsCount: Int
    var durationMinutes: Int
    var endsAt: String
    var status: AuctionStatus
    var winnerId: Int?
    var finalPrice: Double?
    var sellerTerms: String?
    var imageUrls: [String]
    var sellerName: String?
    var sellerPhone: String?
    var winnerName: String?
    var currentBidderId: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, description, status
        case sellerId        = "seller_id"
        case startingPrice   = "starting_price"
        case maxPrice        = "max_price"
        case bidIncrement    = "bid_increment"
        case currentPrice    = "current_price"
        case bidsCount       = "bids_count"
        case durationMinutes = "duration_minutes"
        case endsAt          = "ends_at"
        case winnerId        = "winner_id"
        case finalPrice      = "final_price"
        case sellerTerms     = "seller_terms"
        case imageUrls       = "image_urls"
        case sellerName      = "seller_name"
        case sellerPhone     = "seller_phone"
        case winnerName      = "winner_name"
        case currentBidderId = "current_bidder_id"
    }

    var primaryImage: String { imageUrls.first ?? "" }
    var currentPriceFormatted: String { String(format: "%.3f د.ك", currentPrice) }
    var maxPriceFormatted: String     { String(format: "%.3f د.ك", maxPrice) }
    var progressFraction: Double      { (currentPrice - startingPrice) / max(1, maxPrice - startingPrice) }

    var endsAtDate: Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: endsAt) ?? DateFormatter.sqliteFmt.date(from: endsAt)
    }
    var timeRemaining: TimeInterval   { max(0, endsAtDate?.timeIntervalSinceNow ?? 0) }
    var isActive: Bool                { status == .active && timeRemaining > 0 }
}

enum AuctionStatus: String, Codable {
    case active, ended, cancelled
}

// ─── Bid ──────────────────────────────────────────────────────────────────
struct Bid: Codable, Identifiable {
    let id: Int
    var auctionId: Int
    var bidderId: Int
    var amount: Double
    var bidderName: String?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, amount
        case auctionId  = "auction_id"
        case bidderId   = "bidder_id"
        case bidderName = "bidder_name"
        case createdAt  = "created_at"
    }

    var amountFormatted: String { String(format: "%.3f د.ك", amount) }
}

// ─── Order ────────────────────────────────────────────────────────────────
struct Order: Codable, Identifiable {
    let id: Int
    var orderNumber: String
    var buyerId: Int
    var productId: Int?
    var auctionId: Int?
    var orderType: String  // shop | auction
    var totalAmount: Double
    var status: OrderStatus
    var paymentLink: String?
    var deliveryMethod: String?
    var deliveryArea: String?
    var productName: String?
    var productEmoji: String?
    var notes: String?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, status, notes
        case orderNumber  = "order_number"
        case buyerId      = "buyer_id"
        case productId    = "product_id"
        case auctionId    = "auction_id"
        case orderType    = "order_type"
        case totalAmount  = "total_amount"
        case paymentLink  = "payment_link"
        case deliveryMethod = "delivery_method"
        case deliveryArea = "delivery_area"
        case productName  = "product_name"
        case productEmoji = "product_emoji"
        case createdAt    = "created_at"
    }

    var totalFormatted: String { String(format: "%.3f د.ك", totalAmount) }
}

enum OrderStatus: String, Codable {
    case pending, confirmed, processing, shipped, delivered, cancelled
    var displayName: String {
        switch self {
        case .pending:    return "قيد الانتظار"
        case .confirmed:  return "مؤكد"
        case .processing: return "قيد التجهيز"
        case .shipped:    return "تم الشحن"
        case .delivered:  return "تم التوصيل"
        case .cancelled:  return "ملغي"
        }
    }
}

// ─── AppNotification ──────────────────────────────────────────────────────
struct AppNotification: Codable, Identifiable {
    let id: Int
    var userId: Int
    var type: String
    var title: String
    var body: String
    var icon: String
    var isRead: Bool
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, type, title, body, icon
        case userId    = "user_id"
        case isRead    = "is_read"
        case createdAt = "created_at"
    }
}

// ─── Category ─────────────────────────────────────────────────────────────
struct Category: Codable, Identifiable {
    let id: Int
    var name: String
    var nameEn: String
    var icon: String
    var parentId: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, icon
        case nameEn  = "name_en"
        case parentId = "parent_id"
    }
}

// ─── API Responses ────────────────────────────────────────────────────────
struct APIResponse<T: Codable>: Codable {
    var success: Bool
    var data: T?
    var message: String?
}

struct PaginatedResponse<T: Codable>: Codable {
    var success: Bool
    var data: [T]
    var meta: Meta?
    struct Meta: Codable {
        var total: Int?
        var unread: Int?
    }
}

struct AuthResponse: Codable {
    var success: Bool
    var data: AuthData?
    var message: String?
    struct AuthData: Codable {
        var user: User
        var accessToken: String
        var refreshToken: String
        enum CodingKeys: String, CodingKey {
            case user
            case accessToken  = "access_token"
            case refreshToken = "refresh_token"
        }
    }
}

// ─── Helpers ──────────────────────────────────────────────────────────────
extension DateFormatter {
    static let sqliteFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()
}
