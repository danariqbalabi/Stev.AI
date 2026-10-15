import 'dart:async';

import 'package:flutter/widgets.dart';

import '../domain/auth_user.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._gateway) : _user = _gateway.currentUser {
    _subscription = _gateway.userChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  final AuthGateway _gateway;
  late final StreamSubscription<StevAuthUser?> _subscription;
  StevAuthUser? _user;
  bool _loading = false;
  String? _errorMessage;
  bool _confirmationPending = false;

  bool get isAvailable => _gateway.isAvailable;
  bool get isLoading => _loading;
  bool get isSignedIn => _user != null;
  StevAuthUser? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get confirmationPending => _confirmationPending;

  Future<bool> signIn({required String email, required String password}) =>
      _run(() async {
        _user = await _gateway.signIn(email: email.trim(), password: password);
        return true;
      });

  Future<bool> signUp({required String email, required String password}) =>
      _run(() async {
        _user = await _gateway.signUp(email: email.trim(), password: password);
        _confirmationPending = _user == null;
        return true;
      });

  Future<bool> signOut({bool localOnly = false}) => _run(() async {
    await _gateway.signOut(localOnly: localOnly);
    _user = null;
    return true;
  });

  void clearFeedback() {
    _errorMessage = null;
    _confirmationPending = false;
    notifyListeners();
  }

  Future<bool> _run(Future<bool> Function() operation) async {
    if (_loading) return false;
    _loading = true;
    _errorMessage = null;
    _confirmationPending = false;
    notifyListeners();
    try {
      return await operation();
    } on AuthGatewayException catch (error) {
      _errorMessage = _friendlyMessage(error.message);
      return false;
    } catch (_) {
      _errorMessage = 'Terjadi masalah. Periksa koneksi lalu coba lagi.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  static String _friendlyMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('invalid login credentials')) {
      return 'Email atau kata sandi salah.';
    }
    if (normalized.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Periksa kotak masukmu.';
    }
    if (normalized.contains('already registered') ||
        normalized.contains('already been registered')) {
      return 'Email ini sudah terdaftar. Silakan masuk.';
    }
    if (normalized.contains('password')) {
      return 'Kata sandi belum memenuhi syarat keamanan.';
    }
    return message;
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope is missing above this context.');
    return scope!.notifier!;
  }

  static AuthController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope is missing above this context.');
    return scope!.notifier!;
  }
}
