import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:game_core/game_core.dart';

Future<void> main() async {
  final server = await HttpServer.bind(
    InternetAddress.anyIPv4,
    int.parse(Platform.environment['PORT'] ?? '8080'),
  );
  await for (final request in server) {
    unawaited(
      handle(request).catchError((Object error) {
        stderr.writeln('request disconnected: ${error.runtimeType}');
      }),
    );
  }
}

Future<void> handle(HttpRequest request) async {
  request.response.headers.contentType = ContentType.json;
  try {
    if (request.method == 'GET' && request.uri.path == '/health') {
      request.response.write('{"ok":true,"protocolVersion":2}');
      return;
    }
    if (request.method != 'POST' || request.uri.path != '/reduce') {
      request.response.statusCode = 404;
      return;
    }
    final bytes = <int>[];
    await for (final chunk in request) {
      bytes.addAll(chunk);
      if (bytes.length > 900000) {
        throw const FormatException('Payload too large');
      }
    }
    final body = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    if (body['protocolVersion'] != 2) {
      throw const FormatException('Unsupported protocol');
    }
    final state = GameState.fromJson(
      Map<String, dynamic>.from(body['state'] as Map),
    );
    if (state.players.isEmpty || state.players.length > 200) {
      throw const FormatException('Invalid room size');
    }
    final at = DateTime.parse(body['at'] as String);
    final actions = (body['actions'] as List? ?? [])
        .map((a) => Map<String, dynamic>.from(a as Map))
        .toList();
    final command = body['command'] as String;
    final result = command == 'project'
        ? state
        : ServerReducer.transition(
            state,
            command,
            actions,
            at,
            body['commandId'] as String,
          );
    request.response.write(
      jsonEncode({
        'protocolVersion': 2,
        'state': result.toJson(),
        'projection': ServerReducer.project(
          result,
          body['revision'] as int,
          nightActions: body['nightActions'] != false,
        ),
        'resultStats': resultStats(result),
      }),
    );
  } catch (error) {
    request.response.statusCode = 400;
    request.response.write(
      jsonEncode({'code': 'INVALID_TRANSITION', 'message': error.toString()}),
    );
  } finally {
    await request.response.close();
  }
}
