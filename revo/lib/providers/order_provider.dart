import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _activeOrder;
  List<Map<String, dynamic>> _history = [];
  Set<String> _hiddenOrderIds = {};
  RealtimeChannel? _channel;
  Timer? _pollTimer;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  int _pickupWindowMinutes = 15;
  bool _isConnected = false;

  OrderProvider() {
    _loadHiddenOrders();
  }

  bool get loading => _loading;
  String? get error => _error;
  Map<String, dynamic>? get activeOrder => _activeOrder;
  List<Map<String, dynamic>> get history => _history;
  bool get hasActiveOrder => _activeOrder != null;
  Duration get remaining => _remaining;
  int get pickupWindowMinutes => _pickupWindowMinutes;
  bool get isConnected => _isConnected;

  Future<Map<String, dynamic>> placeOrder(
      List<Map<String, dynamic>> items) async {
    _loading = true;
    _error = null;
    notifyListeners();
    final res = await OrderService.placeOrder(items);
    _loading = false;
    if (!res['success']) {
      _error = res['message'];
    }
    notifyListeners();
    return res;
  }

  Future<Map<String, dynamic>> pay(String orderId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    final res = await OrderService.dummyPay(orderId);
    _loading = false;
    if (!res['success']) _error = res['message'];
    if (res['success']) await fetchActiveOrder();
    notifyListeners();
    return res;
  }

  Future<void> fetchActiveOrder() async {
    final res = await OrderService.getActiveOrder();
    
    // Also fetch settings for pickup window
    final settings = await Supabase.instance.client
        .from('admin_settings')
        .select('pickup_window_minutes')
        .eq('id', 1)
        .maybeSingle();
    
    if (settings != null) {
      _pickupWindowMinutes = settings['pickup_window_minutes'] ?? 15;
    }

    if (res['success']) {
      final order = res['data'];
      // If the latest order is expired, don't show it as "active" in the tracking UI
      if (order != null && order['status'] == 'expired') {
        _activeOrder = null;
        _stopCountdown();
      } else {
        _activeOrder = order;
        _startCountdown();
      }
    } else {
      _activeOrder = null;
      _stopCountdown();
    }
    notifyListeners();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    if (_activeOrder != null && _activeOrder!['status'] == 'ready') {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final deadlineStr = _activeOrder!['pickup_deadline'];
        if (deadlineStr != null) {
          final deadline = DateTime.parse(deadlineStr).toLocal();
          final now = DateTime.now();
          
          if (now.isBefore(deadline)) {
            _remaining = deadline.difference(now);
          } else {
            _remaining = Duration.zero;
            timer.cancel();
            // Automatically trigger backend cleanup when timer hits zero
            // This will mark the order as 'expired' and trigger the wallet refund
            OrderService.cleanupExpiredOrders().then((_) async {
              // Wait 1 second for DB triggers to complete wallet processing
              await Future.delayed(const Duration(seconds: 1));
              fetchActiveOrder();
            });
          }
          notifyListeners();
        }
      });
    } else {
      _remaining = Duration.zero;
    }
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _remaining = Duration.zero;
  }

  Future<void> fetchHistory() async {
    _loading = true;
    notifyListeners();
    final res = await OrderService.getOrderHistory();
    _loading = false;
    if (res['success'] && res['data'] != null) {
      final allHistory = (res['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _history = allHistory.where((o) {
        final id = o['order_id']?.toString() ?? '';
        return !_hiddenOrderIds.contains(id);
      }).toList();
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> confirmReceived(String orderId) async {
    _loading = true;
    notifyListeners();
    final res = await OrderService.confirmReceived(orderId);
    _loading = false;
    if (res['success']) {
      _activeOrder = null;
    } else {
      _error = res['message'];
    }
    notifyListeners();
    return res;
  }

  Future<Map<String, dynamic>> deleteHistoryOrder(String orderId) async {
    // Since backend might be unreachable or lacks the column, we use local hiding
    // which provides the best user experience immediately.
    _loading = true;
    notifyListeners();
    
    // Optional: Still try to call backend if available, but don't fail if it doesn't exist
    await OrderService.deleteHistoryOrder(orderId).catchError((_) => {'success': false});

    _hiddenOrderIds.add(orderId);
    await _saveHiddenOrders();
    
    _history.removeWhere((o) => o['order_id'].toString() == orderId);
    
    _loading = false;
    notifyListeners();
    return {'success': true, 'message': 'Order removed from history'};
  }

  Future<void> _loadHiddenOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('hidden_order_ids') ?? [];
      _hiddenOrderIds = list.toSet();
      if (_history.isNotEmpty) {
        _history.removeWhere((o) => _hiddenOrderIds.contains(o['order_id'].toString()));
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveHiddenOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('hidden_order_ids', _hiddenOrderIds.toList());
    } catch (_) {}
  }

  void subscribeToActiveOrder() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('active-order-updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            // When any change happens, just re-fetch the active order to be sure
            fetchActiveOrder();
          },
        );

    _channel?.subscribe((status, [error]) {
      debugPrint('🔌 [User Realtime] Status: $status');
      _isConnected = status == RealtimeSubscribeStatus.subscribed;
      Future.microtask(() {
        notifyListeners();
      });
    });

    // Fallback polling every 10s
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchActiveOrder();
      
      // If we've lost realtime connection, try to re-setup the channel
      if (!_isConnected) {
        debugPrint('🔌 [User Realtime] Connection lost, re-subscribing...');
        subscribeToActiveOrder();
      }
    });
  }

  void unsubscribe() {
    _channel?.unsubscribe();
    _channel = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _stopCountdown();
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
