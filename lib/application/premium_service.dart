import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simple state provider for premium status. 
// In a real app, this would check SharedPreferences or RevenueCat/In-App Purchases.
class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier() : super(false); // Default to not premium

  void unlockPremium() {
    state = true;
  }
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier();
});
