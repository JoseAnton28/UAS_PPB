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
    _currentUser = Supabase.instance.client.auth.currentUser;

    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _currentUser = data.session?.user;
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

      if (response.user != null) {
        _currentUser = response.user;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Sign up failed';
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

      if (response.user != null) {
        _currentUser = response.user;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Sign in failed';
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