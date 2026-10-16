import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/account_providers.dart';
import 'package:mafia_nightfall/domain/premium/entitlements.dart';

/// Loading and read failures stay visible to the UI and never grant access.
final premiumAccessProvider = Provider<AsyncValue<PremiumEntitlements>>((ref) {
  final access = ref
      .watch(accountProfileProvider)
      .whenData(PremiumEntitlements.fromProfile);
  final expiry = access.asData?.value.expiresAt;
  if (expiry != null && expiry.isAfter(DateTime.now())) {
    final timer = Timer(expiry.difference(DateTime.now()), ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }
  return access;
});
final premiumProvider = Provider<bool>(
  (ref) =>
      ref.watch(premiumAccessProvider).asData?.value.allows('themes') ?? false,
);
