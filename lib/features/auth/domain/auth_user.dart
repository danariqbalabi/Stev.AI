class StevAuthUser {
  const StevAuthUser({required this.id, required this.email});

  final String id;
  final String email;
}

abstract interface class AuthGateway {
  bool get isAvailable;

  StevAuthUser? get currentUser;

  Stream<StevAuthUser?> get userChanges;

  Future<StevAuthUser> signIn({
    required String email,
    required String password,
  });

  Future<StevAuthUser?> signUp({
    required String email,
    required String password,
  });

  Future<void> signOut({bool localOnly = false});
}

class AuthGatewayException implements Exception {
  const AuthGatewayException(this.message);

  final String message;

  @override
  String toString() => message;
}
