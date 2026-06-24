import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> signIn(String email) async {
    _error = null;
    if (!email.contains('@') || !email.contains('.')) {
      _error = 'Saisissez une adresse email professionnelle valide.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    _isLoading = false;
    _isAuthenticated = true;
    notifyListeners();
    return true;
  }

  void signOut() {
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
  }
}
