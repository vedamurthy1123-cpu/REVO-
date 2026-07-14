import 'package:supabase_flutter/supabase_flutter.dart';
import 'rpc_service.dart';

class OrderService {
  static Future<Map<String, dynamic>> placeOrder(
      List<Map<String, dynamic>> items) {
    return RpcService.call('place_order', params: {'p_items': items});
  }

  static Future<Map<String, dynamic>> dummyPay(String orderId) {
    return RpcService.call('dummy_pay', params: {'p_order_id': orderId});
  }

  static Future<Map<String, dynamic>> getActiveOrder() async {
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('orders')
          .select('*, items:order_items(name:item_name, qty:quantity)')
          .inFilter('status', ['pending', 'confirmed', 'preparing', 'ready', 'expired'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // ignore: avoid_print
      print('🛒 [Order Service] Active Order: ${res != null ? 'Found' : 'Not Found'}');

      return {'success': true, 'data': res};
    } catch (e) {
      // ignore: avoid_print
      print('🔥 [Order Service Error] getActiveOrder: $e');
      return {'success': false, 'message': 'Failed to load active order: $e'};
    }
  }

  static Future<Map<String, dynamic>> getOrderHistory({
    int limit = 20,
    int offset = 0,
  }) {
    return RpcService.call('get_order_history', params: {
      'p_limit': limit,
      'p_offset': offset,
    });
  }

  static Future<Map<String, dynamic>> confirmReceived(String orderId) {
    return RpcService.call('student_confirm_received',
        params: {'p_order_id': orderId});
  }

  static Future<Map<String, dynamic>> deleteHistoryOrder(String orderId) {
    return RpcService.call('student_delete_history_order',
        params: {'p_order_id': orderId});
  }

  /// Fetches the single most recent order for the Orders Tab tracking UI.
  /// Does NOT affect order_history_screen or the active-order tracking flow.
  static Future<Map<String, dynamic>> getLatestOrderForTracking() async {
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('orders')
          .select('*, items:order_items(name:item_name, qty:quantity)')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // ignore: avoid_print
      print('📊 [Tracking UI] Latest Order: ${res != null ? 'Found' : 'Not Found'}');

      return {'success': true, 'data': res};
    } catch (e) {
      // ignore: avoid_print
      print('🔥 [Order Service Error] getLatestOrder: $e');
      return {'success': false, 'message': 'Tracking failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> cleanupExpiredOrders() {
    return RpcService.call('cleanup_expired_orders');
  }
}
