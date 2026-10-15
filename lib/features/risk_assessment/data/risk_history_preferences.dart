import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/risk_assessment.dart';

class RiskHistoryEntry {
  const RiskHistoryEntry({
    required this.id,
    required this.checkedAt,
    required this.subject,
    required this.level,
    required this.score,
    required this.topFactors,
    this.familyMemberId,
  });

  final String id;
  final DateTime checkedAt;
  final RiskSubject subject;
  final RiskLevel level;
  final int score;
  final List<String> topFactors;
  final String? familyMemberId;

  RiskAssessmentResult toResult() => RiskAssessmentResult(
    subject: subject,
    level: level,
    topFactors: topFactors,
    score: score,
    familyMemberId: familyMemberId,
  );
}

class RiskHistoryPreferences {
  static const storageKey = 'stev-risk-history-v1';
  static const _maxEntries = 20;

  Future<List<RiskHistoryEntry>> read() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(storageKey);
    if (encoded == null) return const [];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => _fromJson(Map<String, Object?>.from(item)))
          .whereType<RiskHistoryEntry>()
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(RiskAssessmentResult result, {DateTime? checkedAt}) async {
    final timestamp = checkedAt ?? DateTime.now();
    final entries = await read();
    final next = [
      RiskHistoryEntry(
        id: timestamp.microsecondsSinceEpoch.toString(),
        checkedAt: timestamp,
        subject: result.subject,
        level: result.level,
        score: result.score,
        topFactors: List.unmodifiable(result.topFactors),
        familyMemberId: result.familyMemberId,
      ),
      ...entries,
    ].take(_maxEntries).toList(growable: false);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      storageKey,
      jsonEncode(next.map(_toJson).toList(growable: false)),
    );
  }

  static Map<String, Object?> _toJson(RiskHistoryEntry entry) => {
    'id': entry.id,
    'checkedAt': entry.checkedAt.toIso8601String(),
    'subject': entry.subject.name,
    'level': entry.level.name,
    'score': entry.score,
    'topFactors': entry.topFactors,
    if (entry.familyMemberId != null) 'familyMemberId': entry.familyMemberId,
  };

  static RiskHistoryEntry? _fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final checkedAt = DateTime.tryParse(json['checkedAt']?.toString() ?? '');
    final subject = _enumByName(RiskSubject.values, json['subject']);
    final level = _enumByName(RiskLevel.values, json['level']);
    final score = json['score'];
    final factors = json['topFactors'];
    if (id is! String ||
        checkedAt == null ||
        subject == null ||
        level == null ||
        score is! num ||
        factors is! List) {
      return null;
    }
    return RiskHistoryEntry(
      id: id,
      checkedAt: checkedAt,
      subject: subject,
      level: level,
      score: score.toInt(),
      topFactors: factors.whereType<String>().toList(growable: false),
      familyMemberId: json['familyMemberId'] is String
          ? json['familyMemberId']! as String
          : null,
    );
  }

  static T? _enumByName<T extends Enum>(List<T> values, Object? name) {
    if (name is! String) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
