import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/admin_service.dart';
import '../services/item_service.dart';

class AdminProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _allItems = [];
  Map<String, dynamic>? _settings;
  Map<String, dynamic>? _health;
  Map<String, dynamic>? _analytics;
  List<Map<String, dynamic>> _paymentHistory = [];
  RealtimeChannel? _channel;
  Timer? _pollTimer;
  bool _isConnected = false;

  bool get loading => _loading;
  String? get error => _error;
  List<Map<String, dynamic>> get orders => _orders;
  List<Map<String, dynamic>> get allItems => _allItems;
  Map<String, dynamic>? get settings => _settings;
  Map<String, dynamic>? get health => _health;
  Map<String, dynamic>? get analytics => _analytics;
  List<Map<String, dynamic>> get paymentHistory => _paymentHistory;
  bool get isConnected => _isConnected;
  bool get isStoreOpen => _settings?['is_store_open'] == true;
  int get activeOrderCount => _settings?['active_order_count'] ?? 0;

  Future<void> loadDashboard() async {
    _loading = true;
    notifyListeners();
    
    // 1. Trigger backend cleanup to mark expired orders before fetching
    await AdminService.cleanupExpiredOrders();

    // 2. Fetch the latest dashboard data
    final res = await AdminService.getDashboardOrders();
    if (res['success'] && res['data'] != null) {
      _orders = (res['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      _orders = [];
    }
    _settings = await ItemService.fetchAdminSettings();
    _loading = false;
    notifyListeners();
  }

  Future<bool> confirmOrder(String orderId) async {
    final res = await AdminService.markOrderConfirmed(orderId);
    if (res['success']) {
      await loadDashboard();
    } else {
      _error = res['message'];
    }
    notifyListeners();
    return res['success'] == true;
  }

  Future<bool> markReady(String orderId) async {
    final res = await AdminService.markOrderReady(orderId);
    if (res['success']) {
      await loadDashboard();
    } else {
      _error = res['message'];
    }
    notifyListeners();
    return res['success'] == true;
  }

  Future<bool> markCollected(String orderId) async {
    final res = await AdminService.markOrderCollected(orderId);
    if (res['success']) {
      await loadDashboard();
    } else {
      _error = res['message'];
    }
    notifyListeners();
    return res['success'] == true;
  }

  Future<bool> toggleStore(bool open) async {
    final res = await AdminService.toggleStore(open);
    if (res['success']) {
      await refreshSettings();
    } else {
      _error = res['message'];
    }
    notifyListeners();
    return res['success'] == true;
  }

  Future<void> loadInventory() async {
    _loading = true;
    notifyListeners();
    _allItems = await ItemService.fetchAllItems();
    _loading = false;
    notifyListeners();
  }

  Future<String?> uploadProductImage(List<int> bytes, String fileName) async {
    try {
      final path = 'items/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await Supabase.instance.client.storage
          .from('product-images')
          .uploadBinary(path, Uint8List.fromList(bytes));
      
      return Supabase.instance.client.storage
          .from('product-images')
          .getPublicUrl(path);
    } catch (e) {
      _error = 'Upload failed: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> addItem({
    required String name,
    required double price,
    required int stock,
    String? description,
    String? category,
    String? imageUrl,
  }) async {
    final res = await AdminService.addNewItem(
      name: name,
      price: price,
      stock: stock,
      description: description,
      category: category,
      imageUrl: imageUrl,
    );
    
    final ok = res['success'] == true;
    if (ok) {
      await loadInventory();
    } else {
      _error = res['message'] ?? 'Failed to add item';
    }
    notifyListeners();
    return ok;
  }

  Future<bool> updateItem({
    required String itemId,
    String? name,
    double? price,
    int? stock,
    String? imageUrl,
    String? description,
    String? category,
    int? sortOrder,
  }) async {
    final res = await AdminService.updateItem(
      itemId: itemId,
      name: name,
      price: price,
      stock: stock,
      imageUrl: imageUrl,
      description: description,
      category: category,
      sortOrder: sortOrder,
    );
    
    final ok = res['success'] == true;
    if (ok) {
      await loadInventory();
    } else {
      _error = res['message'] ?? 'Failed to update item';
    }
    notifyListeners();
    return ok;
  }

  Future<bool> deleteItem(String itemId) async {
    final ok = await ItemService.deleteItem(itemId);
    if (ok) {
      await loadInventory();
    } else {
      _error = 'Failed to delete item';
    }
    notifyListeners();
    return ok;
  }

  Future<bool> addStock(String itemId, int qty) async {
    // Direct Supabase UPDATE — no RPC dependency
    final ok = await ItemService.addStock(itemId, qty);
    if (ok) {
      await loadInventory();
    } else {
      _error = 'Failed to add stock';
    }
    notifyListeners();
    return ok;
  }

  Future<bool> toggleItemAvail(String itemId, bool avail) async {
    // Direct Supabase UPDATE
    final ok = await ItemService.toggleAvailability(itemId, avail);
    if (ok) {
      await loadInventory();
    } else {
      _error = 'Failed to toggle availability';
    }
    notifyListeners();
    return ok;
  }

  Future<void> refreshSettings() async {
    try {
      debugPrint('🔄 [Admin] Refreshing settings...');
      final newSettings = await ItemService.fetchAdminSettings();
      if (newSettings != null) {
        _settings = Map<String, dynamic>.from(newSettings);
        debugPrint('✅ [Admin] Settings updated: $_settings');
      } else {
        debugPrint('⚠️ [Admin] Received null settings from DB');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('🔥 [Admin] Error refreshing settings: $e');
    }
  }

  Future<bool> updateMaxOrders(int limit) async {
    debugPrint('🚀 [Admin] Updating max orders to: $limit');
    final res = await AdminService.updateOrderLimit(limit);
    final ok = res['success'] == true;
    if (ok) {
      // Direct Optimistic Update to force UI refresh
      if (_settings != null) {
        _settings!['max_active_orders'] = limit;
      }
      notifyListeners(); 
      debugPrint('✨ [Admin] Max orders UI updated to: $limit');
      await refreshSettings();
    } else {
      _error = res['message'] ?? 'Failed to update order limit';
    }
    notifyListeners();
    return ok;
  }

  Future<bool> updatePickupWindow(int minutes) async {
    debugPrint('🚀 [Admin] Updating pickup window to: $minutes');
    final res = await AdminService.updatePickupWindow(minutes);
    final ok = res['success'] == true;
    if (ok) {
      // Direct Optimistic Update to force UI refresh
      if (_settings != null) {
        _settings!['pickup_window_minutes'] = minutes;
      }
      notifyListeners();
      debugPrint('✨ [Admin] Pickup window UI updated to: $minutes');
      await refreshSettings();
    } else {
      _error = res['message'] ?? 'Failed to update pickup window';
    }
    notifyListeners();
    return ok;
  }

  Future<void> loadHealth() async {
    final res = await AdminService.systemHealth();
    if (res['success']) _health = res['data'];
    notifyListeners();
  }

  Future<void> loadAnalytics() async {
    final res = await AdminService.getAnalytics();
    if (res['success']) {
      _analytics = res['data'];
    }
    // Also refresh settings to ensure store management UI is up to date
    await refreshSettings();
    notifyListeners();
  }

  Future<void> loadPaymentHistory({String? studentName, String? status, String? date}) async {
    _loading = true;
    notifyListeners();
    final res = await AdminService.getPaymentHistory(
      studentName: studentName,
      status: status,
      date: date,
    );
    if (res['success']) {
      _paymentHistory = (res['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    _loading = false;
    notifyListeners();
  }

  void subscribeToDashboard() {
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('admin-dashboard')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            debugPrint('Admin: Order changed');
            loadDashboard();
            loadAnalytics();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'items',
          callback: (payload) {
            debugPrint('Admin: Item changed');
            loadInventory();
            loadAnalytics();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'analytics_daily',
          callback: (payload) {
            debugPrint('Admin: Analytics changed');
            loadAnalytics();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'admin_settings',
          callback: (payload) {
            debugPrint('Admin: Settings changed');
            refreshSettings();
          },
        );

    _channel?.subscribe((status, [error]) {
      debugPrint('🔌 [Admin Realtime] Status: $status');
      _isConnected = status == RealtimeSubscribeStatus.subscribed;
      Future.microtask(() {
        notifyListeners();
      });
    });

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      loadDashboard();
      loadAnalytics();
      if (!_isConnected) {
        subscribeToDashboard();
      }
    });
  }

  void unsubscribe() {
    _channel?.unsubscribe();
    _channel = null;
    _pollTimer?.cancel();
    _pollTimer = null;
  }



  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }
}
