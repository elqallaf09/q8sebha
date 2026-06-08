import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> products = [];
  Product? selectedProduct;
  bool isLoading = false;
  String? errorMessage;
  bool orderSuccess = false;

  final _api = APIService.instance;

  List<Product>? _allProducts; // نسخة أصلية قبل الفلتر

  Future<void> fetchProducts({String? category, String? search}) async {
    isLoading = true; notifyListeners();
    try {
      products = await _api.products(category:category, search:search);
      _allProducts = List.of(products);
      errorMessage = null;
    } catch (e) {
      errorMessage = e is APIError ? e.message : 'تعذّر الاتصال بالخادم';
    } finally {
      isLoading = false; notifyListeners();
    }
  }

  void setFilteredProducts(List<Product> filtered) {
    products = filtered;
    notifyListeners();
  }

  void resetFilter() {
    if (_allProducts != null) {
      products = List.of(_allProducts!);
      notifyListeners();
    }
  }

  Future<void> fetchProduct(int id) async {
    isLoading = true; notifyListeners();
    try { selectedProduct = await _api.product(id); }
    on APIError catch (e) { errorMessage = e.message; }
    isLoading = false; notifyListeners();
  }

  Future<void> buyProduct(int id, {String? notes}) async {
    isLoading = true; errorMessage = null; orderSuccess = false; notifyListeners();
    try {
      final r = await _api.createOrder(id, notes:notes);
      orderSuccess = r['success'] == true;
      if (!orderSuccess) errorMessage = r['message'] ?? 'فشل الطلب';
    } on APIError catch (e) { errorMessage = e.message; }
    isLoading = false; notifyListeners();
  }
}
