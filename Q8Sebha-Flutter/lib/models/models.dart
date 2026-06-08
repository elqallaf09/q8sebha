// ─── User ─────────────────────────────────────────────────────────────────
class User {
  final int id;
  String name, phone;
  String? email, username, role;
  String? contactMethod, deliveryMethod;
  // حقول العنوان التفصيلية
  String? deliveryCountry, deliveryArea, deliveryBlock, deliveryStreet,
          deliveryAvenue, deliveryHouse, deliveryApartment, deliveryAddress;
  // إحصائيات
  int? totalPurchases, totalWins, totalAuctions, isVerified;
  double? rating;
  bool isBanned;

  User({
    required this.id, required this.name, required this.phone,
    this.email, this.username, this.role = 'user', this.isBanned = false,
    this.contactMethod, this.deliveryMethod,
    this.deliveryCountry, this.deliveryArea, this.deliveryBlock,
    this.deliveryStreet, this.deliveryAvenue, this.deliveryHouse,
    this.deliveryApartment, this.deliveryAddress,
    this.totalPurchases, this.totalWins, this.totalAuctions,
    this.isVerified, this.rating,
  });

  factory User.fromJson(Map<String,dynamic> j) => User(
    id: j['id'], name: j['name'], phone: j['phone'],
    email: j['email'], username: j['username'],
    role: j['role'] ?? 'user',
    isBanned: j['is_banned'] == 1 || j['is_banned'] == true,
    contactMethod:     j['contact_method'],
    deliveryMethod:    j['delivery_method'],
    deliveryCountry:   j['delivery_country'],
    deliveryArea:      j['delivery_area'],
    deliveryBlock:     j['delivery_block'],
    deliveryStreet:    j['delivery_street'],
    deliveryAvenue:    j['delivery_avenue'],
    deliveryHouse:     j['delivery_house'],
    deliveryApartment: j['delivery_apartment'],
    deliveryAddress:   j['delivery_address'],
    totalPurchases: j['total_purchases'] is int ? j['total_purchases'] : 0,
    totalWins:      j['total_wins']      is int ? j['total_wins']      : 0,
    totalAuctions:  j['total_auctions']  is int ? j['total_auctions']  : 0,
    isVerified: j['is_verified'] is int ? j['is_verified'] : 0,
    rating: j['rating'] != null ? (j['rating'] as num).toDouble() : 5.0,
  );

  bool get isAdmin  => role == 'admin';
  bool get isSeller => role == 'seller' || role == 'admin';

  /// عنوان كامل مُجمَّع
  String get fullAddress {
    final parts = <String>[];
    if (deliveryCountry != null && deliveryCountry!.isNotEmpty) parts.add(deliveryCountry!);
    if (deliveryArea    != null && deliveryArea!.isNotEmpty)    parts.add('م. ${deliveryArea!}');
    if (deliveryBlock   != null && deliveryBlock!.isNotEmpty)   parts.add('ق ${deliveryBlock!}');
    if (deliveryStreet  != null && deliveryStreet!.isNotEmpty)  parts.add('ش ${deliveryStreet!}');
    if (deliveryAvenue  != null && deliveryAvenue!.isNotEmpty)  parts.add('ج ${deliveryAvenue!}');
    if (deliveryHouse   != null && deliveryHouse!.isNotEmpty)   parts.add('م ${deliveryHouse!}');
    if (deliveryApartment != null && deliveryApartment!.isNotEmpty) parts.add('ش ${deliveryApartment!}');
    return parts.isEmpty ? '—' : parts.join(' | ');
  }
}

// ─── Product ──────────────────────────────────────────────────────────────
class Product {
  final int id;
  String name;
  String? description, categoryName, material, originCountry, badge;
  double price;
  int stock, viewsCount, salesCount;
  int? beadCount;
  double? beadSizeMm, weightGrams;
  String emoji;
  List<String> imageUrls;
  bool isAvailable;

  Product({required this.id, required this.name, required this.price,
           this.description, this.categoryName, this.material, this.badge,
           this.originCountry, this.beadCount, this.beadSizeMm, this.weightGrams,
           this.emoji = '📿', this.imageUrls = const [], this.isAvailable = true,
           this.stock = 1, this.viewsCount = 0, this.salesCount = 0});

