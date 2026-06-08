import 'package:flutter/material.dart' show Color;

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
  int? categoryId;
  double price;
  int stock, viewsCount, salesCount;
  int? beadCount;
  double? beadSizeMm, weightGrams;
  String emoji;
  List<String> imageUrls;
  bool isAvailable;

  Product({required this.id, required this.name, required this.price,
           this.description, this.categoryName, this.categoryId, this.material, this.badge,
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
      categoryId: j['category_id'] as int?,
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
// ─── OrderItem ────────────────────────────────────────────────────────────
class OrderItem {
  final int id, productId, quantity;
  final String productName, productEmoji;
  final double unitPrice, totalPrice;

  OrderItem({required this.id, required this.productId, required this.quantity,
             required this.productName, required this.productEmoji,
             required this.unitPrice, required this.totalPrice});

  factory OrderItem.fromJson(Map<String,dynamic> j) => OrderItem(
    id:           j['id'],
    productId:    j['product_id'],
    quantity:     j['quantity'] ?? 1,
    productName:  j['product_name'] ?? '',
    productEmoji: j['product_emoji'] ?? '📿',
    unitPrice:    double.tryParse(j['unit_price'].toString()) ?? 0.0,
    totalPrice:   double.tryParse(j['total_price'].toString()) ?? 0.0,
  );
}

// ─── Order ────────────────────────────────────────────────────────────────
class Order {
  final int id;
  String orderNumber, status;
  double totalPrice;
  String? productName, productEmoji, paymentLink, notes;
  String? buyerName, buyerPhone, deliveryAddress;
  int? productId;
  bool isCartOrder;
  List<OrderItem> items;
  String? createdAt;

  Order({required this.id, required this.orderNumber, required this.status,
         required this.totalPrice, this.productName, this.productEmoji,
         this.paymentLink, this.notes, this.buyerName, this.buyerPhone,
         this.deliveryAddress, this.productId, this.isCartOrder = false,
         this.items = const [], this.createdAt});

  factory Order.fromJson(Map<String,dynamic> j) => Order(
    id:              j['id'],
    orderNumber:     j['order_number'] ?? '#${j['id']}',
    status:          j['status'] ?? 'pending',
    totalPrice:      double.tryParse(j['total_price'].toString()) ?? 0.0,
    productName:     j['product_name'],
    productEmoji:    j['product_emoji'],
    paymentLink:     j['payment_link'],
    notes:           j['notes'],
    buyerName:       j['buyer_name'],
    buyerPhone:      j['buyer_phone'],
    deliveryAddress: j['delivery_address'],
    productId:       j['product_id'],
    isCartOrder:     j['is_cart_order'] == 1 || j['is_cart_order'] == true,
    items: (j['items'] as List? ?? []).map((i) => OrderItem.fromJson(i)).toList(),
    createdAt:       j['created_at'],
  );

  String get totalFormatted => '${totalPrice.toStringAsFixed(totalPrice % 1 == 0 ? 0 : 3)} د.ك';

  String get statusDisplay {
    const m = {'pending':'قيد الانتظار','confirmed':'تم التأكيد',
                'processing':'قيد التجهيز','shipped':'تم الشحن',
                'delivered':'تم التوصيل','cancelled':'ملغي'};
    return m[status] ?? status;
  }

  Color get statusColor {
    switch (status) {
      case 'confirmed':  return const Color(0xFF2196F3);
      case 'processing': return const Color(0xFFFF9800);
      case 'shipped':    return const Color(0xFF9C27B0);
      case 'delivered':  return const Color(0xFF4CAF50);
      case 'cancelled':  return const Color(0xFFF44336);
      default:           return const Color(0xFF9E9E9E);
    }
  }

  String get statusEmoji {
    const m = {'pending':'⏳','confirmed':'✅','processing':'⚙️',
                'shipped':'🚚','delivered':'🎉','cancelled':'❌'};
    return m[status] ?? '📦';
  }

  // عرض المحتوى — منتج واحد أو قائمة
  String get summary {
    if (isCartOrder && items.isNotEmpty) {
      return items.map((i) => '${i.productEmoji} ${i.productName} ×${i.quantity}').join('\n');
    }
    return '${productEmoji ?? '📦'} ${productName ?? 'منتج'}';
  }
}

// ─── AppNotification ──────────────────────────────────────────────────────
class AppNotification {
  final int id;
  String type, title, body, icon;
  bool isRead;
  String? createdAt;

  AppNotification({required this.id, required this.type,
    required this.title, required this.body, required this.icon,
    this.isRead = false, this.createdAt});

  factory AppNotification.fromJson(Map<String,dynamic> j) => AppNotification(
    id:        j['id'],
    type:      j['type'] ?? 'info',
    title:     j['title'] ?? '',
    body:      j['body'] ?? '',
    icon:      j['icon'] ?? '🔔',
    isRead:    j['is_read'] == 1 || j['is_read'] == true,
    createdAt: j['created_at'],
  );
}
