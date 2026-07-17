import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
        emailRedirectTo: 'https://vedamurthy1123-cpu.github.io/REVO-/callback.html',
      );
      if (res.user == null) {
        return {'success': false, 'message': 'Signup failed. Try again.'};
      }
      // ignore: avoid_print
      print('🔐 [Auth] User signed up: ${res.user!.email}');

      // If email confirmation is required, the session will be null
      // and emailConfirmedAt will be null.
      final isConfirmed = res.user!.emailConfirmedAt != null;
      if (!isConfirmed) {
        // Sign out the temporary session created by signUp so the user
        // cannot access protected areas before confirming their email.
        await _client.auth.signOut();
        return {
          'success': true,
          'requiresConfirmation': true,
          'message':
              'A confirmation email has been sent to $email. Please verify your email before logging in.',
        };
      }

      return {'success': true, 'requiresConfirmation': false, 'message': 'Account created!'};
    } on AuthException catch (e) {
      // ignore: avoid_print
      print('🔐 [Auth Error] Signup: ${e.message}');
      return {'success': false, 'message': e.message};
    } catch (e) {
      // ignore: avoid_print
      print('🔥 [System Error] Signup: $e');
      return {'success': false, 'message': 'Network error.'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user == null) {
        return {'success': false, 'message': 'Login failed.'};
      }

      // Block login if the user has not confirmed their email yet.
      if (res.user!.emailConfirmedAt == null) {
        // Sign out immediately so no session is retained.
        await _client.auth.signOut();
        // ignore: avoid_print
        print('🔐 [Auth] Login blocked – email not confirmed: ${res.user!.email}');
        return {
          'success': false,
          'message':
              'Please verify your email address before logging in. Check your inbox for the confirmation link.',
        };
      }

      // ignore: avoid_print
      print('🔐 [Auth] User logged in: ${res.user!.email}');
      return {'success': true, 'message': 'Welcome back!'};
    } on AuthException catch (e) {
      // ignore: avoid_print
      print('🔐 [Auth Error] Login: ${e.message}');
      return {'success': false, 'message': e.message};
    } catch (e) {
      // ignore: avoid_print
      print('🔥 [System Error] Login: $e');
      return {'success': false, 'message': 'Network error.'};
    }
  }

  static Future<void> logout() async {
    await _client.auth.signOut();
  }

  static User? get currentUser => _client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  static Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  static Future<String> getUserRole() async {
    final user = currentUser;
    if (user == null) return 'none';

    // Primary: read role directly from the profiles table
    try {
      final data = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      final role = data?['role'] as String?;
      if (role != null && role.isNotEmpty) return role;
    } catch (_) {
      // Fall through to metadata fallback
    }

    // Fallback: check user_metadata (set during signup or admin update)
    try {
      final role = user.userMetadata?['role'] as String?;
      if (role != null && role.isNotEmpty) return role;
    } catch (_) {}

    return 'customer';
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      
      // ignore: avoid_print
      print('👤 [Auth] Profile fetched: ${data != null ? 'Success' : 'Not found'}');
      return data;
    } catch (e) {
      // ignore: avoid_print
      print('🔥 [Auth Error] getProfile: $e');
      return null;
    }
  }
}
