import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class AuctionProvider extends ChangeNotifier {
  List<Auction> auctions = [];
  Auction? selectedAuction;
  List<Bid> bids = [];
  bool isLoading = false;
  String? errorMessage;
  bool bidSuccess = false;

  final _api = APIService.instance;

  AuctionProvider() { _subscribeWS(); }

  void _subscribeWS() {
    WebSocketService.instance.onNewBid = (auctionId, amount, bidderName) {
      final idx = auctions.indexWhere((a) => a.id == auctionId);
      if (idx != -1) { auctions[idx].currentPrice = amount; auctions[idx].bidsCount++; }
      if (selectedAuction?.id == auctionId) { selectedAuction!.currentPrice = amount; }
      notifyListeners();
    };
    WebSocketService.instance.onAuctionEnded = (auctionId) {
      final idx = auctions.indexWhere((a) => a.id == auctionId);
      if (idx != -1) { auctions[idx].status = 'ended'; }
      notifyListeners();
      fetchAuctions();
    };
  }

  Future<void> fetchAuctions({String status = 'active'}) async {
    isLoading = true; notifyListeners();
    try { auctions = await _api.auctions(status:status); }
    on APIError catch (e) { errorMessage = e.message; }
    isLoading = false; notifyListeners();
  }

  Future<void> fetchAuction(int id) async {
    isLoading = true; errorMessage = null; notifyListeners();
    try {
      final r = await _api.auctionDetail(id);
      final data = Map<String,dynamic>.from(r['data'] as Map);
      selectedAuction = Auction.fromJson(data);
      final rawBids = data['recent_bids'] as List? ?? [];
      bids = rawBids.map((e) => Bid.fromJson(e as Map<String,dynamic>)).toList();
    } on APIError catch (e) { errorMessage = e.message; }
    catch (e) { errorMessage = e.toString(); }
    isLoading = false; notifyListeners();
  }

  Future<void> placeBid(int auctionId, double amount) async {
    isLoading = true; errorMessage = null; bidSuccess = false; notifyListeners();
    try {
      final r = await _api.placeBid(auctionId, amount);
      final newBid = Bid.fromJson(r['data']['bid']);
      bids.insert(0, newBid);
      selectedAuction = Auction.fromJson(r['data']['auction']);
      final idx = auctions.indexWhere((a) => a.id == auctionId);
      if (idx != -1) auctions[idx] = selectedAuction!;
      bidSuccess = true;
    } on APIError catch (e) { errorMessage = e.message; }
    isLoading = false; notifyListeners();
  }

  Future<bool> sendPaymentLink(int auctionId, String link) async {
    try { await _api.sendPaymentLink(auctionId, link); return true; }
    catch (_) { return false; }
  }

  Future<bool> reportNonPayment(int auctionId) async {
    try { await _api.reportNonPayment(auctionId); return true; }
    catch (_) { return false; }
  }
}
