import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/status_badge.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    final orders = context.read<OrderProvider>();
    Future.microtask(() => orders.fetchHistory());
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History', 
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: prov.loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.black))
          : prov.history.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No orders yet',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: Colors.black,
                  onRefresh: () => prov.fetchHistory(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: prov.history.length + 1,
                    itemBuilder: (ctx, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ORDER MANAGEMENT',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.5,
                                      color: Colors.grey.shade500)),
                              const SizedBox(height: 4),
                              const Text('Order History',
                                  style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        );
                      }
                      final order = prov.history[i - 1];
                      return _OrderHistoryCard(order: order);
                    },
                  ),
                ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderHistoryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString() ?? '';
    final total = (order['total_amount'] as num?)?.toDouble() ?? 0;
    final items = order['items'] as List? ?? [];
    final date = order['created_at_fmt'] ?? '';
    final orderId = (order['order_id'] ?? '').toString();
    final shortId = orderId.length > 8 ? orderId.substring(0, 8) : orderId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('ORDER #${shortId.toUpperCase()}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: Colors.grey.shade500)),
              ),
              StatusBadge(status: status),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey.shade400),
                onPressed: () => _confirmDelete(context, orderId),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('₹${total.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...items.take(2).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${item['quantity'] ?? item['qty'] ?? 1}× ${item['name'] ?? ''}',
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )),
          if (items.length > 2)
            Text('+${items.length - 2} more',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(date,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
          if (order['refund_status'] != null &&
              order['refund_status'] != 'none') ...[
            const SizedBox(height: 8),
            Text('Refund: ${order['refund_status']}',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete History?'),
        content: const Text('This will remove this order from your history. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final prov = context.read<OrderProvider>();
              final res = await prov.deleteHistoryOrder(orderId);
              
              if (!context.mounted) return;
              if (!res['success']) {
                messenger.showSnackBar(
                  SnackBar(content: Text(res['message'] ?? 'Delete failed')),
                );
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
