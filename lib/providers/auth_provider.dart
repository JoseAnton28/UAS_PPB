import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String _errorMessage = '';

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _initAuth();
  }

  void _initAuth() {
    // Get current session
    final session = Supabase.instance.client.auth.currentSession;
    _currentUser = session?.user;

    if (_currentUser != null) {
      print('✅ Auth: User session restored - ${_currentUser!.email}');
    } else {
      print('⚠️ Auth: No active session');
    }

    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      _currentUser = data.session?.user;

      print('🔐 Auth state changed: $event');
      if (_currentUser != null) {
        print('✅ User: ${_currentUser!.email}');
      }

      notifyListeners();
    });
  }

  Future<bool> signUp(String email, String password, String displayName) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

      if (response.session != null) {  // Changed to check session, not user (for confirmation flow)
        _currentUser = response.user;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Sign up failed. Check if email confirmation is required.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {  // Check session
        _currentUser = response.user;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Sign in failed. Check credentials or confirm email.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  String get displayName {
    if (_currentUser == null) return 'Guest';
    return _currentUser!.userMetadata?['display_name'] ??
        _currentUser!.email?.split('@')[0] ??
        'User';
  }
}