  factory Product.fromJson(Map<String,dynamic> j) {
    List<String> imgs = [];
    if (j['image_urls'] != null) {
      if (j['image_urls'] is List) imgs = List<String>.from(j['image_urls']);
      else if (j['image_urls'] is String && j['image_urls'].isNotEmpty) {
        try { imgs = List<String>.from(j['image_urls'].toString().replaceAll('[','').replaceAll(']','').replaceAll('"','').split(',')); }
        catch (_) {}
      }
    }
    return Product(
      id: j['id'], name: j['name'],
      price: double.tryParse(j['price'].toString()) ?? 0.0,
      description: j['description'], categoryName: j['category_name'],
      material: j['material'], badge: j['badge'],
      originCountry: j['origin_country'],
      beadCount:  j['bead_count'],
      beadSizeMm: j['bead_size_mm'] != null ? (j['bead_size_mm'] as num).toDouble() : null,
      weightGrams: j['weight_grams'] != null ? (j['weight_grams'] as num).toDouble() : null,
      emoji: j['emoji'] ?? '📿', imageUrls: imgs,
      isAvailable: j['is_available'] == 1 || j['is_available'] == true,
      stock: j['stock'] ?? 1,
      viewsCount: j['views_count'] ?? 0,
      salesCount: j['sales_count'] ?? 0,
    );
  }

  String get priceFormatted => '${price.toStringAsFixed(3)} د.ك';
  String get primaryImage   => imageUrls.isNotEmpty ? imageUrls.first : '';
}

// ─── Auction ──────────────────────────────────────────────────────────────
class Auction {
  final int id, sellerId;
  String title, status;
  String? description, sellerTerms, sellerName, sellerPhone, winnerName;
  double startingPrice, maxPrice, bidIncrement, currentPrice;
  double? reservePrice;
  int bidsCount, durationMinutes;
  int? winnerId, currentBidderId;
  double? finalPrice;
  DateTime? endsAt;
  List<String> imageUrls;

  Auction({required this.id, required this.sellerId, required this.title,
           required this.startingPrice, required this.maxPrice,
           required this.currentPrice, this.bidIncrement = 1.0,
           this.reservePrice, this.bidsCount = 0, required this.durationMinutes,
           required this.status, this.description, this.sellerTerms,
           this.sellerName, this.sellerPhone, this.winnerName,
           this.winnerId, this.currentBidderId, this.finalPrice,
           this.endsAt, this.imageUrls = const []});

  factory Auction.fromJson(Map<String,dynamic> j) {
    DateTime? ends;
    if (j['ends_at'] != null) {
      try { ends = DateTime.parse(j['ends_at']).toLocal(); } catch (_) {}
    }
    List<String> imgs = [];
    if (j['image_urls'] is List) imgs = List<String>.from(j['image_urls']);
    return Auction(
      id: j['id'], sellerId: j['seller_id'],
      title: j['title'], status: j['status'] ?? 'active',
      description: j['description'], sellerTerms: j['seller_terms'],
      sellerName: j['seller_name'], sellerPhone: j['seller_phone'],
      winnerName: j['winner_name'],
      startingPrice: double.tryParse(j['starting_price'].toString()) ?? 0.0,
      maxPrice:      double.tryParse(j['max_price'].toString()) ?? 0.0,
      currentPrice:  double.tryParse(j['current_price'].toString()) ?? 0.0,
      bidIncrement:  double.tryParse(j['bid_increment']?.toString() ?? '') ?? 1.0,
      reservePrice:  j['reserve_price'] != null ? double.tryParse(j['reserve_price'].toString()) : null,
      bidsCount:     j['bids_count'] ?? 0,
      durationMinutes: j['duration_minutes'] ?? 60,
      winnerId:       j['winner_id'],
      currentBidderId: j['current_bidder_id'],
      finalPrice: j['final_price'] != null ? double.tryParse(j['final_price'].toString()) : null,
      endsAt: ends, imageUrls: imgs,
    );
  }

  bool get isActive       => status == 'active' && timeRemaining.inSeconds > 0;
  bool get isReserveNotMet => status == 'reserve_not_met';
  bool get isNoBids       => status == 'no_bids';
  Duration get timeRemaining => endsAt != null ? endsAt!.difference(DateTime.now()) : Duration.zero;
  double get progressFraction => ((currentPrice - startingPrice) / (maxPrice - startingPrice)).clamp(0.0, 1.0);
  String get currentPriceFormatted => '${currentPrice.toStringAsFixed(3)} د.ك';
  String get maxPriceFormatted     => '${maxPrice.toStringAsFixed(3)} د.ك';
  String get primaryImage          => imageUrls.isNotEmpty ? imageUrls.first : '';

  /// نص الحالة النهائية
  String get statusLabel {
    switch (status) {
      case 'active':           return '🟢 نشط';
      case 'ended':            return '✅ انتهى';
      case 'reserve_not_met':  return '↩️ عالمرجوع';
      case 'no_bids':          return '😶 لا مزايدات';
      default:                 return '🔴 انتهى';
    }
  }

  String get countdownString {
    final d = timeRemaining;
    if (d.inSeconds <= 0) return 'انتهى';
    if (d.inHours > 0) return '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2,'0')}:${(d.inSeconds % 60).toString().padLeft(2,'0')}';
    return '${d.inMinutes.toString().padLeft(2,'0')}:${(d.inSeconds % 60).toString().padLeft(2,'0')}';
  }
}

