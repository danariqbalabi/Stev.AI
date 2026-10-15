enum FamilyProgressStatus { notChecked, assessed, invited, examined }

extension FamilyProgressStatusLabel on FamilyProgressStatus {
  String get label => switch (this) {
    FamilyProgressStatus.notChecked => 'Belum dicek',
    FamilyProgressStatus.assessed => 'Sudah cek risiko',
    FamilyProgressStatus.invited => 'Sudah diajak',
    FamilyProgressStatus.examined => 'Sudah periksa',
  };
}

class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.nickname,
    required this.relationship,
    required this.status,
    required this.updatedAt,
  });

  final String id;
  final String nickname;
  final String relationship;
  final FamilyProgressStatus status;
  final DateTime updatedAt;

  FamilyMember copyWith({
    String? nickname,
    String? relationship,
    FamilyProgressStatus? status,
    DateTime? updatedAt,
  }) {
    return FamilyMember(
      id: id,
      nickname: nickname ?? this.nickname,
      relationship: relationship ?? this.relationship,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
