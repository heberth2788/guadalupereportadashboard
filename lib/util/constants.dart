import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

const double zoomMapValue = 15.0;
const String appTitle = "Panel de reportes";
const int  startingYear = 2023;
const int rangeDays = 63; //21;
const Color seedColor = Color.fromRGBO(60, 105, 27, 0); // Const for material theme
const Size markerSize = Size(40, 40); // Size of the pin on the map
const int maxAllowedResponsePhotos = 3; // Maximum number of response photos allowed
const String redPinAssetPath = 'images/pins/pin_red.png';

final ButtonStyle buttonStyle = ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 13));
const TextStyle reportTitleTextStyle = TextStyle(fontSize: 17, fontWeight: FontWeight.bold);
const TextStyle reportStatusTextStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontStyle: FontStyle.normal);
const TextStyle reportUserAndDateTextStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.normal);
const TextStyle reportCommentTextStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.normal);

const LatLng latLonGuadalupe = LatLng(-7.243271, -79.470281); // Guadalupe city's location

/// Parse a timestamp to a human readable string format. 
/// E.g: 21/04/2014 06:16 pm
String getDatetimeFromTimestamp(int? timestamp) {
  if (timestamp == null) return '';

  var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return DateFormat('dd/MM/yyyy hh:mm a').format(date);
}

String getDateFromTimestamp(int? timestamp) {
  if (timestamp == null) return '';

  var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return DateFormat('ddMMyyyy').format(date);
}

String _getCurrentTime() {
  var now = DateTime.now();
  return DateFormat('hh:mm:ss').format(now);
}

/// Logs messages for debugging and informational purposes.
/// [tag] is a label for the log source, [msg] is the message to log.
void logMsg(String tag, { String msg = '' }) {
  if (kDebugMode) {
    debugPrint('[ ${ _getCurrentTime() } $tag: $msg ]');
  }
}

enum ReportStatus {
  created(0, "REPORTADO"),
  inProgress(1, "EN PROGRESO"),
  done(2, "ATENDIDO"),
  canceled(666, "ANULADO");

  final int code;
  final String description;

  const ReportStatus(this.code, this.description);

  static ReportStatus findByCode(int? code) {
    for (var status in ReportStatus.values) {
      if (status.code == code) {
        return status;
      }
    }
    return ReportStatus.canceled;
  }
}