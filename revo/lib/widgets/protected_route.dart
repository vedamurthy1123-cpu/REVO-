import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProtectedRoute extends StatelessWidget {
  final Widget child;
  final String requiredRole; // 'admin', 'customer', or 'guest'

  const ProtectedRoute({
    super.key,
    required this.child,
    required this.requiredRole,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // If AuthProvider is not initialized yet (e.g. recovering session on start/refresh),
    // show a centered loading indicator.
    if (!auth.initialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );
    }

    if (requiredRole == 'guest') {
      // If already logged in, redirect away from guest-only pages (login/signup)
      if (auth.isLoggedIn) {
        if (auth.role == 'admin') {
          return const RedirectToHome(isAdminRedirect: true);
        } else {
          return const RedirectToHome(isAdminRedirect: false);
        }
      }
      return child;
    }

    // If not logged in and trying to access protected pages:
    if (!auth.isLoggedIn) {
      return const RedirectToLogin();
    }

    // If logged in as student/customer, trying to access admin route
    if (requiredRole == 'admin' && auth.role != 'admin') {
      return const RedirectToHome(isAdminRedirect: false);
    }

    // If logged in as admin, trying to access student route
    if (requiredRole == 'customer' && auth.role == 'admin') {
      return const RedirectToHome(isAdminRedirect: true);
    }

    return child;
  }
}

class RedirectToLogin extends StatefulWidget {
  const RedirectToLogin({super.key});

  @override
  State<RedirectToLogin> createState() => _RedirectToLoginState();
}

class _RedirectToLoginState extends State<RedirectToLogin> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Colors.black),
      ),
    );
  }
}

class RedirectToHome extends StatefulWidget {
  final bool isAdminRedirect;
  const RedirectToHome({super.key, required this.isAdminRedirect});

  @override
  State<RedirectToHome> createState() => _RedirectToHomeState();
}

class _RedirectToHomeState extends State<RedirectToHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isAdminRedirect) {
        Navigator.of(context).pushReplacementNamed('/admin');
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Colors.black),
      ),
    );
  }
}
