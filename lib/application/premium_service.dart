import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mafia_nightfall/data/services/auth_service.dart';

class PremiumNotifier extends StateNotifier<bool> {
  final Ref ref;
  StreamSubscription? _subscription;

  PremiumNotifier(this.ref) : super(false) {
    _init();
  }

  void _init() {
    ref.listen(authServiceProvider, (previous, next) {
      final user = next.currentUser;
      
      _subscription?.cancel();
      
      if (user != null) {
        _subscription = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final isPremium = snapshot.data()!['isPremium'] ?? false;
            if (mounted) state = isPremium;
          }
        });
      } else {
        if (mounted) state = false;
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> unlockPremium() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isPremium': true,
      }, SetOptions(merge: true));
    }
    if (mounted) state = true;
  }
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier(ref);
});
