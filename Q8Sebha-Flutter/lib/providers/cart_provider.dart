import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  bool isLoading = false;
  String? error;

  List<CartItem> get items => _items;
  int  get count   => _items.fold(0, (s, i) => s + i.quantity);
  double get total => _items.fold(0.0, (s, i) => s + i.total);
  String get totalFormatted => total.toStringAsFixed(total % 1 == 0 ? 0 : 3);

  Future<void> fetchCart() async {
    isLoading = true; notifyListeners();
    try {
      _items = await APIService.instance.getCart();
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false; notifyListeners();
    }
  }

  Future<bool> addItem(int productId, {int quantity=1, String? notes}) async {
    try {
      await APIService.instance.addToCart(productId, quantity: quantity, notes: notes);
      await fetchCart();
      return true;
    } catch (_) { return false; }
  }

  Future<void> updateQuantity(int id, int quantity) async {
    if (quantity < 1) { await removeItem(id); return; }
    try {
      await APIService.instance.updateCartItem(id, quantity);
      final idx = _items.indexWhere((i) => i.id == id);
      if (idx != -1) { _items[idx].quantity = quantity; notifyListeners(); }
    } catch (_) {}
  }

  Future<void> removeItem(int id) async {
    try {
      await APIService.instance.removeFromCart(id);
      _items.removeWhere((i) => i.id == id);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> clearCart() async {
    try {
      await APIService.instance.clearCart();
      _items = []; notifyListeners();
    } catch (_) {}
  }

  void reset() { _items = []; error = null; notifyListeners(); }
}
