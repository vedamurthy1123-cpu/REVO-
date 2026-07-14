import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemService {
  static final _client = Supabase.instance.client;

  // ─── Fetch ─────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> fetchItems() async {
    try {
      final data = await _client
          .from('items')
          .select()
          .order('name', ascending: true);
      final items = (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      // ignore: avoid_print
      print('🛍️ [Items] Fetched ${items.length} items');
      return items;
    } catch (e) {
      // ignore: avoid_print
      print('🔥 [Items Error] fetchItems: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAllItems() async {
    try {
      final data = await _client
          .from('items')
          .select()
          .order('name', ascending: true);
      final items = (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      // ignore: avoid_print
      print('🛍️ [Items] Fetched all ${items.length} items (admin)');
      return items;
    } catch (e) {
      // ignore: avoid_print
      print('🔥 [Items Error] fetchAllItems: $e');
      return [];
    }
  }

  // ─── Add ───────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> addItem({
    required String name,
    required double price,
    required int stock,
    String? description,
    String? category,
    String? imageUrl,
  }) async {
    try {
      final data = await _client.from('items').insert({
        'name': name,
        'price': price,
        'stock': stock,
        'description': description,
        'category': category,
        'image_url': imageUrl,
        'is_available': true,
      }).select().maybeSingle();
      if (data == null) throw Exception('Failed to insert item');
      return {'success': true, 'data': data};
    } catch (e) {
      // ignore: avoid_print
      print('🔥 [Items Error] addItem: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─── Update ────────────────────────────────────────────────────────────────

  static Future<bool> updateItem({
    required String itemId,
    String? name,
    double? price,
    int? stock,
    String? imageUrl,
    String? description,
    String? category,
  }) async {
    try {
      final updates = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};
      if (name != null) updates['name'] = name;
      if (price != null) updates['price'] = price;
      if (stock != null) {
        updates['stock'] = stock;
        updates['is_available'] = stock > 0;
      }
      if (imageUrl != null) updates['image_url'] = imageUrl;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category;

      await _client.from('items').update(updates).eq('id', itemId);
      // ignore: avoid_print
      print('📝 [Items] Updated item: $itemId');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('🔥 [Items Error] updateItem: $e');
      return false;
    }
  }

  // ─── Stock ─────────────────────────────────────────────────────────────────

  static Future<bool> addStock(String itemId, int quantity) async {
    try {
      // Get current stock first
      final current = await _client
          .from('items')
          .select('stock')
          .eq('id', itemId)
          .maybeSingle();
      if (current == null) return false;
      final newStock = ((current['stock'] as num?)?.toInt() ?? 0) + quantity;
      await _client.from('items').update({
        'stock': newStock,
        'is_available': newStock > 0,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', itemId);
      // ignore: avoid_print
      print('📈 [Items] Added $quantity stock to: $itemId');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('🔥 [Items Error] addStock: $e');
      return false;
    }
  }

  static Future<bool> deductStock(String itemId, int quantity) async {
    try {
      final current = await _client
          .from('items')
          .select('stock')
          .eq('id', itemId)
          .maybeSingle();
      if (current == null) return false;
      final currentStock = (current['stock'] as num?)?.toInt() ?? 0;
      if (currentStock < quantity) return false;
      final newStock = currentStock - quantity;
      await _client.from('items').update({
        'stock': newStock,
        'is_available': newStock > 0,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', itemId);
      // ignore: avoid_print
      print('📉 [Items] Deducted $quantity stock from: $itemId');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('🔥 [Items Error] deductStock: $e');
      return false;
    }
  }

  // ─── Toggle ────────────────────────────────────────────────────────────────

  static Future<bool> toggleAvailability(String itemId, bool available) async {
    try {
      await _client.from('items').update({
        'is_available': available,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', itemId);
      return true;
    } catch (e) {
      debugPrint('Error toggling availability: $e');
      return false;
    }
  }

  // ─── Delete ────────────────────────────────────────────────────────────────
  
  static Future<bool> deleteItem(String itemId) async {
    try {
      await _client.from('items').delete().eq('id', itemId);
      // ignore: avoid_print
      print('🗑️ [Items] Deleted item: $itemId');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('🔥 [Items Error] deleteItem: $e');
      return false;
    }
  }

  // ─── Admin Settings ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> fetchAdminSettings() async {
    try {
      return await _client
          .from('admin_settings')
          .select()
          .eq('id', 1)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  static Future<bool> updateAdminSettings(Map<String, dynamic> updates) async {
    try {
      await _client
          .from('admin_settings')
          .update(updates)
          .eq('id', 1);
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('🔥 [Items Error] updateAdminSettings: $e');
      return false;
    }
  }
}
