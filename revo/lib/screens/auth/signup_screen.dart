import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final auth = context.read<AuthProvider>();
    final ok = await auth.signUp(
      _emailCtrl.text.trim(),
      _passCtrl.text,
      _nameCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      if (auth.requiresConfirmation) {
        // Show "check your email" screen – do NOT navigate to /home
        _showVerifyEmailDialog(auth);
      } else {
        // Email confirmation is disabled in Supabase; go straight home
        navigator.pushReplacementNamed('/home');
      }
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Signup failed')),
      );
    }
  }

  void _showVerifyEmailDialog(AuthProvider auth) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.mark_email_unread_outlined,
            size: 48, color: Colors.black87),
        title: const Text(
          'Verify your email',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A confirmation link has been sent to\n${_emailCtrl.text.trim()}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Click the link in your email to activate your account, then come back and log in.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('GO TO LOGIN'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Center(
                  child: Text('REVO',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4)),
                ),
                const SizedBox(height: 60),
                const Text('Create Account.',
                    style:
                        TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Join the academic community.',
                    style: TextStyle(
                        fontSize: 15, color: Colors.grey.shade600)),
                const SizedBox(height: 40),
                const Text('FULL NAME',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Colors.grey)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Your full name',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 24),
                const Text('EMAIL',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Colors.grey)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'student@university.edu',
                    prefixIcon: Icon(Icons.mail_outline, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter email';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text('PASSWORD',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Colors.grey)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter password';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: auth.loading ? null : _signup,
                  child: auth.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('CREATE ACCOUNT'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('ALREADY HAVE ACCOUNT? LOGIN'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
