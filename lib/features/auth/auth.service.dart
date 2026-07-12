import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/network/api_client.dart';

enum AuthStatus { initializing, unauthenticated, authenticated }

abstract interface class SessionStore {
  Future<String?> readSecretKey();
  Future<void> writeSecretKey(String value);
  Future<void> clearSecretKey();
  Future<String?> readLastValidationDay();
  Future<void> writeLastValidationDay(String value);
  Future<void> clearLastValidationDay();
}

class SecureSessionStore implements SessionStore {
  static const _key = 'korascope_secret_key';
  static const _lastValidationDayKey = 'korascope_last_validation_day';
  final FlutterSecureStorage storage;

  const SecureSessionStore({
    this.storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  });

  @override
  Future<String?> readSecretKey() => storage.read(key: _key);

  @override
  Future<void> writeSecretKey(String value) =>
      storage.write(key: _key, value: value);

  @override
  Future<void> clearSecretKey() => storage.delete(key: _key);

  @override
  Future<String?> readLastValidationDay() =>
      storage.read(key: _lastValidationDayKey);

  @override
  Future<void> writeLastValidationDay(String value) =>
      storage.write(key: _lastValidationDayKey, value: value);

  @override
  Future<void> clearLastValidationDay() =>
      storage.delete(key: _lastValidationDayKey);
}

class AuthService extends ChangeNotifier {
  final ApiClient apiClient;
  final SessionStore sessionStore;

  AuthStatus _status = AuthStatus.initializing;
  bool _isLoading = false;
  bool _isNewUser = false;
  String? _error;

  AuthService({ApiClient? apiClient, SessionStore? sessionStore})
    : apiClient = apiClient ?? ApiClient(),
      sessionStore = sessionStore ?? const SecureSessionStore() {
    this.apiClient.onUnauthorized = _handleUnauthorized;
  }

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isInitializing => _status == AuthStatus.initializing;
  bool get isLoading => _isLoading;
  bool get isNewUser => _isNewUser;
  String? get error => _error;

  Future<void> initialize() async {
    try {
      final secretKey = await sessionStore.readSecretKey();
      if (secretKey == null || secretKey.isEmpty) {
        _status = AuthStatus.unauthenticated;
      } else {
        apiClient.secretKey = secretKey;
        await _validateStoredSession();
        await sessionStore.writeLastValidationDay(_todayKey());
        _status = AuthStatus.authenticated;
      }
    } catch (_) {
      await sessionStore.clearSecretKey();
      apiClient.secretKey = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> validateCurrentSession() async {
    if (_status != AuthStatus.authenticated || apiClient.secretKey == null) {
      return false;
    }
    try {
      await _validateStoredSession();
      await sessionStore.writeLastValidationDay(_todayKey());
      return true;
    } catch (_) {
      await _clearSession();
      notifyListeners();
      return false;
    }
  }

  Future<bool> validateCurrentSessionIfDue() async {
    if (_status != AuthStatus.authenticated || apiClient.secretKey == null) {
      return false;
    }
    final today = _todayKey();
    final lastValidationDay = await sessionStore.readLastValidationDay();
    if (lastValidationDay == today) return true;
    return validateCurrentSession();
  }

  Future<bool> requestOtp(String email) async {
    if (!email.contains('@') || !email.contains('.')) {
      _error = 'Saisissez une adresse email professionnelle valide.';
      notifyListeners();
      return false;
    }
    return _run(() async {
      await apiClient.post(
        '/auth/request-otp',
        protected: false,
        body: {'email': email},
      );
    });
  }

  Future<bool> verifyOtp({required String email, required String otp}) async {
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _error = 'Le code doit contenir exactement 6 chiffres.';
      notifyListeners();
      return false;
    }
    return _run(() async {
      final data =
          await apiClient.post(
                '/auth/verify-otp',
                protected: false,
                body: {'email': email, 'otp': otp},
              )
              as Map<String, dynamic>;
      final secretKey = (data['token'] ?? data['secretKey']) as String;
      _isNewUser = data['isNew'] == true;
      apiClient.secretKey = secretKey;
      await sessionStore.writeSecretKey(secretKey);
      await sessionStore.writeLastValidationDay(_todayKey());
      _status = AuthStatus.authenticated;
    });
  }

  Future<bool> _run(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      return false;
    } catch (_) {
      _error = 'Impossible de joindre le serveur. Vérifiez votre connexion.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _clearSession();
    notifyListeners();
  }

  Future<void> _validateStoredSession() async {
    final data = await apiClient.get('/auth/validate');
    if (data is Map<String, dynamic> && data['status'] != 'VALID') {
      throw const ApiException(401, 'Session expirée.');
    }
  }

  Future<void> _clearSession() async {
    await sessionStore.clearSecretKey();
    await sessionStore.clearLastValidationDay();
    apiClient.secretKey = null;
    _isNewUser = false;
    _status = AuthStatus.unauthenticated;
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  void markProfileCompleted() {
    _isNewUser = false;
    notifyListeners();
  }

  void _handleUnauthorized() {
    apiClient.secretKey = null;
    _status = AuthStatus.unauthenticated;
    sessionStore.clearSecretKey();
    notifyListeners();
  }
}
