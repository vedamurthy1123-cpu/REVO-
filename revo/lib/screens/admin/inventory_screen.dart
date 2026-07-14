import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/revo_switch.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<AdminProvider>().loadInventory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      body: admin.loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : RefreshIndicator(
              color: Colors.black,
              onRefresh: () => admin.loadInventory(),
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: admin.allItems.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Inventory',
                                    style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.pushNamed(context, '/add-item');
                              if (context.mounted) {
                                context.read<AdminProvider>().loadInventory();
                              }
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Item'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (admin.allItems.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: Text('No items yet. Tap "Add Item" to start.',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }

                  final item = admin.allItems[i - 1];
                  return _InventoryCard(
                    item: item,
                    onToggle: (val) => admin.toggleItemAvail(item['id'], val),
                    onAddStock: () =>
                        _showAddStockDialog(item['id'], item['name']),
                    onEdit: () => _showEditDialog(item),
                    onDelete: () => _confirmDelete(item['id'], item['name']),
                  );
                },
              ),
            ),
    );
  }

  // ─── Add Stock Dialog ─────────────────────────────────────────────────────
  void _showAddStockDialog(String itemId, String name) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Stock — $name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Quantity to add',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final qty = int.tryParse(ctrl.text);
              if (qty == null || qty <= 0) return;
              Navigator.pop(ctx);
              final admin = context.read<AdminProvider>();
              final ok = await admin.addStock(itemId, qty);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(ok ? '✅ Stock updated!' : admin.error ?? 'Failed'),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ─── Edit Item Dialog ─────────────────────────────────────────────────────
  void _showEditDialog(Map<String, dynamic> item) {
    final nameCtrl = TextEditingController(text: item['name']);
    final priceCtrl =
        TextEditingController(text: item['price']?.toString() ?? '');
    final stockCtrl =
        TextEditingController(text: item['stock']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField('Name', nameCtrl),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _dialogField('Price (₹)', priceCtrl,
                  inputType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _dialogField('Stock', stockCtrl,
                  inputType: TextInputType.number)),
            ]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final admin = context.read<AdminProvider>();
              final ok = await admin.updateItem(
                itemId: item['id'],
                name: nameCtrl.text.trim().isNotEmpty
                    ? nameCtrl.text.trim()
                    : null,
                price: double.tryParse(priceCtrl.text.trim()),
                stock: int.tryParse(stockCtrl.text.trim()),
              );
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(ok ? '✅ Item updated!' : admin.error ?? 'Failed'),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl,
      {TextInputType inputType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  void _confirmDelete(String itemId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final admin = context.read<AdminProvider>();
              final ok = await admin.deleteItem(itemId);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(ok ? '🗑️ Item deleted' : 'Failed to delete'),
                  backgroundColor: ok ? Colors.black : Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Inventory Card ───────────────────────────────────────────────────────────

class _InventoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onAddStock;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InventoryCard({
    required this.item,
    required this.onToggle,
    required this.onAddStock,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = item['name'] ?? '';
    final stock = (item['stock'] as num?)?.toInt() ?? 0;
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final available = item['is_available'] == true;
    final category = item['category'] ?? '';
    final imageUrl = item['image_url'] as String?;
    final isLowStock = stock > 0 && stock <= 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: stock <= 0
              ? Colors.red.shade200
              : isLowStock
                  ? Colors.orange.shade200
                  : Colors.grey.shade200,
          width: stock <= 0 || isLowStock ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Product Image / Icon
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 60,
                height: 60,
                color: Colors.grey.shade100,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.grey))
                    : const Icon(Icons.inventory_2_outlined, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 14),

            // Item Info
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  if (category.isNotEmpty)
                    Text(category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text('₹${price.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      // Stock badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: stock <= 0
                              ? Colors.red.shade50
                              : isLowStock
                                  ? Colors.orange.shade50
                                  : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          stock <= 0
                              ? 'OUT OF STOCK'
                              : isLowStock
                                  ? 'Low: $stock'
                                  : '$stock in stock',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: stock <= 0
                                ? Colors.red.shade700
                                : isLowStock
                                    ? Colors.orange.shade700
                                    : Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Available toggle
                Transform.scale(
                  scale: 0.8,
                  child: RevoSwitch(
                    value: available,
                    onChanged: onToggle,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _actionIcon(Icons.edit_outlined, Colors.blue, onEdit),
                    const SizedBox(width: 4),
                    _actionIcon(Icons.add_box_outlined, Colors.green, onAddStock),
                    const SizedBox(width: 4),
                    _actionIcon(Icons.delete_outline, Colors.red, onDelete),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
