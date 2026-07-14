import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/revo_app_bar.dart';
import 'payment_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    // Load fresh wallet balance every time this screen opens
    Future.microtask(() {
      if (mounted) context.read<WalletProvider>().loadBalance();
    });
  }

  Future<void> _placeAndPay() async {
    if (_processing) return;

    final cart    = context.read<CartProvider>();
    final wallet  = context.read<WalletProvider>();
    final total   = cart.total;
    final balance = wallet.balance;

    // ── Client-side balance check (UX guard before hitting DB) ─────────────
    if (balance < total) {
      _showError(
        'Insufficient Balance',
        'Your wallet has ₹${balance.toStringAsFixed(2)} but this order costs ₹${total.toStringAsFixed(2)}. '
        'Please top up your wallet and try again.',
      );
      return;
    }

    setState(() => _processing = true);

    // ── Build items payload ─────────────────────────────────────────────────
    final items = cart.toOrderPayload();

    // ── Call atomic RPC: place_and_pay_with_wallet ─────────────────────────
    final res = await wallet.placeAndPay(items);
    if (!mounted) return;

    if (res['success'] == true) {
      // Clear the local cart state (DB cart is cleared by the RPC)
      cart.clearLocalCart();

      // Navigate to Payment Success screen — NO back stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            orderData: Map<String, dynamic>.from(res['data'] as Map),
          ),
        ),
        (route) => false,
      );
    } else {
      setState(() => _processing = false);
      _showError('Payment Failed', res['message'] ?? 'Something went wrong. Please try again.');
    }
  }

  void _showError(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 22),
            const SizedBox(width: 10),
            Text(title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(message,
            style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Navigate to wallet screen to top up
              if (title == 'Insufficient Balance') {
                Navigator.pushNamed(context, '/wallet');
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              title == 'Insufficient Balance' ? 'ADD FUNDS' : 'OK',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          if (title == 'Insufficient Balance')
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL',
                  style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart   = context.watch<CartProvider>();
    final wallet = context.watch<WalletProvider>();
    final total  = cart.total;
    final bal    = wallet.balance;
    final hasFunds = bal >= total;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const RevoAppBar(showCart: false, showBack: true, showMenu: false),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Header ──────────────────────────────────────────
                  const Text('Checkout',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1)),
                  const SizedBox(height: 4),
                  const Text('Review & pay with your Revo Wallet',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 28),

                  // ── Wallet Balance Card ───────────────────────────────
                  _WalletBalanceCard(
                    balance: bal,
                    total: total,
                    hasFunds: hasFunds,
                    loading: wallet.loading,
                  ),

                  const SizedBox(height: 28),

                  // ── Section label ────────────────────────────────────
                  Text('ORDER SUMMARY',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: Colors.grey.shade500)),
                  const SizedBox(height: 14),

                  // ── Items list ───────────────────────────────────────
                  ...cart.items.map((item) => _ItemRow(item: item)),

                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // ── Price breakdown ──────────────────────────────────
                  _PriceRow(label: 'Subtotal',  value: '₹${total.toStringAsFixed(2)}'),
                  const SizedBox(height: 10),
                  const _PriceRow(label: 'Shipping',  value: '₹0.00', isMuted: true),
                  const SizedBox(height: 10),
                  const _PriceRow(label: 'Discount',  value: '₹0.00', isMuted: true),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5)),
                      Text('₹${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Pickup window info ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Estimated Pickup Window',
                                  style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700)),
                              Text('${cart.pickupWindow} minutes after ready',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Insufficient balance warning ────────────────────
                  if (!hasFunds && !wallet.loading) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Insufficient balance. Add ₹${(total - bal).toStringAsFixed(2)} more to proceed.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Pay Now button ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!hasFunds && !wallet.loading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/wallet'),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('ADD FUNDS TO WALLET'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: const BorderSide(color: Colors.black, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_processing || !hasFunds || cart.isEmpty)
                        ? null
                        : _placeAndPay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade200,
                      disabledForegroundColor: Colors.grey.shade400,
                      minimumSize: const Size(double.infinity, 58),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _processing
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.account_balance_wallet_rounded,
                                  size: 20),
                              const SizedBox(width: 10),
                              Text(
                                hasFunds
                                    ? 'PAY  ₹${total.toStringAsFixed(2)}'
                                    : 'INSUFFICIENT BALANCE',
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Wallet Balance Card ───────────────────────────────────────────────────

class _WalletBalanceCard extends StatelessWidget {
  final double balance;
  final double total;
  final bool hasFunds;
  final bool loading;

  const _WalletBalanceCard({
    required this.balance,
    required this.total,
    required this.hasFunds,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('REVO WALLET',
                    style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
                const SizedBox(height: 4),
                loading
                    ? Container(
                        height: 28,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      )
                    : Text(
                        '₹${balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5),
                      ),
              ],
            ),
          ),
          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: hasFunds ? Colors.white : Colors.red.shade400,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              hasFunds ? '✓ Sufficient' : '✗ Low',
              style: TextStyle(
                color: hasFunds ? Colors.black : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Item Row ──────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final CartItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade100),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Image / placeholder
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) =>
                            const Icon(Icons.inventory_2_outlined,
                                color: Colors.grey)),
                  )
                : const Icon(Icons.inventory_2_outlined, color: Colors.grey),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text('₹${item.price.toStringAsFixed(2)}  ×  ${item.quantity}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text('₹${(item.price * item.quantity).toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ─── Price Row ─────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMuted;
  const _PriceRow(
      {required this.label, required this.value, this.isMuted = false});

  @override
  Widget build(BuildContext context) {
    final color = isMuted ? Colors.grey.shade400 : Colors.grey.shade700;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: color)),
        Text(value,  style: TextStyle(fontSize: 14, color: color)),
      ],
    );
  }
}
