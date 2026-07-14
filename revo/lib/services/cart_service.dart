import 'package:supabase_flutter/supabase_flutter.dart';
import 'item_service.dart';

class CartService {
  static final _client = Supabase.instance.client;

  // ─── Fetch Cart ───────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> fetchCart() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final data = await _client
          .from('cart')
          .select('*, items(*)')
          .eq('user_id', userId);
      final list = (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      // ignore: avoid_print
      print('🛒 [Cart] Fetched ${list.length} items for: $userId');
      return list;
    } catch (e) {
      // ignore: avoid_print
      print('🔥 [Cart Error] fetchCart: $e');
      return [];
    }
  }

  // ─── Add / Update Cart ────────────────────────────────────────────────────

  static Future<bool> addToCart(String itemId, int quantity) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final existing = await _client
          .from('cart')
          .select()
          .eq('user_id', userId)
          .eq('item_id', itemId)
          .maybeSingle();

      if (existing != null) {
        await _client
            .from('cart')
            .update({'quantity': ((existing['quantity'] as num?)?.toInt() ?? 0) + quantity})
            .eq('id', existing['id']);
      } else {
        await _client.from('cart').insert({
          'user_id': userId,
          'item_id': itemId,
          'quantity': quantity,
        });
      }
      // ignore: avoid_print
      print('🛒 [Cart] Updated/Added item $itemId for user: $userId');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('🔥 [Cart Error] addToCart: $e');
      return false;
    }
  }

  static Future<bool> updateQuantity(String cartId, int quantity) async {
    try {
      if (quantity <= 0) {
        await _client.from('cart').delete().eq('id', cartId);
      } else {
        await _client.from('cart').update({'quantity': quantity}).eq('id', cartId);
      }
      // ignore: avoid_print
      print('🛒 [Cart] Updated qty for $cartId to $quantity');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('🔥 [Cart Error] updateQuantity: $e');
      return false;
    }
  }

  // ─── Clear Cart ───────────────────────────────────────────────────────────

  static Future<bool> clearCart() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      await _client.from('cart').delete().eq('user_id', userId);
      // ignore: avoid_print
      print('🛒 [Cart] Cleared for user: $userId');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('🔥 [Cart Error] clearCart: $e');
      return false;
    }
  }

  // ─── Place Order (with Stock Deduction) ───────────────────────────────────

  static Future<Map<String, dynamic>> placeOrder(
      double total, List<Map<String, dynamic>> cartItems) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return {'success': false, 'message': 'User not logged in'};
    }

    try {
      // Step 1: Validate stock for all items before placing order
      for (final cartRow in cartItems) {
        final item = cartRow['items'] as Map<String, dynamic>?;
        if (item == null) continue;

        final orderedQty = (cartRow['quantity'] as num?)?.toInt() ?? 1;
        final availableStock = (item['stock'] as num?)?.toInt() ?? 0;

        if (availableStock < orderedQty) {
          return {
            'success': false,
            'message':
                '${item['name']} only has $availableStock in stock. Please update your cart.',
          };
        }
      }

      // Step 2: Create order record
      final order = await _client.from('orders').insert({
        'user_id': userId,
        'total_amount': total,
        'status': 'preparing',
      }).select().maybeSingle();

      if (order == null) throw Exception('Failed to create order');
      final orderId = order['id'];

      // Step 3: Create order items & deduct stock
      for (final cartRow in cartItems) {
        final item = cartRow['items'] as Map<String, dynamic>?;
        if (item == null) continue;

        final itemId = item['id'] as String;
        final itemName = item['name'] as String;
        final unitPrice = (item['price'] as num).toDouble();
        final orderedQty = (cartRow['quantity'] as num?)?.toInt() ?? 1;

        // Insert into order_items
        await _client.from('order_items').insert({
          'order_id': orderId,
          'item_id': itemId,
          'item_name': itemName,
          'quantity': orderedQty,
          'unit_price': unitPrice,
          'subtotal': unitPrice * orderedQty,
        });

        // Deduct stock
        await ItemService.deductStock(itemId, orderedQty);
      }

      // Step 4: Clear cart
      await clearCart();

      return {
        'success': true,
        'message': 'Order placed successfully!',
        'data': order,
      };
    } catch (e) {
      // ignore: avoid_print
      print('🔥 [Cart Error] placeOrder: $e');
      return {'success': false, 'message': 'Checkout failed: $e'};
    }
  }
}
