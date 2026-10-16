import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:mafia_nightfall/core/config/app_environment.dart';

class GameApiException implements Exception {
  const GameApiException(this.code, this.status);
  final String code;
  final int status;
  @override
  String toString() => switch (code) {
    'STALE_WINDOW' ||
    'WINDOW_CLOSED' => 'انتهت نافذة الحركة. اختر مجدداً في الجولة الحالية.',
    'HOST_BUSY' || 'HOST_LEASE_LOST' =>
      'الجلسة مفتوحة من جهاز حكم آخر. أعد فتحها بعد انتهاء الاتصال السابق.',
    'STALE_STATE' => 'تم تحديث اللعبة. أعد فتح شاشة الحكم.',
    'BALLOT_CONFLICT' => 'تغيّر تصويتك من نافذة أخرى. أعد تحميل الاختيار.',
    'TOO_FAST' => 'انتظر لحظة وأعد المحاولة.',
    'ACTIVE_ROOM_EXISTS' => 'لديك جلسة نشطة. تابعها أو أنهِها أولاً.',
    _ => 'تعذر إكمال الطلب ($code). أعد المحاولة.',
  };
}

class GameApiClient {
  GameApiClient(this.auth, {http.Client? client})
    : _client = client ?? http.Client();
  final FirebaseAuth auth;
  final http.Client _client;
  final String hostInstanceId = const Uuid().v4();
  final Map<String, Map<String, dynamic>> _pending = {};
  void close() => _client.close();
  Future<Map<String, dynamic>> request(
    String sessionId,
    String operation,
    Map<String, dynamic> data, {
    String? retryKey,
  }) async {
    final token = await auth.currentUser?.getIdToken();
    if (token == null) throw const GameApiException('UNAUTHENTICATED', 401);
    final body = retryKey == null
        ? {...data}
        : _pending.putIfAbsent(
            retryKey,
            () => {
              ...data,
              'commandId': data['commandId'] ?? const Uuid().v4(),
            },
          );
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    if (!AppEnvironment.useEmulators) {
      final appToken = await FirebaseAppCheck.instance.getToken();
      if (appToken != null) headers['X-Firebase-AppCheck'] = appToken;
    }
    final uri = AppEnvironment.apiUri.resolve(
      '/v2/sessions/$sessionId/$operation',
    );
    final response = await _client
        .post(
          uri,
          headers: headers,
          body: jsonEncode({...body, 'protocolVersion': 2}),
        )
        .timeout(const Duration(seconds: 25));
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      if (response.statusCode < 500 &&
          response.statusCode != 429 &&
          result['code'] != 'TRANSITION_PENDING') {
        _pending.remove(retryKey);
      }
      throw GameApiException(
        result['code'] as String? ?? 'SERVICE_UNAVAILABLE',
        response.statusCode,
      );
    }
    _pending.remove(retryKey);
    return result;
  }
}
