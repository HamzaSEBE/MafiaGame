import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafia_nightfall/data/repositories/profile_repository.dart';

void main() {
  test(
    'avatar validation rejects oversized and unsupported payloads before upload',
    () {
      expect(() => avatarContentType(Uint8List(300000)), throwsArgumentError);
      expect(
        () => avatarContentType(Uint8List.fromList(List.filled(20, 0))),
        throwsArgumentError,
      );
      expect(
        avatarContentType(Uint8List.fromList([255, 216, 255, 0, 0, 0, 0, 0])),
        'image/jpeg',
      );
      expect(
        avatarContentType(
          Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
        ),
        'image/png',
      );
    },
  );
}
