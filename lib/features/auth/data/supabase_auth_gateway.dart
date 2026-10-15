import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_user.dart';

class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(this._client);

  final SupabaseClient? _client;

  @override
  bool get isAvailable => _client != null;

  @override
  StevAuthUser? get currentUser => _mapUser(_client?.auth.currentUser);

  @override
  Stream<StevAuthUser?> get userChanges {
    final client = _client;
    if (client == null) return const Stream.empty();
    return client.auth.onAuthStateChange.map(
      (event) => _mapUser(event.session?.user),
    );
  }

  @override
  Future<StevAuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = _mapUser(response.user);
      if (user == null) {
        throw const AuthGatewayException('Sesi akun tidak dapat dibuat.');
      }
      return user;
    } on AuthException catch (error) {
      throw AuthGatewayException(error.message);
    }
  }

  @override
  Future<StevAuthUser?> signUp({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );
      return response.session == null ? null : _mapUser(response.user);
    } on AuthException catch (error) {
      throw AuthGatewayException(error.message);
    }
  }

  @override
  Future<void> signOut({bool localOnly = false}) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.auth.signOut(
        scope: localOnly ? SignOutScope.local : SignOutScope.global,
      );
    } on AuthException catch (error) {
      throw AuthGatewayException(error.message);
    }
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw const AuthGatewayException(
        'Layanan akun belum dikonfigurasi. Kamu tetap bisa memakai mode tamu.',
      );
    }
    return client;
  }

  static StevAuthUser? _mapUser(User? user) {
    final email = user?.email;
    if (user == null || email == null) return null;
    return StevAuthUser(id: user.id, email: email);
  }
}
