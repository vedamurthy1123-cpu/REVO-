import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'config/app_theme.dart';

import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/items_provider.dart';
import 'providers/order_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/wallet_provider.dart';

import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/student/student_shell.dart';
import 'screens/student/cart_screen.dart';
import 'screens/student/checkout_screen.dart';
import 'screens/student/wallet_screen.dart';
import 'screens/student/order_history_screen.dart';
import 'screens/student/notifications_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/admin/add_item_screen.dart';
import 'constants/keys.dart';
import 'widgets/protected_route.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const RevoApp());
}

class RevoApp extends StatelessWidget {
  const RevoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ItemsProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: MaterialApp(
        title: 'REVO',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        theme: AppTheme.theme,
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const ProtectedRoute(requiredRole: 'guest', child: LoginScreen()),
          '/signup': (_) => const ProtectedRoute(requiredRole: 'guest', child: SignupScreen()),
          '/home': (_) => const ProtectedRoute(requiredRole: 'customer', child: StudentShell()),
          '/cart': (_) => const ProtectedRoute(requiredRole: 'customer', child: CartScreen()),
          '/checkout': (_) => const ProtectedRoute(requiredRole: 'customer', child: CheckoutScreen()),
          '/wallet': (_) => const ProtectedRoute(requiredRole: 'customer', child: WalletScreen()),
          '/admin-login': (_) => const ProtectedRoute(requiredRole: 'guest', child: AdminLoginScreen()),
          '/admin': (_) => const ProtectedRoute(requiredRole: 'admin', child: AdminShell()),
          '/add-item': (_) => const ProtectedRoute(requiredRole: 'admin', child: AddItemScreen()),
          '/order-history': (_) => const ProtectedRoute(requiredRole: 'customer', child: OrderHistoryScreen()),
          '/notifications': (_) => const ProtectedRoute(requiredRole: 'customer', child: NotificationsScreen()),
        },
      ),
    );
  }
}
