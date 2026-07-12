import '../../core/constants.dart';

class ChildProfile {
  final String? childName;
  final int childAgeMonths;
  final String anganwadiId;
  final String districtCode;

  const ChildProfile({
    this.childName,
    required this.childAgeMonths,
    required this.anganwadiId,
    required this.districtCode,
  });

  bool get isValidAge =>
      childAgeMonths >= AppConstants.minAgeMonths &&
      childAgeMonths <= AppConstants.maxAgeMonths;

  Map<String, dynamic> toMap() => {
        'child_name': childName,
        'child_age_months': childAgeMonths,
        'anganwadi_id': anganwadiId,
        'district_code': districtCode,
      };

  factory ChildProfile.fromMap(Map<String, dynamic> map) => ChildProfile(
        childName: map['child_name'] as String?,
        childAgeMonths: map['child_age_months'] as int,
        anganwadiId: map['anganwadi_id'] as String,
        districtCode: map['district_code'] as String,
      );
}
