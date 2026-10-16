import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafia_nightfall/application/account_providers.dart';
import 'package:mafia_nightfall/application/premium_service.dart';

void main() {
  test('missing, malformed and failed entitlement reads fail closed', () async {
    final profile = StreamController<Map<String, dynamic>?>();
    final container = ProviderContainer(
      overrides: [accountProfileProvider.overrideWith((ref) => profile.stream)],
    );
    addTearDown(container.dispose);
    addTearDown(profile.close);
    final subscription = container.listen(premiumProvider, (_, __) {});
    addTearDown(subscription.close);
    expect(container.read(premiumProvider), false);
    for (final event in [
      null,
      <String, dynamic>{},
      {'isPremium': 'true'},
      {'isPremium': true},
      {'isPremium': false},
    ]) {
      profile.add(event);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(premiumProvider), event?['isPremium'] == true);
    }
    profile.add({'isPremium': true});
    await Future<void>.delayed(Duration.zero);
    profile.addError(StateError('disconnected'));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(premiumProvider), false);
  });
}
