/// A server-issued grant. Legacy membership grants only themes, never future
/// features. A structured entitlement takes precedence, including revocation.
class PremiumEntitlements {
  const PremiumEntitlements({this.features = const {}, this.expiresAt});
  final Set<String> features;
  final DateTime? expiresAt;
  bool allows(String feature, {DateTime? now}) =>
      features.contains(feature) &&
      (expiresAt == null ||
          expiresAt!.isAfter((now ?? DateTime.now()).toUtc()));

  factory PremiumEntitlements.fromProfile(Map<String, dynamic>? profile) {
    final raw = profile?['entitlements'];
    if ((profile?.containsKey('entitlements') ?? false) && raw is! Map) {
      return const PremiumEntitlements();
    }
    if (raw is! Map) {
      return PremiumEntitlements(
        features: profile?['isPremium'] == true ? const {'themes'} : const {},
      );
    }
    if (raw['status'] != 'active' || raw['schemaVersion'] != 1) {
      return const PremiumEntitlements();
    }
    final expiry = raw['expiresAt'];
    final parsedExpiry = expiry is String ? DateTime.tryParse(expiry) : null;
    if (expiry != null && parsedExpiry == null) {
      return const PremiumEntitlements();
    }
    final list = raw['features'];
    if (list is! List || list.any((value) => value is! String)) {
      return const PremiumEntitlements();
    }
    return PremiumEntitlements(
      features: Set.unmodifiable(list.cast<String>()),
      expiresAt: parsedExpiry,
    );
  }
}
