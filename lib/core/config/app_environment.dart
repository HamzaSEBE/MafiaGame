import 'package:flutter/foundation.dart';

abstract final class AppEnvironment {
  static const avatarStorageEnabled = bool.fromEnvironment(
    'AVATAR_STORAGE_ENABLED',
  );
  static const gameApiUrl = String.fromEnvironment('GAME_API_URL');
  static const enableServerGames = bool.fromEnvironment('ENABLE_SERVER_GAMES');
  static const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  static const emulatorHost = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );
  static const joinBaseUrl = String.fromEnvironment(
    'JOIN_BASE_URL',
    defaultValue: 'https://mafiagame-351f8.web.app',
  );
  static const appCheckWebSiteKey = String.fromEnvironment(
    'APP_CHECK_WEB_SITE_KEY',
  );
  static bool get serverGames =>
      enableServerGames ||
      (kIsWeb && Uri.base.queryParameters['protocol'] == '2');
  static Uri get apiUri {
    final uri = Uri.tryParse(gameApiUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' &&
            !(useEmulators &&
                ['127.0.0.1', 'localhost', '10.0.2.2'].contains(uri.host)))) {
      throw StateError('خادم الجلسات غير مهيأ لهذا الإصدار.');
    }
    return uri;
  }

  static String joinLink(String sessionId, {required int protocol}) =>
      Uri.parse(joinBaseUrl)
          .replace(
            queryParameters: {'session': sessionId, 'protocol': '$protocol'},
          )
          .toString();
}
