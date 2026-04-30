import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

//region General constants
const int startingYear = 2026;
const int rangeDays = 63;
const int maxAllowedResponsePhotos = 3; // Maximum number of response photos allowed
const double rightPanelWidth = 500.0;
const double shimmerHeight = 630.0;
const String empty = '';
//endregion

//region Report status constants
const int reportStatusCreatedId = 2;
const int reportStatusInProgressId = 3;
const int reportStatusDoneId = 4;
const int reportStatusCanceledId = 666;
//endregion

//region Styling constants
const Color seedColor = Color.fromRGBO(60, 105, 27, 0); // Const for material theme
final ButtonStyle buttonStyle = ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 13));
const TextStyle reportTitleTextStyle = TextStyle(fontSize: 17, fontWeight: FontWeight.bold);
const TextStyle reportStatusTextStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontStyle: FontStyle.normal);
const TextStyle reportUserAndDateTextStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.normal);
const TextStyle reportCommentTextStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.normal);
//endregion

//region Google Maps constants
const LatLng latLngGuadalupe = LatLng(-7.243271, -79.470281); // Guadalupe city's location
const String mapId = '7370104ef8b1c0e23253acdd';
const String createdPinAssetPath = 'assets/images/pins/pin_red.png';
const String inProgressPinAssetPath = 'assets/images/pins/pin_black.png';
const String donePinAssetPath = 'assets/images/pins/pin_blue.png';
const String canceledPinAssetPath = 'assets/images/pins/pin_white.png';
const Size markerSize = Size(40, 40); // Size of the pin on the map (Alternatives: Size(24, 24), Size(32, 32))
const double zoomMapValue = 15.0;
//endregion

//region UI text constants
const String strAppTitle = "Panel de reportes";
const String strRange = 'Rango :';
const String strReportsQuantity = 'Cantidad de reportes :';
const String strResponse = 'Respuesta';
const String strCancel = 'Anular';
const String strInProgress = 'En progreso';
const String strDone = 'Atendido';
const String strPhoto = 'Foto';
const String strHintTextWriteResponse = 'Escribir respuesta...';
const String strSave = 'Guardar';
const String strLogout = 'Cerrar sessión';
//endregion