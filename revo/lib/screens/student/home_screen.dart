import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/items_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/item_card.dart';
import '../../widgets/pickup_countdown.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  @override
  void initState() {
    super.initState();
    final items = context.read<ItemsProvider>();
    final orders = context.read<OrderProvider>();
    Future.microtask(() {
      items.loadItems();
      items.subscribeToItems(); // 🔴 Realtime: live product updates
      orders.fetchActiveOrder();
      orders.subscribeToActiveOrder(); // 🔴 Realtime: live order updates
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    context.read<ItemsProvider>().unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<ItemsProvider>();
    final cart = context.watch<CartProvider>();
    final order = context.watch<OrderProvider>();

    return Scaffold(
      body: RefreshIndicator(
        color: Colors.black,
        onRefresh: () async {
          await items.loadItems();
          await order.fetchActiveOrder();
        },
        child: CustomScrollView(
          slivers: [
            // Active order banner
            if (order.hasActiveOrder)
              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/home', (route) => false,
                          arguments: 1),
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long,
                            color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Active Order',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              if (order.activeOrder?['status'] == 'ready' && order.activeOrder?['ready_at'] != null)
                                Row(
                                  children: [
                                    const Text('COLLECT IN: ', style: TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.w800)),
                                    PickupCountdown(
                                      deadline: order.activeOrder!['pickup_deadline'],
                                      compact: true,
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  'Status: ${(order.activeOrder?['status'] ?? '').toString().toUpperCase()}',
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ),

            // Store closed banner
            if (!items.isStoreOpen && !items.loading)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.store, color: Colors.red.shade400),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Store is currently closed',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search stationery...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintStyle: TextStyle(
                                color: Colors.grey.shade500, fontSize: 14),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Loading state
            if (items.loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Colors.black)),
              ),

            // Items list
            if (!items.loading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final filteredItems = items.items.where((item) {
                        final name = (item['name'] ?? '').toString().toLowerCase();
                        return name.contains(_searchQuery.toLowerCase());
                      }).toList();

                      if (i >= filteredItems.length) return null;

                      final item = filteredItems[i];
                      final id = item['id'] as String;
                      return ItemCard(
                        item: item,
                        inCart: cart.isInCart(id),
                        cartQty: cart.getQuantity(id),
                        onAdd: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await cart.addItem(id);
                          if (!context.mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('${item['name']} added to cart'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        onBuy: () async {
                          final navigator = Navigator.of(context);
                          await cart.addItem(id);
                          if (!context.mounted) return;
                          navigator.pushNamed('/cart');
                        },
                      );
                    },
                    childCount: items.items.where((item) {
                      final name = (item['name'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery.toLowerCase());
                    }).length,
                  ),
                ),
              ),

            // Empty state
            if (!items.loading)
              Builder(builder: (context) {
                final filtered = items.items.where((item) {
                  final name = (item['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery.toLowerCase());
                }).toList();

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _searchQuery.isEmpty 
                                ? Icons.inventory_2_outlined 
                                : Icons.search_off,
                            size: 64, 
                            color: Colors.grey
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty 
                                ? 'No items available' 
                                : 'No results for "$_searchQuery"',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }),
          ],
        ),
      ),
    );
  }
}
