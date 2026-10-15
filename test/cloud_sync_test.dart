import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:steviai/features/auth/application/auth_controller.dart';
import 'package:steviai/features/auth/domain/auth_user.dart';
import 'package:steviai/features/drinks/application/drink_log_controller.dart';
import 'package:steviai/features/family/application/family_controller.dart';
import 'package:steviai/features/onboarding/data/onboarding_preferences.dart';
import 'package:steviai/features/profile/data/local_data_preferences.dart';
import 'package:steviai/features/sync/application/cloud_sync_controller.dart';
import 'package:steviai/features/sync/domain/cloud_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('first sync uploads local data for the signed-in user', () async {
    await OnboardingPreferences.complete(name: 'Danan', drinkTime: 'Sore');
    final authGateway = _SignedInAuthGateway();
    final auth = AuthController(authGateway);
    final drinkLog = await DrinkLogController.persistent(
      now: DateTime(2026, 10, 15),
    );
    final family = await FamilyController.persistent();
    final cloud = _FakeCloudSyncGateway();
    final sync = CloudSyncController(
      auth: auth,
      gateway: cloud,
      drinkLog: drinkLog,
      family: family,
    );
    addTearDown(sync.dispose);
    addTearDown(auth.dispose);
    addTearDown(authGateway.dispose);
    addTearDown(drinkLog.dispose);
    addTearDown(family.dispose);

    expect(await sync.syncNow(), isTrue);
    expect(cloud.savedUserId, 'user-1');
    expect(cloud.snapshot!.payload[OnboardingPreferences.nameKey], 'Danan');
    expect(sync.status, CloudSyncStatus.synced);
    expect(await LocalDataPreferences.lastSyncedAt(), isNotNull);
    expect(await LocalDataPreferences.ownerUserId(), 'user-1');
  });

  test('first sync merges cloud data into local preferences', () async {
    final remoteTime = DateTime.utc(2026, 10, 15, 8);
    final authGateway = _SignedInAuthGateway();
    final auth = AuthController(authGateway);
    final drinkLog = await DrinkLogController.persistent(
      now: DateTime(2026, 10, 15),
    );
    final family = await FamilyController.persistent();
    final cloud = _FakeCloudSyncGateway(
      snapshot: CloudSnapshot(
        payload: const {
          OnboardingPreferences.nameKey: 'Dari cloud',
          OnboardingPreferences.drinkTimeKey: 'Malam',
        },
        updatedAt: remoteTime,
      ),
    );
    final sync = CloudSyncController(
      auth: auth,
      gateway: cloud,
      drinkLog: drinkLog,
      family: family,
    );
    addTearDown(sync.dispose);
    addTearDown(auth.dispose);
    addTearDown(authGateway.dispose);
    addTearDown(drinkLog.dispose);
    addTearDown(family.dispose);

    expect(await sync.syncNow(), isTrue);
    final profile = await OnboardingPreferences.readProfile();
    expect(profile.name, 'Dari cloud');
    expect(profile.drinkTime, 'Malam');
  });

  test('local data export excludes sync metadata and unrelated keys', () async {
    SharedPreferences.setMockInitialValues({
      OnboardingPreferences.nameKey: 'Danan',
      LocalDataPreferences.revisionKey: '2026-10-15T08:00:00.000Z',
      'unrelated-key': 'keep',
      'stev-device-barcode-cache-v1': 'device-only',
      'stev-device-barcode-retry-at': 'device-only',
    });

    final exported = await LocalDataPreferences.exportData();
    expect(exported, {OnboardingPreferences.nameKey: 'Danan'});
  });

  test(
    'cloud restore cannot replace or import device cache and pacing',
    () async {
      SharedPreferences.setMockInitialValues({
        'stev-device-barcode-cache-v1': 'local',
      });
      await LocalDataPreferences.importData(
        {
          'stev-device-barcode-cache-v1': 'remote',
          'stev-device-barcode-retry-at': 'remote',
        },
        syncedAt: DateTime.utc(2026, 10, 16),
        userId: 'user',
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('stev-device-barcode-cache-v1'), 'local');
      expect(prefs.getString('stev-device-barcode-retry-at'), isNull);
      await LocalDataPreferences.resetAll();
      expect(prefs.getString('stev-device-barcode-cache-v1'), isNull);
    },
  );

  test(
    'a different account never inherits the previous account cache',
    () async {
      SharedPreferences.setMockInitialValues({
        OnboardingPreferences.nameKey: 'Akun lama',
        LocalDataPreferences.ownerUserKey: 'old-user',
        LocalDataPreferences.revisionKey: '2026-10-15T07:00:00.000Z',
        LocalDataPreferences.lastSyncedKey: '2026-10-15T07:00:00.000Z',
      });
      final authGateway = _SignedInAuthGateway(userId: 'new-user');
      final auth = AuthController(authGateway);
      final drinkLog = await DrinkLogController.persistent(
        now: DateTime(2026, 10, 15),
      );
      final family = await FamilyController.persistent();
      final cloud = _FakeCloudSyncGateway(
        snapshot: CloudSnapshot(
          payload: const {OnboardingPreferences.nameKey: 'Akun baru'},
          updatedAt: DateTime.utc(2026, 10, 15, 8),
        ),
      );
      final sync = CloudSyncController(
        auth: auth,
        gateway: cloud,
        drinkLog: drinkLog,
        family: family,
      );
      addTearDown(sync.dispose);
      addTearDown(auth.dispose);
      addTearDown(authGateway.dispose);
      addTearDown(drinkLog.dispose);
      addTearDown(family.dispose);

      expect(await sync.syncNow(), isTrue);
      expect((await OnboardingPreferences.readProfile()).name, 'Akun baru');
      expect(await LocalDataPreferences.ownerUserId(), 'new-user');
      expect(cloud.snapshot!.payload.values, isNot(contains('Akun lama')));
    },
  );
}

class _SignedInAuthGateway implements AuthGateway {
  _SignedInAuthGateway({this.userId = 'user-1'});

  final String userId;
  final _changes = StreamController<StevAuthUser?>.broadcast();
  StevAuthUser get _user =>
      StevAuthUser(id: userId, email: '$userId@example.com');

  @override
  bool get isAvailable => true;

  @override
  StevAuthUser? get currentUser => _user;

  @override
  Stream<StevAuthUser?> get userChanges => _changes.stream;

  @override
  Future<StevAuthUser> signIn({
    required String email,
    required String password,
  }) async => _user;

  @override
  Future<StevAuthUser?> signUp({
    required String email,
    required String password,
  }) async => _user;

  @override
  Future<void> signOut({bool localOnly = false}) async => _changes.add(null);

  Future<void> dispose() => _changes.close();
}

class _FakeCloudSyncGateway implements CloudSyncGateway {
  _FakeCloudSyncGateway({this.snapshot});

  CloudSnapshot? snapshot;
  String? savedUserId;

  @override
  bool get isAvailable => true;

  @override
  Future<CloudSnapshot?> fetch(String userId) async => snapshot;

  @override
  Future<CloudSnapshot> save(
    String userId,
    Map<String, Object?> payload,
  ) async {
    savedUserId = userId;
    snapshot = CloudSnapshot(
      payload: Map.unmodifiable(payload),
      updatedAt: DateTime.now().toUtc(),
    );
    return snapshot!;
  }

  @override
  Future<void> delete(String userId) async => snapshot = null;
}
