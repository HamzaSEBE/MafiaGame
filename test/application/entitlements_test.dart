import 'package:flutter_test/flutter_test.dart';
import 'package:mafia_nightfall/domain/premium/entitlements.dart';

void main() {
  test('legacy membership grants themes only', () {
    final access = PremiumEntitlements.fromProfile({'isPremium': true});
    expect(access.allows('themes'), true);
    expect(access.allows('futureFeature'), false);
  });
  test('revoked, expired and malformed grants override legacy membership', () {
    for (final grant in [
      {
        'schemaVersion': 1,
        'status': 'revoked',
        'features': ['themes'],
      },
      {
        'schemaVersion': 1,
        'status': 'active',
        'features': ['themes'],
        'expiresAt': '2020-01-01T00:00:00Z',
      },
      {
        'schemaVersion': 1,
        'status': 'active',
        'features': ['themes'],
        'expiresAt': 'invalid',
      },
      {
        'schemaVersion': 1,
        'status': 'active',
        'features': [1],
      },
    ]) {
      expect(
        PremiumEntitlements.fromProfile({
          'isPremium': true,
          'entitlements': grant,
        }).allows('themes'),
        false,
      );
    }
  });
  test('feature-specific grant and exact expiry boundary', () {
    final at = DateTime.utc(2026, 10, 10);
    final access = PremiumEntitlements(
      features: const {'themes'},
      expiresAt: at,
    );
    expect(
      access.allows(
        'themes',
        now: at.subtract(const Duration(milliseconds: 1)),
      ),
      true,
    );
    expect(access.allows('themes', now: at), false);
  });
}
