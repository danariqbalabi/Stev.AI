import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../auth/application/auth_controller.dart';
import '../../drinks/application/drink_log_controller.dart';
import '../../family/application/family_controller.dart';
import '../../profile/data/local_data_preferences.dart';
import '../domain/cloud_snapshot.dart';

enum CloudSyncStatus { unavailable, signedOut, idle, syncing, synced, error }

class CloudSyncController extends ChangeNotifier {
  CloudSyncController({
    required AuthController auth,
    required CloudSyncGateway gateway,
    required this.drinkLog,
    required this.family,
  }) : _auth = auth,
       _gateway = gateway,
       _status = !gateway.isAvailable
           ? CloudSyncStatus.unavailable
           : auth.isSignedIn
           ? CloudSyncStatus.idle
           : CloudSyncStatus.signedOut {
    _auth.addListener(_handleAuthChange);
    if (_auth.isSignedIn && _gateway.isAvailable) {
      scheduleMicrotask(syncNow);
    }
  }

  final AuthController _auth;
  final CloudSyncGateway _gateway;
  final DrinkLogController drinkLog;
  final FamilyController family;
  CloudSyncStatus _status;
  DateTime? _lastSyncedAt;
  String? _errorMessage;
  Future<bool>? _activeSync;
  String? _observedUserId;

  CloudSyncStatus get status => _status;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get errorMessage => _errorMessage;
  bool get canSync => _gateway.isAvailable && _auth.isSignedIn;

  void _handleAuthChange() {
    final userId = _auth.user?.id;
    if (!_gateway.isAvailable) {
      _status = CloudSyncStatus.unavailable;
    } else if (userId == null) {
      _status = CloudSyncStatus.signedOut;
      _lastSyncedAt = null;
      _observedUserId = null;
    } else {
      _status = CloudSyncStatus.idle;
      if (_observedUserId != userId) {
        _observedUserId = userId;
        scheduleMicrotask(syncNow);
      }
    }
    notifyListeners();
  }

  Future<bool> syncNow() {
    final active = _activeSync;
    if (active != null) return active;
    final operation = _performSync();
    _activeSync = operation;
    return operation.whenComplete(() {
      if (identical(_activeSync, operation)) _activeSync = null;
    });
  }

  Future<bool> _performSync() async {
    final user = _auth.user;
    if (!_gateway.isAvailable) {
      _status = CloudSyncStatus.unavailable;
      notifyListeners();
      return false;
    }
    if (user == null) {
      _status = CloudSyncStatus.signedOut;
      notifyListeners();
      return false;
    }

    _status = CloudSyncStatus.syncing;
    _errorMessage = null;
    notifyListeners();
    try {
      await drinkLog.flush();
      final local = await LocalDataPreferences.exportData();
      final localDirty = await LocalDataPreferences.isDirty();
      final lastSynced = await LocalDataPreferences.lastSyncedAt();
      final ownerUserId = await LocalDataPreferences.ownerUserId();
      final remote = await _gateway.fetch(user.id);

      if (ownerUserId != null && ownerUserId != user.id) {
        final accountSnapshot =
            remote ?? await _gateway.save(user.id, const <String, Object?>{});
        await _restore(accountSnapshot, userId: user.id);
      } else if (remote == null) {
        final saved = await _gateway.save(user.id, local);
        await LocalDataPreferences.markSynced(saved.updatedAt, userId: user.id);
        _lastSyncedAt = saved.updatedAt;
      } else if (lastSynced == null) {
        final merged = <String, Object?>{...remote.payload, ...local};
        final saved = await _gateway.save(user.id, merged);
        await _restore(saved, userId: user.id);
      } else {
        final cloudChanged = remote.updatedAt.isAfter(lastSynced);
        final localChanged = localDirty;
        if (cloudChanged && localChanged) {
          final merged = <String, Object?>{...remote.payload, ...local};
          final saved = await _gateway.save(user.id, merged);
          await _restore(saved, userId: user.id);
        } else if (localChanged) {
          final saved = await _gateway.save(user.id, local);
          await LocalDataPreferences.markSynced(
            saved.updatedAt,
            userId: user.id,
          );
          _lastSyncedAt = saved.updatedAt;
        } else if (cloudChanged) {
          await _restore(remote, userId: user.id);
        } else {
          _lastSyncedAt = lastSynced;
        }
      }

      _status = CloudSyncStatus.synced;
      notifyListeners();
      return true;
    } on CloudSyncException catch (error) {
      _status = CloudSyncStatus.error;
      _errorMessage = error.message;
    } catch (_) {
      _status = CloudSyncStatus.error;
      _errorMessage = 'Sinkronisasi gagal. Periksa koneksi lalu coba lagi.';
    }
    notifyListeners();
    return false;
  }

  Future<void> _restore(
    CloudSnapshot snapshot, {
    required String userId,
  }) async {
    await LocalDataPreferences.importData(
      snapshot.payload,
      syncedAt: snapshot.updatedAt,
      userId: userId,
    );
    await drinkLog.reloadLocalState();
    await family.reloadLocalState();
    _lastSyncedAt = snapshot.updatedAt;
  }

  Future<bool> deleteCloudData() async {
    final user = _auth.user;
    if (!_gateway.isAvailable || user == null) return true;
    try {
      await _gateway.delete(user.id);
      return true;
    } catch (_) {
      _status = CloudSyncStatus.error;
      _errorMessage = 'Data cloud belum berhasil dihapus. Coba lagi.';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_handleAuthChange);
    super.dispose();
  }
}

class CloudSyncScope extends InheritedNotifier<CloudSyncController> {
  const CloudSyncScope({
    super.key,
    required CloudSyncController controller,
    required super.child,
  }) : super(notifier: controller);

  static CloudSyncController watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CloudSyncScope>();
    assert(scope != null, 'CloudSyncScope is missing above this context.');
    return scope!.notifier!;
  }

  static CloudSyncController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<CloudSyncScope>();
    assert(scope != null, 'CloudSyncScope is missing above this context.');
    return scope!.notifier!;
  }
}
