import 'package:flutter_test/flutter_test.dart';
import 'package:mozhimuthal/data/models/child_profile.dart';

void main() {
  test('stable child UUID is reused when child details are entered again', () {
    final first = ChildProfile.stableUuid(
      childName: ' Anu ',
      birthDate: DateTime(2024, 1, 3, 18),
      anganwadiId: ' KL-IDK-042 ',
      districtCode: 'IDK',
    );
    final repeat = ChildProfile.stableUuid(
      childName: 'anu',
      birthDate: DateTime(2024, 1, 3),
      anganwadiId: 'kl-idk-042',
      districtCode: 'idk',
    );

    expect(repeat, first);
  });

  test('stable child UUID changes when the child identity changes', () {
    final first = ChildProfile.stableUuid(
      childName: 'Anu',
      birthDate: DateTime(2024, 1, 3),
      anganwadiId: 'KL-IDK-042',
      districtCode: 'IDK',
    );
    final anotherChild = ChildProfile.stableUuid(
      childName: 'Binu',
      birthDate: DateTime(2024, 1, 3),
      anganwadiId: 'KL-IDK-042',
      districtCode: 'IDK',
    );

    expect(anotherChild, isNot(first));
  });
}
