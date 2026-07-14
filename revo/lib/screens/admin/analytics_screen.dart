import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_provider.dart';
import '../../constants/keys.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    if (!mounted) return;
    await context.read<AdminProvider>().loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final data = admin.analytics;

    if (admin.error != null && admin.analytics == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${admin.error}', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => admin.loadAnalytics(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (data == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: () => admin.loadAnalytics(),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text('Sales Analytics',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
              Text('Real-time store performance & controls',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
              const SizedBox(height: 32),

              // Store Management Controls
              _sectionHeader('Store Management'),
              const SizedBox(height: 16),
              _storeManagementCard(admin),

              const SizedBox(height: 32),

              // Overview Cards
              _sectionHeader('Sales Overview'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      'TODAY REVENUE',
                      '₹${data['today_revenue']}',
                      Icons.account_balance_wallet,
                      Colors.black,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _statCard(
                      'TOTAL ORDERS',
                      '${data['today_orders']}',
                      Icons.shopping_bag,
                      Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Revenue Graph
              _sectionHeader('Revenue Trend (7 Days)'),
              const SizedBox(height: 16),
              _chartContainer(
                height: 200,
                child: LineChart(_revenueChart(data['revenue_series'])),
              ),

              const SizedBox(height: 32),

              // Top Selling Items
              _sectionHeader('Top Selling Items'),
              const SizedBox(height: 16),
              _topItemsList(data['top_items']),

              const SizedBox(height: 32),

              // Stock Alerts
              _sectionHeader('Inventory Alerts'),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _stockAlertList('LOW STOCK', data['low_stock'], Colors.orange)),
                  const SizedBox(width: 16),
                  Expanded(child: _stockAlertList('OUT OF STOCK', data['out_of_stock'], Colors.red)),
                ],
              ),

              const SizedBox(height: 32),

              // Order Status Distribution
              _sectionHeader('Order Status Distribution'),
              const SizedBox(height: 16),
              _chartContainer(
                height: 200,
                child: PieChart(_statusPieChart(data['order_status_stats'])),
              ),

              const SizedBox(height: 32),

              // Restock Insights
              _sectionHeader('Restock Recommendations'),
              const SizedBox(height: 16),
              _restockList(data['restock_recommendations']),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _restockList(dynamic items) {
    final list = items as List? ?? [];
    if (list.isEmpty) return const Center(child: Text('Inventory is healthy'));
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: list.map((item) {
          return ListTile(
            leading: const Icon(Icons.inventory, color: Colors.blue),
            title: Text(item['name'], 
              style: const TextStyle(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis),
            subtitle: Text('Recommended: Bring ${item['recommend_qty']} more'),
            trailing: const Icon(Icons.chevron_right, size: 16),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title.toUpperCase(),
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Colors.grey));
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _chartContainer({required double height, required Widget child}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: child,
    );
  }

  Widget _topItemsList(dynamic items) {
    if (items == null || items is! List || items.isEmpty) {
      return const Center(child: Text('No sales data yet'));
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: items.map<Widget>((item) {
          return ListTile(
            title: Text(item['name'], 
              style: const TextStyle(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: Text('${item['sold']} sold', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _stockAlertList(String title, dynamic items, Color color) {
    final list = items as List? ?? [];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const Text('All clear', style: TextStyle(color: Colors.grey, fontSize: 12))
          else
            ...list.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• ${item['name']}${item['stock'] != null ? ' (${item['stock']})' : ''}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                )),
        ],
      ),
    );
  }

  LineChartData _revenueChart(dynamic series) {
    final list = series as List? ?? [];
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: list.asMap().entries.map((e) {
            return FlSpot(e.key.toDouble(), (e.value['total_revenue'] as num).toDouble());
          }).toList(),
          isCurved: true,
          color: Colors.black,
          barWidth: 4,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ],
    );
  }

  PieChartData _statusPieChart(dynamic stats) {
    if (stats == null || (stats as Map).isEmpty) {
      return PieChartData(sections: [
        PieChartSectionData(
          value: 100,
          title: '',
          color: Colors.grey.shade200,
          radius: 50,
        )
      ]);
    }
    final map = stats as Map<String, dynamic>;
    final List<PieChartSectionData> sections = [];
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple];
    int i = 0;
    map.forEach((key, value) {
      if ((value as num) > 0) {
        sections.add(PieChartSectionData(
          value: value.toDouble(),
          title: key.substring(0, 1).toUpperCase(),
          color: colors[i % colors.length],
          radius: 50,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ));
      }
      i++;
    });

    if (sections.isEmpty) {
      return PieChartData(sections: [
        PieChartSectionData(
          value: 100,
          title: '',
          color: Colors.grey.shade200,
          radius: 50,
        )
      ]);
    }

    return PieChartData(sections: sections, centerSpaceRadius: 40);
  }

  Widget _storeManagementCard(AdminProvider admin) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          // Store Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Store Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(admin.isStoreOpen ? 'Accepting new orders' : 'Store is currently closed',
                      style: TextStyle(color: admin.isStoreOpen ? Colors.green : Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              Switch.adaptive(
                value: admin.isStoreOpen,
                activeTrackColor: Colors.green.withValues(alpha: 0.5),
                activeThumbColor: Colors.green,
                onChanged: (val) async {
                  final success = await admin.toggleStore(val);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success 
                          ? (val ? '🏪 Store is now OPEN' : '🏪 Store is now CLOSED')
                          : '❌ Failed to change store status'),
                        backgroundColor: success ? Colors.blue : Colors.red,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1),
          ),
          // Max Orders & Pickup Window
          Row(
            children: [
              Expanded(
                child: _managementInput(
                  label: 'MAX ORDERS',
                  value: admin.settings?['max_active_orders']?.toString() ?? '50',
                  icon: Icons.shopping_cart_checkout,
                  onTap: () => _showInputDialog(
                    title: 'Update Max Orders',
                    initialValue: admin.settings?['max_active_orders']?.toString() ?? '50',
                    onSave: (val) => admin.updateMaxOrders(int.parse(val)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _managementInput(
                  label: 'PICKUP WINDOW',
                  value: '${admin.settings?['pickup_window_minutes'] ?? 10} MIN',
                  icon: Icons.timer_outlined,
                  onTap: () => _showInputDialog(
                    title: 'Update Pickup Window',
                    initialValue: admin.settings?['pickup_window_minutes']?.toString() ?? '10',
                    suffix: ' minutes',
                    onSave: (val) => admin.updatePickupWindow(int.parse(val)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _managementInput({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  void _showInputDialog({
    required String title,
    required String initialValue,
    String? suffix,
    required Future<bool> Function(String) onSave,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: suffix,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final val = controller.text;
              if (val.isEmpty) return;
              
              Navigator.pop(ctx);
              
              final success = await onSave(val);
              
              // Use rootScaffoldMessengerKey to avoid "removeChild" null errors on Web
              rootScaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(
                  content: Text(success ? '✅ Settings updated successfully' : '❌ Update failed'),
                  backgroundColor: success ? Colors.green : Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
}
