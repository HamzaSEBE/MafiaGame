import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mafia_nightfall/data/services/auth_service.dart';

class PremiumNotifier extends StateNotifier<bool> {
  final Ref ref;

  PremiumNotifier(this.ref) : super(false) {
    _init();
  }

  void _init() {
    // Listen to user changes
    ref.listen(authServiceProvider, (previous, next) {
      final user = next.currentUser;
      if (user != null) {
        // Listen to Firestore for premium status
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final isPremium = snapshot.data()!['isPremium'] ?? false;
            state = isPremium;
          }
        });
      } else {
        state = false;
      }
    }, fireImmediately: true);
  }

  Future<void> unlockPremium() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isPremium': true,
      }, SetOptions(merge: true));
    }
    state = true;
  }
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier(ref);
});
