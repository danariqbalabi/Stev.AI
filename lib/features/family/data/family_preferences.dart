import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/family_member.dart';
import '../../profile/data/local_data_preferences.dart';

class FamilyPreferences {
  static const storageKey = 'stev-family-members-v1';

  Future<List<FamilyMember>> read() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(storageKey);
    if (encoded == null) return const [];

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => _fromJson(Map<String, Object?>.from(item)))
          .whereType<FamilyMember>()
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> write(Iterable<FamilyMember> members) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      storageKey,
      jsonEncode(members.map(_toJson).toList(growable: false)),
    );
    await LocalDataPreferences.touch();
  }

  static Map<String, Object?> _toJson(FamilyMember member) => {
    'id': member.id,
    'nickname': member.nickname,
    'relationship': member.relationship,
    'status': member.status.name,
    'updatedAt': member.updatedAt.toIso8601String(),
  };

  static FamilyMember? _fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final nickname = json['nickname'];
    final relationship = json['relationship'];
    final statusName = json['status'];
    final updatedAtValue = json['updatedAt'];
    if (id is! String ||
        nickname is! String ||
        relationship is! String ||
        statusName is! String ||
        updatedAtValue is! String) {
      return null;
    }
    final status = FamilyProgressStatus.values
        .where((value) => value.name == statusName)
        .firstOrNull;
    final updatedAt = DateTime.tryParse(updatedAtValue);
    if (status == null || updatedAt == null) return null;
    return FamilyMember(
      id: id,
      nickname: nickname,
      relationship: relationship,
      status: status,
      updatedAt: updatedAt,
    );
  }
}
