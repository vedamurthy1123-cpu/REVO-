import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../config/supabase_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  String _statusMessage = 'Connecting to server...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() {
      _hasError = false;
      _statusMessage = 'Connecting to server...';
    });

    try {
      debugPrint('🔌 [Health Check] Pinging Supabase at: ${SupabaseConfig.url}');
      // Ping database to check connection
      await Supabase.instance.client
          .from('admin_settings')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 10));
      
      debugPrint('✅ [Health Check] Connection successful');
      _navigate();
    } catch (e) {
      debugPrint('❌ [Health Check] Connection failed: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusMessage = 'Server unreachable. Please check your connection.';
        });
      }
    }
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final auth = context.read<AuthProvider>();
    
    try {
      if (auth.isLoggedIn) {
        await auth.refreshProfile();
        if (!mounted) return;
        if (auth.isAdmin) {
          navigator.pushReplacementNamed('/admin');
        } else {
          navigator.pushReplacementNamed('/home');
        }
      } else {
        navigator.pushReplacementNamed('/login');
      }
    } catch (e) {
       if (mounted) {
        setState(() {
          _hasError = true;
          _statusMessage = 'Failed to load user profile.';
        });
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text(
                    'rv',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'REVO',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'College Store',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 48),
              if (_hasError) ...[
                const Icon(Icons.cloud_off, color: Colors.redAccent, size: 32),
                const SizedBox(height: 12),
                Text(
                  _statusMessage,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _checkConnection,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Connection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
              ] else ...[
                const CircularProgressIndicator(color: Colors.black),
                const SizedBox(height: 16),
                Text(
                  _statusMessage,
                  style: const TextStyle(color: Colors.black, fontSize: 12),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
