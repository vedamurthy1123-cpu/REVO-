import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../services/item_service.dart';

class CartItem {
  final String id; // cart table id
  final String itemId;
  final String name;
  final double price;
  final String? imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.itemId,
    required this.name,
    required this.price,
    this.imageUrl,
    this.quantity = 1,
  });

  factory CartItem.fromDb(Map<String, dynamic> data) {
    final item = data['items'] as Map<String, dynamic>;
    return CartItem(
      id: data['id'],
      itemId: data['item_id'],
      name: item['name'],
      price: (item['price'] as num).toDouble(),
      imageUrl: item['image_url'],
      quantity: data['quantity'],
    );
  }
}

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  bool _loading = false;

  int _pickupWindow = 10;

  List<CartItem> get items => _items;
  bool get loading => _loading;
  int get itemCount => _items.length;
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);
  double get total => _items.fold(0.0, (sum, item) => sum + item.price * item.quantity);
  bool get isEmpty => _items.isEmpty;
  int get pickupWindow => _pickupWindow;

  Future<void> loadCart() async {
    _loading = true;
    notifyListeners();
    final data = await CartService.fetchCart();
    _items = data.map((e) => CartItem.fromDb(e)).toList();
    
    // Fetch pickup window from settings
    final settings = await ItemService.fetchAdminSettings();
    if (settings != null) {
      _pickupWindow = settings['pickup_window_minutes'] ?? 10;
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> addItem(String itemId) async {
    final success = await CartService.addToCart(itemId, 1);
    if (success) {
      await loadCart();
    }
  }

  Future<void> updateQuantity(String cartId, int qty) async {
    final success = await CartService.updateQuantity(cartId, qty);
    if (success) {
      await loadCart();
    }
  }

  Future<void> removeItem(String cartId) async {
    final success = await CartService.updateQuantity(cartId, 0);
    if (success) {
      await loadCart();
    }
  }

  Future<void> clearCart() async {
    final success = await CartService.clearCart();
    if (success) {
      _items.clear();
      notifyListeners();
    }
  }

  /// Clears only the in-memory cart (used after atomic RPC already cleared DB).
  void clearLocalCart() {
    _items.clear();
    notifyListeners();
  }

  Future<Map<String, dynamic>> placeOrder() async {
    // Fetch raw DB rows so CartService can read product stock info
    final rawRows = await CartService.fetchCart();
    final res = await CartService.placeOrder(total, rawRows);
    if (res['success'] == true) {
      _items.clear();
      notifyListeners();
    }
    return res;
  }

  bool isInCart(String itemId) {
    return _items.any((e) => e.itemId == itemId);
  }

  int getQuantity(String itemId) {
    final idx = _items.indexWhere((e) => e.itemId == itemId);
    return idx >= 0 ? _items[idx].quantity : 0;
  }

  List<Map<String, dynamic>> toOrderPayload() {
    return _items
        .map((e) => {'item_id': e.itemId, 'quantity': e.quantity})
        .toList();
  }
}
