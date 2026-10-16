import 'dart:typed_data';
import 'dart:convert';
import 'package:mafia_nightfall/core/config/app_environment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:mafia_nightfall/application/account_providers.dart';

String avatarContentType(Uint8List bytes) {
  if (bytes.length > 256 * 1024 || bytes.length < 8) {
    throw ArgumentError('اختر صورة أصغر من 256 كيلوبايت.');
  }
  if (bytes[0] == 0xff && bytes[1] == 0xd8 && bytes[2] == 0xff) {
    return 'image/jpeg';
  }
  if (bytes.take(8).join(',') == '137,80,78,71,13,10,26,10') return 'image/png';
  throw ArgumentError('الصورة يجب أن تكون JPEG أو PNG.');
}

class ProfileRepository {
  ProfileRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _db = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  Future<void> saveAvatar(String uid, Uint8List bytes) async {
    final type = avatarContentType(bytes);
    if (!AppEnvironment.avatarStorageEnabled) {
      // Spark-compatible, bounded legacy representation. Storage migration is
      // explicitly enabled only when a bucket and billing are configured.
      await _db.collection('users').doc(uid).set({
        'photoBase64': base64Encode(bytes),
        'photoVersion': const Uuid().v4(),
        'photoPath': FieldValue.delete(),
      }, SetOptions(merge: true));
      return;
    }
    final version = const Uuid().v4();
    final path = 'avatars/$uid/$version.${type == 'image/png' ? 'png' : 'jpg'}';
    final photo = _storage.ref(path);
    await photo.putData(
      bytes,
      SettableMetadata(
        contentType: type,
        cacheControl: 'private,max-age=86400',
      ),
    );
    String? oldPath;
    try {
      await _db.runTransaction((tx) async {
        final account = _db.collection('users').doc(uid);
        oldPath = (await tx.get(account)).data()?['photoPath'] as String?;
        tx.set(account, {
          'photoPath': path,
          'photoVersion': version,
          'photoBase64': FieldValue.delete(),
        }, SetOptions(merge: true));
      });
    } catch (_) {
      try {
        await photo.delete();
      } catch (_) {}
      rethrow;
    }
    if (oldPath != null &&
        oldPath!.startsWith('avatars/$uid/') &&
        oldPath != path) {
      try {
        await _storage.ref(oldPath).delete();
      } catch (_) {
        /* Old object can be removed by storage lifecycle. */
      }
    }
  }
}

final profileRepositoryProvider = Provider((ref) => ProfileRepository());
final profileAvatarProvider = FutureProvider<Uint8List?>((ref) async {
  final uid = ref.watch(accountIdProvider);
  final path = ref.watch(accountProfileProvider).asData?.value?['photoPath'];
  if (uid == null || path is! String || !path.startsWith('avatars/$uid/')) {
    return null;
  }
  return FirebaseStorage.instance.ref(path).getData(256 * 1024);
});
