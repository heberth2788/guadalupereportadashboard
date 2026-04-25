import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Parse a timestamp to a human readable string format.
/// E.g: 21/04/2014 06:16 pm
String getDatetimeFromTimestamp(int timestamp) {
  final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return DateFormat('dd/MM/yyyy hh:mm a').format(date);
}

String getDateFromTimestamp(int? timestamp) {
  if (timestamp == null) return '';

  var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return DateFormat('ddMMyyyy').format(date);
}

/// Logs messages for debugging and informational purposes.
/// [tag] is a label for the log source, [msg] is the message to log.
void logMsg(String tag, { String msg = '' }) {
  if (kDebugMode) {
    debugPrint('[ ${ _getCurrentTime() } $tag: $msg ]');
  }
}

String _getCurrentTime() {
  var now = DateTime.now();
  return DateFormat('hh:mm:ss').format(now);
}