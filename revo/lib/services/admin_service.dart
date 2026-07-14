import 'package:supabase_flutter/supabase_flutter.dart';
import 'rpc_service.dart';
import 'auth_service.dart';

class AdminService {
  static Future<Map<String, dynamic>> getDashboardOrders() async {
    try {
      final client = Supabase.instance.client;
      // Fetch orders with joined order_items and student profile name
      final data = await client
          .from('orders')
          .select('*, student_name:profiles(full_name), items:order_items(name:item_name, qty:quantity)')
          .inFilter('status', ['pending', 'confirmed', 'preparing', 'ready'])
          .order('created_at', ascending: true);
      
      // ignore: avoid_print
      print('📦 [Admin Dashboard] Fetched ${data.length} orders');

      // Clean up the structure for the UI
      final orders = (data as List).map((o) {
        final profile = o['student_name'] as Map?;
        return {
          ...o,
          'order_id': o['id'],
          'student_name': profile?['full_name'] ?? 'Student',
          'created_at_fmt': o['created_at'] != null 
            ? DateTime.parse(o['created_at']).toLocal().toString().substring(11, 16) 
            : '',
        };
      }).toList();

      return {'success': true, 'data': orders};
    } catch (e) {
      // ignore: avoid_print
      print('🔥 [Admin Dashboard Error] $e');
      return {'success': false, 'message': 'Failed to load dashboard: $e'};
    }
  }

  static Future<Map<String, dynamic>> markOrderConfirmed(String orderId) {
    return RpcService.call('mark_order_confirmed',
        params: {'p_order_id': orderId});
  }

  static Future<Map<String, dynamic>> markOrderReady(String orderId) {
    return RpcService.call('mark_order_ready',
        params: {'p_order_id': orderId});
  }

  static Future<Map<String, dynamic>> markOrderCollected(String orderId) {
    return RpcService.call('mark_order_collected',
        params: {'p_order_id': orderId});
  }

  static Future<Map<String, dynamic>> toggleStore(bool open) {
    return RpcService.call('toggle_store', params: {'p_open': open});
  }

  static Future<Map<String, dynamic>> updateOrderLimit(int limit) {
    return RpcService.call('update_order_limit',
        params: {'p_new_limit': limit});
  }

  static Future<Map<String, dynamic>> updatePickupWindow(int minutes) {
    return RpcService.call('update_pickup_window',
        params: {'p_minutes': minutes});
  }

  static Future<Map<String, dynamic>> addNewItem({
    required String name,
    required double price,
    required int stock,
    String? description,
    String? category,
    String? imageUrl,
    int sortOrder = 0,
  }) {
    return RpcService.call('add_new_item', params: {
      'p_name': name,
      'p_price': price,
      'p_stock': stock,
      'p_description': description,
      'p_category': category,
      'p_image_url': imageUrl,
      'p_sort_order': sortOrder,
    });
  }

  static Future<Map<String, dynamic>> updateItem({
    required String itemId,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    int? sortOrder,
    int? stock,
  }) {
    return RpcService.call('update_item', params: {
      'p_item_id': itemId,
      'p_name': name,
      'p_description': description,
      'p_price': price,
      'p_image_url': imageUrl,
      'p_category': category,
      'p_sort_order': sortOrder,
      'p_stock': stock,
    });
  }

  static Future<Map<String, dynamic>> addItemStock(
      String itemId, int quantity) {
    return RpcService.call('add_item_stock', params: {
      'p_item_id': itemId,
      'p_quantity': quantity,
    });
  }

  static Future<Map<String, dynamic>> toggleItemAvailability(
      String itemId, bool available) {
    return RpcService.call('toggle_item_availability', params: {
      'p_item_id': itemId,
      'p_available': available,
    });
  }

  static Future<Map<String, dynamic>> systemHealth() {
    return RpcService.call('system_health');
  }

  // ─── Reports ──────────────────────────────────────────
  static Future<Map<String, dynamic>> getTodayReport() {
    final adminId = AuthService.currentUser?.id;
    if (adminId == null) {
      return Future.value(
          {'success': false, 'message': 'Not logged in', 'data': null});
    }
    return RpcService.call('get_today_report',
        params: {'p_admin_id': adminId});
  }

  static Future<Map<String, dynamic>> getWeeklySummary(
      {int weeksAgo = 0}) {
    final adminId = AuthService.currentUser?.id;
    if (adminId == null) {
      return Future.value(
          {'success': false, 'message': 'Not logged in', 'data': null});
    }
    return RpcService.call('get_weekly_summary', params: {
      'p_admin_id': adminId,
      'p_weeks_ago': weeksAgo,
    });
  }

  static Future<Map<String, dynamic>> getMonthlySummary({
    int? year,
    int? month,
  }) {
    final adminId = AuthService.currentUser?.id;
    if (adminId == null) {
      return Future.value(
          {'success': false, 'message': 'Not logged in', 'data': null});
    }
    return RpcService.call('get_monthly_summary', params: {
      'p_admin_id': adminId,
      'p_year': year,
      'p_month': month,
    });
  }

  static Future<Map<String, dynamic>> getLowStockAlerts() {
    return RpcService.call('get_low_stock_alerts');
  }

  static Future<Map<String, dynamic>> cleanupExpiredOrders() {
    return RpcService.call('cleanup_expired_orders');
  }

  // ─── Analytics & History ──────────────────────────────────
  
  static Future<Map<String, dynamic>> getAnalytics() async {
    return RpcService.call('get_admin_analytics');
  }

  static Future<Map<String, dynamic>> getPaymentHistory({
    String? studentName,
    String? status,
    String? date,
    int limit = 50,
  }) async {
    return RpcService.call('get_admin_payment_history', params: {
      'p_student_name': studentName,
      'p_status': status,
      'p_date': date,
    });
  }
}
