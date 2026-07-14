import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized RPC caller that wraps every backend call in the standard
/// `{ success, message, data }` response format defined in PRD Section B.
class RpcService {
  static final _client = Supabase.instance.client;

  /// Calls an RPC function in the `revo` schema and returns the standard
  /// response map.
  static Future<Map<String, dynamic>> call(
    String function, {
    Map<String, dynamic>? params,
  }) async {
    try {
      final data = await _client.rpc(function, params: params);

      // Detailed logging for debugging
      // ignore: avoid_print
      print('🚀 [RPC Call] $function | Params: $params | Res: $data');

      // The function returns JSONB. Supabase decodes it to Map/List.
      if (data is Map<String, dynamic>) {
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'OK',
          'data': data['data'],
        };
      }

      // Some functions (e.g. cleanup) return scalars.
      return {'success': true, 'message': 'OK', 'data': data};
    } on PostgrestException catch (e) {
      // ignore: avoid_print
      print('❌ [RPC Error] $function | code: ${e.code} | msg: ${e.message}');
      return {
        'success': false,
        'message': _parseError(e.message),
        'data': null,
      };
    } on AuthException catch (e) {
      // ignore: avoid_print
      print('🔐 [Auth Error] $function | msg: ${e.message}');
      return {
        'success': false,
        'message': e.message,
        'data': null,
      };
    } catch (e) {
      // ignore: avoid_print
      print('🔥 [System Error] $function | error: $e');
      return {
        'success': false,
        'message': 'Network error. Please try again.',
        'data': null,
      };
    }
  }

  /// Strips the error-code prefix (e.g. "STORE_CLOSED: ...") and returns
  /// a user-friendly message.
  static String _parseError(String raw) {
    final idx = raw.indexOf(': ');
    if (idx > 0 && idx < 30) return raw.substring(idx + 2);
    return raw;
  }
}