// ─── Bid ──────────────────────────────────────────────────────────────────
class Bid {
  final int id, auctionId, bidderId;
  double amount;
  String? bidderName, createdAt;

  Bid({required this.id, required this.auctionId, required this.bidderId,
       required this.amount, this.bidderName, this.createdAt});

  factory Bid.fromJson(Map<String,dynamic> j) => Bid(
    id: j['id'], auctionId: j['auction_id'], bidderId: j['bidder_id'],
    amount: (j['amount'] as num).toDouble(),
    bidderName: j['bidder_name'], createdAt: j['created_at'],
  );

  String get amountFormatted => '${amount.toStringAsFixed(3)} د.ك';
}

// ─── Order ────────────────────────────────────────────────────────────────
class Order {
  final int id;
  String orderNumber, status;
  double totalAmount;
  String? productName, productEmoji, paymentLink, deliveryArea, notes;
  int? productId, auctionId;
  String? createdAt;

  Order({required this.id, required this.orderNumber, required this.status,
         required this.totalAmount, this.productName, this.productEmoji,
         this.paymentLink, this.deliveryArea, this.notes,
         this.productId, this.auctionId, this.createdAt});

  factory Order.fromJson(Map<String,dynamic> j) => Order(
    id: j['id'], orderNumber: j['order_number'],
    status: j['status'] ?? 'pending',
    totalAmount: (j['total_amount'] as num).toDouble(),
    productName:  j['product_name'],
    productEmoji: j['product_emoji'],
    paymentLink:  j['payment_link'],
    deliveryArea: j['delivery_area'],
    notes:       j['notes'],
    productId:   j['product_id'],
    auctionId:   j['auction_id'],
    createdAt:   j['created_at'],
  );

  String get totalFormatted  => '${totalAmount.toStringAsFixed(3)} د.ك';
  String get statusDisplay {
    const m = {'pending':'قيد الانتظار','confirmed':'مؤكد','processing':'قيد التجهيز',
                'shipped':'تم الشحن','delivered':'تم التوصيل','cancelled':'ملغي'};
    return m[status] ?? status;
  }
}

// ─── AppNotification ──────────────────────────────────────────────────────
class AppNotification {
  final int id;
  String type, title, body, icon;
  bool isRead;
  String? createdAt;

  AppNotification({required this.id, required this.type, required this.title,
                   required this.body, this.icon = '🔔', this.isRead = false, this.createdAt});

  factory AppNotification.fromJson(Map<String,dynamic> j) => AppNotification(
    id: j['id'], type: j['type'] ?? 'system',
    title: j['title'], body: j['body'],
    icon: j['icon'] ?? '🔔',
    isRead: j['is_read'] == 1 || j['is_read'] == true,
    createdAt: j['created_at'],
  );
}

// ─── CartItem ─────────────────────────────────────────────────────────────
class CartItem {
  final int id;
  final int productId;
  final String name;
  final double price;
  final String emoji;
  final List<String> imageUrls;
  int quantity;
  final String? notes;

  CartItem({
    required this.id, required this.productId, required this.name,
    required this.price, required this.emoji, required this.imageUrls,
    required this.quantity, this.notes,
  });

  double get total => price * quantity;
  String get priceFormatted => price.toStringAsFixed(price % 1 == 0 ? 0 : 3);
  String get totalFormatted => total.toStringAsFixed(total % 1 == 0 ? 0 : 3);

  factory CartItem.fromJson(Map<String,dynamic> j) {
    List<String> imgs = [];
    if (j['image_urls'] != null) {
      if (j['image_urls'] is List) imgs = List<String>.from(j['image_urls']);
      else if (j['image_urls'] is String && (j['image_urls'] as String).isNotEmpty) {
        try { imgs = List<String>.from(j['image_urls'].toString()
            .replaceAll('[','').replaceAll(']','').replaceAll('"','').split(',')); } catch (_) {}
      }
    }
    return CartItem(
      id: j['id'],
      productId: j['product_id'],
      name: j['name'] ?? '',
      price: double.tryParse(j['price'].toString()) ?? 0.0,
      emoji: j['emoji'] ?? '📿',
      imageUrls: imgs,
      quantity: j['quantity'] ?? 1,
      notes: j['notes'],
    );
  }
}

// ─── Category ─────────────────────────────────────────────────────────────
class Category {
  final int id;
  String name, nameEn, icon;
  Category({required this.id, required this.name, required this.nameEn, required this.icon});
  factory Category.fromJson(Map<String,dynamic> j) =>
      Category(id:j['id'], name:j['name'], nameEn:j['name_en'], icon:j['icon'] ?? '📿');
}
