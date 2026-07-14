import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/pickup_countdown.dart';
import '../../config/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      body: admin.loading && admin.orders.isEmpty
          ? const Center(
              child: CircularProgressIndicator())
          : admin.orders.isEmpty
              ? _emptyState(admin)
              : RefreshIndicator(
                  onRefresh: () => admin.loadDashboard(),
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    cacheExtent: 500, // Pre-render cards for smooth scrolling
                    itemCount: admin.orders.length + 1,
                    itemBuilder: (ctx, i) {
                      if (i == 0) return _header(admin);
                      final order = admin.orders[i - 1];
                      return RepaintBoundary(
                        child: _OrderCard(
                          order: order,
                          onConfirm: () => _confirmOrder(order['order_id']),
                          onMarkReady: () => _markReady(order['order_id']),
                          onMarkDelivered: () => _markCollected(order['order_id']),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _header(AdminProvider admin) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LIVE ORDERS',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Processing Queue (FIFO)',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.brandPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '● ${admin.orders.length} ACTIVE TICKETS',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.brandPrimary,
                  letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(AdminProvider admin) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inbox_outlined,
                size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          const Text('No active orders',
              style:
                  TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'There are currently no orders requiring\nyour attention. New orders will appear\nhere automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => admin.loadDashboard(),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 48)),
            child: const Text('REFRESH DASHBOARD'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmOrder(String orderId) async {
    final messenger = ScaffoldMessenger.of(context);
    final admin = context.read<AdminProvider>();
    final ok = await admin.confirmOrder(orderId);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
          content:
              Text(ok ? 'Order confirmed' : admin.error ?? 'Failed')),
    );
  }

  Future<void> _markReady(String orderId) async {
    final messenger = ScaffoldMessenger.of(context);
    final admin = context.read<AdminProvider>();
    final ok = await admin.markReady(orderId);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
          content:
              Text(ok ? 'Order marked ready' : admin.error ?? 'Failed')),
    );
  }

  Future<void> _markCollected(String orderId) async {
    final messenger = ScaffoldMessenger.of(context);
    final admin = context.read<AdminProvider>();
    final ok = await admin.markCollected(orderId);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
          content: Text(
              ok ? 'Order marked as delivered' : admin.error ?? 'Failed')),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onConfirm;
  final VoidCallback onMarkReady;
  final VoidCallback onMarkDelivered;

  const _OrderCard({
    required this.order,
    required this.onConfirm,
    required this.onMarkReady,
    required this.onMarkDelivered,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString() ?? 'pending';
    final token = order['token_number'];
    final name = order['student_name'] ?? 'Student';
    final items = order['items'] as List? ?? [];
    final time = order['created_at_fmt'] ?? '';
    final orderId = (order['order_id'] ?? '').toString();
    final shortId =
        orderId.length > 8 ? orderId.substring(0, 8) : orderId;
    
    final isPending = status == 'pending';
    final isConfirmed = status == 'confirmed' || status == 'preparing';
    final isReady = status == 'ready';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
            color: isReady ? AppTheme.brandSecondary : AppTheme.slate200),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepNavy.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOKEN NUMBER',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: Colors.grey.shade500)),
                    Text(
                      token != null
                          ? token.toString().padLeft(3, '0')
                          : '---',
                      style: const TextStyle(
                          fontSize: 40, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: status),
            ],
          ),
          if (isReady && order['ready_at'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: AppTheme.brandAccent),
                const SizedBox(width: 8),
                const Text('COLLECT IN: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.brandAccent)),
                PickupCountdown(
                  deadline: order['pickup_deadline'],
                  compact: true,
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              Text('ORD-${shortId.toUpperCase()}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('${item['qty']}×',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${item['name']}',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
          if (time.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(time,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: isPending
                ? ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandAccent),
                    child: const Text('CONFIRM ORDER'),
                  )
                : isConfirmed
                    ? OutlinedButton(
                        onPressed: onMarkReady,
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48)),
                        child: const Text('MARK READY'),
                      )
                    : isReady
                        ? ElevatedButton(
                            onPressed: onMarkDelivered,
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPrimary),
                            child: const Text('MARK DELIVERED'),
                          )
                        : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
