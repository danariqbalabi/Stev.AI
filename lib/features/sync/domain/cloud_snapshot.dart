class CloudSnapshot {
  const CloudSnapshot({required this.payload, required this.updatedAt});

  final Map<String, Object?> payload;
  final DateTime updatedAt;
}

abstract interface class CloudSyncGateway {
  bool get isAvailable;

  Future<CloudSnapshot?> fetch(String userId);

  Future<CloudSnapshot> save(String userId, Map<String, Object?> payload);

  Future<void> delete(String userId);
}

class CloudSyncException implements Exception {
  const CloudSyncException(this.message);

  final String message;
}
