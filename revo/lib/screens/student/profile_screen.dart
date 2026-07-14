import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    final currentUser = AuthService.currentUser;

    // Name fallback chain:
    // 1. Profile table full_name
    // 2. Auth metadata full_name (from signup)
    // 3. Email username part (e.g. "vedamurthy1123" from vedamurthy1123@gmail.com)
    final rawName = profile?['full_name'] as String? ??
        currentUser?.userMetadata?['full_name'] as String? ??
        '';
    final email = currentUser?.email ?? '';
    final name = rawName.trim().isNotEmpty
        ? rawName.trim()
        : (email.isNotEmpty ? email.split('@').first : 'User');

    final role = profile?['role'] ?? 'customer';

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Avatar
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(name,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(email,
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(role.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
            ),
            
            const SizedBox(height: 16),
            Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: orderProvider.isConnected ? Colors.blue : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      orderProvider.isConnected ? 'Live Sync Active' : 'Offline / Reconnecting...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: orderProvider.isConnected ? Colors.blue : Colors.red,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 40),

            // Menu items
            _menuItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Wallet',
              subtitle: 'View balance & transactions',
              onTap: () => Navigator.pushNamed(context, '/wallet'),
            ),
            _menuItem(
              icon: Icons.receipt_long_outlined,
              title: 'Order History',
              subtitle: 'View past orders',
              onTap: () => Navigator.pushNamed(context, '/order-history'),
            ),
            _menuItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Manage preferences',
              onTap: () => Navigator.pushNamed(context, '/notifications'),
            ),
            _menuItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help or report issues',
              onTap: () {},
            ),

            const SizedBox(height: 32),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await context.read<AuthProvider>().logout();
                  if (!mounted) return;
                  navigator.pushNamedAndRemoveUntil('/login', (_) => false);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(0, 52),
                ),
                child: const Text('LOGOUT'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22),
        ),
        title: Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style:
                TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}
