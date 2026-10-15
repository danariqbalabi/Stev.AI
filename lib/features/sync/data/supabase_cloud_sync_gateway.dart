import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/cloud_snapshot.dart';

class SupabaseCloudSyncGateway implements CloudSyncGateway {
  SupabaseCloudSyncGateway(this._client);

  final SupabaseClient? _client;

  @override
  bool get isAvailable => _client != null;

  @override
  Future<CloudSnapshot?> fetch(String userId) async {
    final client = _requireClient();
    try {
      final row = await client
          .from('user_data_snapshots')
          .select('payload, updated_at')
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return null;
      return _fromRow(row);
    } on PostgrestException catch (error) {
      throw CloudSyncException(error.message);
    }
  }

  @override
  Future<CloudSnapshot> save(
    String userId,
    Map<String, Object?> payload,
  ) async {
    final client = _requireClient();
    final now = DateTime.now().toUtc();
    try {
      final row = await client
          .from('user_data_snapshots')
          .upsert({
            'user_id': userId,
            'payload': payload,
            'client_updated_at': now.toIso8601String(),
          }, onConflict: 'user_id')
          .select('payload, updated_at')
          .single();
      return _fromRow(row);
    } on PostgrestException catch (error) {
      throw CloudSyncException(error.message);
    }
  }

  @override
  Future<void> delete(String userId) async {
    final client = _requireClient();
    try {
      await client.from('user_data_snapshots').delete().eq('user_id', userId);
    } on PostgrestException catch (error) {
      throw CloudSyncException(error.message);
    }
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw const CloudSyncException('Layanan sinkronisasi belum tersedia.');
    }
    return client;
  }

  static CloudSnapshot _fromRow(Map<String, dynamic> row) {
    final payload = row['payload'];
    final updatedAt = DateTime.tryParse(row['updated_at']?.toString() ?? '');
    if (payload is! Map || updatedAt == null) {
      throw const CloudSyncException('Format data cloud tidak valid.');
    }
    return CloudSnapshot(
      payload: Map<String, Object?>.from(payload),
      updatedAt: updatedAt.toUtc(),
    );
  }
}
