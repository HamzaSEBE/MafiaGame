import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Aggregate-statistics deduplication only: no game ID, date or report payload.
String resultReceiptId(String uid, String gameId) =>
    sha256.convert(utf8.encode('$uid/$gameId')).toString();
