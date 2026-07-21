import '../../core/constants.dart';

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
