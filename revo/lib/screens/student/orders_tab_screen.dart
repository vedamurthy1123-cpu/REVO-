import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../config/app_theme.dart';
import '../../widgets/pickup_countdown.dart';

class OrdersTabScreen extends StatefulWidget {
  const OrdersTabScreen({super.key});

  @override
  State<OrdersTabScreen> createState() => _OrdersTabScreenState();
}

class _OrdersTabScreenState extends State<OrdersTabScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<OrderProvider>().fetchActiveOrder();
      }
    });
    _subscribeToOrderUpdates();
    setState(() => _loading = false);
  }

  void _subscribeToOrderUpdates() {
    context.read<OrderProvider>().subscribeToActiveOrder(); 
  }

  @override
  void dispose() {
    // Subscription managed by provider
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final latestOrder = orderProvider.activeOrder;

    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
      );
    }

    if (latestOrder == null) {
      return _buildEmptyState();
    }

    final status = latestOrder['status'];
    final isFinalized = status == 'delivered' ||
        status == 'collected' ||
        status == 'expired' ||
        status == 'cancelled';

    if (isFinalized) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      body: RefreshIndicator(
        onRefresh: () => orderProvider.fetchActiveOrder(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildIntegratedTrackingCard(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Tracking',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
        ),
        SizedBox(height: 4),
        Text(
          'Your order is being processed in real-time',
          style: TextStyle(color: AppTheme.slate500, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildIntegratedTrackingCard() {
    final order = context.read<OrderProvider>().activeOrder!;
    final orderId = order['id'].toString();
    final shortId = orderId.length > 8 ? orderId.substring(0, 8) : orderId;
    final token = order['token_number'];
    final total = order['total_amount'] ?? 0;
    final status = order['status']?.toString() ?? 'pending';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepNavy.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Summary Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppTheme.deepNavy,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ORDER ID',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.slate500,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text('#${shortId.toUpperCase()}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('TOKEN',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.slate500,
                              letterSpacing: 1)),
                      Text(
                        token != null ? token.toString().padLeft(3, '0') : '---',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Tracking Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVerticalTracking(status),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoItem(Icons.payments_outlined, 'Total Amount', '₹$total'),
                    _buildTimerDisplay(status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.slate50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppTheme.brandPrimary),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.slate500, fontWeight: FontWeight.w600)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.deepNavy)),
          ],
        ),
      ],
    );
  }

  Widget _buildVerticalTracking(String status) {
    final steps = [
      _Step(
        label: 'Order Placed',
        description: 'Waiting for shop confirmation',
        icon: Icons.receipt_long_outlined,
        isDone: true,
        isActive: status == 'pending',
      ),
      _Step(
        label: 'Confirmed',
        description: 'Store has accepted your order',
        icon: Icons.thumb_up_outlined,
        isDone: status != 'pending',
        isActive: status == 'confirmed' || status == 'preparing',
      ),
      _Step(
        label: 'Ready for Pickup',
        description: 'Visit the store to collect',
        icon: Icons.inventory_2_outlined,
        isDone: status == 'delivered' || status == 'collected',
        isActive: status == 'ready',
      ),
      _Step(
        label: 'Delivered',
        description: 'Enjoy your purchase!',
        icon: Icons.celebration_outlined,
        isDone: status == 'delivered' || status == 'collected',
        isActive: false,
      ),
    ];

    return Column(
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final isLast = i == steps.length - 1;
        
        final color = step.isDone
            ? AppTheme.brandPrimary
            : (step.isActive ? AppTheme.brandAccent : AppTheme.slate200);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: step.isDone || step.isActive ? color : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Icon(
                      step.isDone ? Icons.check : step.icon,
                      size: 18,
                      color: step.isDone || step.isActive ? Colors.white : AppTheme.slate200,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: step.isDone ? AppTheme.brandPrimary : AppTheme.slate200,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              Padding(
                padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.label,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: step.isDone || step.isActive ? FontWeight.w800 : FontWeight.w600,
                        color: step.isDone || step.isActive ? AppTheme.deepNavy : AppTheme.slate500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: step.isActive ? AppTheme.brandAccent : AppTheme.slate500,
                        fontWeight: step.isActive ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTimerDisplay(String status) {
    final order = context.read<OrderProvider>().activeOrder;
    if (status != 'ready' || order == null || order['ready_at'] == null) {
      return const SizedBox.shrink();
    }

    return PickupCountdown(
      deadline: order['pickup_deadline'],
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppTheme.deepNavy.withValues(alpha: 0.05), blurRadius: 20),
                  ],
                ),
                child: const Icon(Icons.shopping_bag_outlined, size: 70, color: AppTheme.slate200),
              ),
              const SizedBox(height: 32),
              const Text(
                'No orders, make orders',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.deepNavy),
              ),
              const SizedBox(height: 12),
              const Text(
                'Once you place an order, you can track its live progress here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.slate500, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                child: const Text('START SHOPPING'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step {
  final String label;
  final String description;
  final IconData icon;
  final bool isDone;
  final bool isActive;

  _Step({
    required this.label,
    required this.description,
    required this.icon,
    required this.isDone,
    required this.isActive,
  });
}
