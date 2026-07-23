import '../../core/constants.dart';
import 'package:uuid/uuid.dart';

class ChildProfile {
  final String childUuid;
  final String? childName;
  final int childAgeMonths;
  final DateTime birthDate;
  final int? gestationalWeeks;
  final String anganwadiId;
  final String districtCode;

  const ChildProfile({
    required this.childUuid,
    this.childName,
    required this.childAgeMonths,
    required this.birthDate,
    this.gestationalWeeks,
    required this.anganwadiId,
    required this.districtCode,
  });

  bool get isValidAge =>
      childAgeMonths >= AppConstants.minAgeMonths &&
      childAgeMonths <= AppConstants.maxAgeMonths;

  /// Produces the same UUID whenever the same child details are entered for a
  /// repeat screening. The age is deliberately excluded because it changes
  /// over time; date of birth is the stable value used instead.
  static String stableUuid({
    required String? childName,
    required DateTime birthDate,
    required String anganwadiId,
    required String districtCode,
  }) {
    String normalize(String? value) => value?.trim().toLowerCase() ?? '';
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final birthDateKey =
        '${birthDate.year.toString().padLeft(4, '0')}-${twoDigits(birthDate.month)}-${twoDigits(birthDate.day)}';
    final identity = [
      normalize(childName),
      birthDateKey,
      normalize(anganwadiId),
      normalize(districtCode),
    ].join('|');
    return const Uuid().v5(
      Namespace.url.value,
      'mozhimuthal-child-v1|$identity',
    );
  }

  Map<String, dynamic> toMap() => {
    'child_uuid': childUuid,
    'child_name': childName,
    'child_age_months': childAgeMonths,
    'birth_date': birthDate.toIso8601String(),
    'gestational_weeks': gestationalWeeks,
    'anganwadi_id': anganwadiId,
    'district_code': districtCode,
  };

  factory ChildProfile.fromMap(Map<String, dynamic> map) => ChildProfile(
    childUuid: map['child_uuid'] as String,
    childName: map['child_name'] as String?,
    childAgeMonths: map['child_age_months'] as int,
    birthDate: DateTime.parse(map['birth_date'] as String),
    gestationalWeeks: map['gestational_weeks'] as int?,
    anganwadiId: map['anganwadi_id'] as String,
    districtCode: map['district_code'] as String,
  );
}
