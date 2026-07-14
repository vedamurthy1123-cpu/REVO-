import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/item_service.dart';

class ItemsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _settings;
  RealtimeChannel? _channel;

  List<Map<String, dynamic>> get items => _items;
  bool get loading => _loading;
  String? get error => _error;
  Map<String, dynamic>? get settings => _settings;
  bool get isStoreOpen => _settings?['is_store_open'] == true;

  // ─── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadItems() async {
    _loading = true;
    _error = null;
    notifyListeners();
    _items = await ItemService.fetchItems();
    _settings = await ItemService.fetchAdminSettings();
    _loading = false;
    notifyListeners();
  }

  Future<void> loadAllItems() async {
    _loading = true;
    notifyListeners();
    _items = await ItemService.fetchAllItems();
    _settings = await ItemService.fetchAdminSettings();
    _loading = false;
    notifyListeners();
  }

  Future<void> refreshSettings() async {
    _settings = await ItemService.fetchAdminSettings();
    notifyListeners();
  }

  // ─── Realtime Subscription ────────────────────────────────────────────────

  /// Call this once (e.g. in HomeScreen initState) to get live product updates.
  void subscribeToItems() {
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('public-items')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'items',
          callback: (payload) {
            debugPrint('[Realtime] items changed: ${payload.eventType}');
            _handleRealtimeChange(payload);
          },
        )
        .subscribe();
  }

  void _handleRealtimeChange(PostgresChangePayload payload) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        final newRow = payload.newRecord;
        if (newRow.isNotEmpty) {
          _items = [..._items, newRow];
          _items.sort((a, b) =>
              (a['name'] as String).compareTo(b['name'] as String));
          notifyListeners();
        }
        break;

      case PostgresChangeEvent.update:
        final updated = payload.newRecord;
        final idx = _items.indexWhere((p) => p['id'] == updated['id']);
        if (idx >= 0) {
          _items = List.from(_items)..[idx] = updated;
          notifyListeners();
        }
        break;

      case PostgresChangeEvent.delete:
        final oldId = payload.oldRecord['id'];
        _items = _items.where((p) => p['id'] != oldId).toList();
        notifyListeners();
        break;

      default:
        // For any other event, do a full refresh
        loadItems();
    }
  }

  void unsubscribe() {
    _channel?.unsubscribe();
    _channel = null;
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  List<String> get categories {
    final cats = <String>{};
    for (final item in _items) {
      if (item['category'] != null &&
          (item['category'] as String).isNotEmpty) {
        cats.add(item['category']);
      }
    }
    return cats.toList()..sort();
  }

  List<Map<String, dynamic>> itemsByCategory(String cat) {
    return _items.where((i) => i['category'] == cat).toList();
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }
}
