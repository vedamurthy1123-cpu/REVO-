import 'package:supabase_flutter/supabase_flutter.dart';
import 'rpc_service.dart';

class WalletService {
  static final _client = Supabase.instance.client;

  // ── Get wallet balance (no arg — auth.uid() used server-side) ─────────────
  static Future<Map<String, dynamic>> getBalance() async {
    try {
      final data = await _client.rpc('get_wallet_balance');
      if (data is Map<String, dynamic>) {
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'OK',
          'data': data['data'],
        };
      }
      return {'success': true, 'message': 'OK', 'data': data};
    } on PostgrestException catch (e) {
      return {'success': false, 'message': e.message, 'data': null};
    } catch (e) {
      return {'success': false, 'message': 'Network error.', 'data': null};
    }
  }

  // ── Get transaction history ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> getHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final data = await _client
          .rpc('get_wallet_history', params: {'p_limit': limit, 'p_offset': offset});
      if (data is Map<String, dynamic>) {
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'OK',
          'data': data['data'],
        };
      }
      return {'success': true, 'message': 'OK', 'data': data};
    } on PostgrestException catch (e) {
      return {'success': false, 'message': e.message, 'data': null};
    } catch (e) {
      return {'success': false, 'message': 'Network error.', 'data': null};
    }
  }

  // ── Topup wallet (dummy — no real gateway) ────────────────────────────────
  static Future<Map<String, dynamic>> topup(double amount) async {
    return RpcService.call('topup_wallet', params: {'p_amount': amount});
  }

  // ── Atomic: place order + pay with wallet in one DB transaction ───────────
  static Future<Map<String, dynamic>> placeAndPayWithWallet(
      List<Map<String, dynamic>> items) async {
    return RpcService.call('place_and_pay_with_wallet', params: {
      'p_items': items,
    });
  }
}
