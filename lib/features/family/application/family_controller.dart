import 'package:flutter/widgets.dart';

import '../data/family_preferences.dart';
import '../domain/family_member.dart';

class FamilyController extends ChangeNotifier {
  FamilyController({
    Iterable<FamilyMember> initialMembers = const [],
    DateTime Function()? now,
  }) : _members = List.of(initialMembers),
       _preferences = null,
       _now = now ?? DateTime.now;

  FamilyController._persistent({
    required Iterable<FamilyMember> initialMembers,
    required this._preferences,
  }) : _members = List.of(initialMembers),
       _now = DateTime.now;

  static Future<FamilyController> persistent() async {
    final preferences = FamilyPreferences();
    return FamilyController._persistent(
      initialMembers: await preferences.read(),
      preferences: preferences,
    );
  }

  final FamilyPreferences? _preferences;
  final DateTime Function() _now;
  final List<FamilyMember> _members;

  List<FamilyMember> get members => List.unmodifiable(_members);

  FamilyMember? memberById(String id) {
    for (final member in _members) {
      if (member.id == id) return member;
    }
    return null;
  }

  Future<void> add({
    required String nickname,
    required String relationship,
  }) async {
    final normalizedName = nickname.trim();
    final normalizedRelationship = relationship.trim();
    if (normalizedName.isEmpty || normalizedRelationship.isEmpty) return;
    final timestamp = _now();
    _members.insert(
      0,
      FamilyMember(
        id: timestamp.microsecondsSinceEpoch.toString(),
        nickname: normalizedName,
        relationship: normalizedRelationship,
        status: FamilyProgressStatus.notChecked,
        updatedAt: timestamp,
      ),
    );
    await _commit();
  }

  Future<void> updateDetails({
    required String id,
    required String nickname,
    required String relationship,
  }) async {
    final index = _members.indexWhere((member) => member.id == id);
    if (index < 0 || nickname.trim().isEmpty || relationship.trim().isEmpty) {
      return;
    }
    _members[index] = _members[index].copyWith(
      nickname: nickname.trim(),
      relationship: relationship.trim(),
      updatedAt: _now(),
    );
    await _commit();
  }

  Future<void> updateStatus(String id, FamilyProgressStatus status) async {
    final index = _members.indexWhere((member) => member.id == id);
    if (index < 0) return;
    _members[index] = _members[index].copyWith(
      status: status,
      updatedAt: _now(),
    );
    await _commit();
  }

  Future<void> remove(String id) async {
    _members.removeWhere((member) => member.id == id);
    await _commit();
  }

  /// Clears the in-memory session during an app-wide data reset without
  /// recreating the persisted family list.
  void resetLocalState() {
    _members.clear();
    notifyListeners();
  }

  Future<void> _commit() async {
    notifyListeners();
    await _preferences?.write(_members);
  }
}

class FamilyScope extends InheritedNotifier<FamilyController> {
  const FamilyScope({
    super.key,
    required FamilyController controller,
    required super.child,
  }) : super(notifier: controller);

  static FamilyController watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FamilyScope>();
    assert(scope != null, 'FamilyScope is missing above this context.');
    return scope!.notifier!;
  }

  static FamilyController read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<FamilyScope>();
    final scope = element?.widget as FamilyScope?;
    assert(scope != null, 'FamilyScope is missing above this context.');
    return scope!.notifier!;
  }
}
