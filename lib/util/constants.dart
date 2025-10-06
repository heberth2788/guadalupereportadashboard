import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

const double zoomMapValue = 15.0;
const String appTitle = "Guadalupe Reporta Dashboard";
const int  startingYear = 2023;
const int rangeDays = 21;
const Color seedColor = Color.fromRGBO(60, 105, 27, 0); // Const for material theme
const Size markerSize = Size(40, 40); // Size of the pin on the map

final ButtonStyle buttonStyle = ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 13));
const TextStyle reportTitleTextStyle = TextStyle(fontSize: 17, fontWeight: FontWeight.bold);
const TextStyle reportStatusTextStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.normal, fontStyle: FontStyle.italic);
const TextStyle reportUserAndDateTextStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.normal);
const TextStyle reportCommentTextStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.normal);

const LatLng latLonGuadalupe = LatLng(-7.243271, -79.470281); // Guadalupe city's location

/// Parse a timestamp to a human readable string format. 
/// E.g: 21/04/2014 06:16 pm
String getDatetimeFromTimestamp(int? timestamp) {
  if (timestamp == null) return '-';

  var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return DateFormat('dd/MM/yyy hh:mm a').format(date);
}

/// Parse the int status value to its string value
String getStringStatus(int? intStatus) {
  if (intStatus == 0) {
    return 'Reported';
  } else if (intStatus == 1) {
    return 'InProgress';
  } else if (intStatus == 2) {
    return 'Done';
  }
  return '-';
}

/// Logs messages for debugging and informational purposes.
/// [tag] is a label for the log source, [msg] is the message to log.
void logMsg(String tag, { String msg = '' }) {
  if (kDebugMode) {
    debugPrint('[ $tag: $msg ]');
  }
}