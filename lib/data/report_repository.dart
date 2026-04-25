import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:guadalupereportadashboard/data/report.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:guadalupereportadashboard/data/response.dart';
import 'package:guadalupereportadashboard/util/constants.dart';
import 'package:guadalupereportadashboard/util/report_status.dart';

class ReportRepository {

  final FirebaseDatabase _fbDatabase = FirebaseDatabase.instance;
  final FirebaseStorage _fbStorage = FirebaseStorage.instance;

  /// Declare private varible with '_'
  final Map<String, Report> _reportMap = { };
  /// Declare get method for the private variable
  Map<String, Report> get reportMap => _reportMap;

  ///////////////////////////////////////////////////////////////////////////////////////
  /// Methods for Firebase Realtime Database
  ///////////////////////////////////////////////////////////////////////////////////////

  /// Fetch the report by date range(From - To)
  /// Called every time  data is changed
  void fetchReportByDateRange(String dateFrom, String dateTo, Function() notifyCallback) {
    
    logMsg('report_repository', msg: 'fetchReportByDateRange > $dateFrom - $dateTo');

      DatabaseReference dfReports = _fbDatabase.ref('/day-users-reports');
      Query query = dfReports.orderByKey().startAt(dateFrom).endAt(dateTo);
      query.onValue.listen((DatabaseEvent event) {
        for (final DataSnapshot reportChild in event.snapshot.children) {
          final key = reportChild.key?.toString() ?? '';
          final userId = reportChild.child('userId').value?.toString() ?? '';
          final userName = reportChild.child('userName').value?.toString() ?? '';
          logMsg('report_repository', msg: '$key - $userName - $userId');
        }
      });
  }

  /// Fetch all the reports from firebase database
  /// Called every time  data is changed
  void fetchAllReports(Function() notifyCallback) {
    logMsg('report_repository', msg: 'fetchAllReports');
    _fbDatabase.ref('/reports').onValue.listen((DatabaseEvent event) {
      logMsg('report_repository', msg: 'fetchAllReports > onValue');
      if (!event.snapshot.exists) return;

      logMsg('report_repository', msg: 'fetchAllReports > onValue > event.snapshot.value');
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      _reportMap.clear();
      data.forEach((key, value) {
        _reportMap[key] = Report.fromMap(key, value as Map<dynamic, dynamic>);
      });
      notifyCallback();
    });
  }

  /// Update the status of the report.
  /// Possible status codes: Reported = 0, InProgress = 1, Done = 2, canceled = 666
  Future<void> updateReportStatus(String userId, String reportId, String date, ReportStatus status) async {
    logMsg('report_repository', msg: 'updateReportStatus');

    final int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    final Map<String, int> updates = { };

    updates['/reports/$reportId/status'] = status.code;
    updates['/day-users-reports/$date/$userId/$reportId/status'] = status.code;
    updates['/user-reports/$userId/$reportId/status'] = status.code;

    if (status == ReportStatus.inProgress) {
      updates['/reports/$reportId/inProgressTimestamp'] = currentTimestamp;
      updates['/day-users-reports/$date/$userId/$reportId/inProgressTimestamp'] = currentTimestamp;
      updates['/user-reports/$userId/$reportId/inProgressTimestamp'] = currentTimestamp;
    } else if (status == ReportStatus.done) {
      updates['/reports/$reportId/doneTimestamp'] = currentTimestamp;
      updates['/day-users-reports/$date/$userId/$reportId/doneTimestamp'] = currentTimestamp;
      updates['/user-reports/$userId/$reportId/doneTimestamp'] = currentTimestamp;
    } else if (status == ReportStatus.canceled) {
      updates['/reports/$reportId/canceledTimestamp'] = currentTimestamp;
      updates['/day-users-reports/$date/$userId/$reportId/canceledTimestamp'] = currentTimestamp;
      updates['/user-reports/$userId/$reportId/canceledTimestamp'] = currentTimestamp;
    }

    return _fbDatabase.ref().update(updates);
  }

  /// Save the response message to firebase database for a specific user and report
  Future<void> saveResponseMessage(
      String userId,
      String reportId,
      String message,
      String authorityId,
      String authorityName,
  ) async {
    logMsg('report_repository', msg: 'saveResponseMessage');
    final DatabaseReference dfResponses = _fbDatabase.ref('/responses/$userId/$reportId');
    final int creationTimestamp = DateTime.now().millisecondsSinceEpoch;

    final String authId = authorityId.isEmpty ? FirebaseAuth.instance.currentUser?.uid ?? '' : authorityId;
    final String authName = authorityName.isEmpty ? FirebaseAuth.instance.currentUser?.displayName ?? '' : authorityName;

    await dfResponses.set({
      'message': message,
      'authorityId': authId,
      'authorityName': authName,
      'creationTimestamp': creationTimestamp,
      'visible': true,
    });
  }

  Future<Response> fetchResponse(String userId, String reportId) async {
    logMsg('report_repository', msg: 'fetchResponse userId: $userId , reportId: $reportId');
    final DatabaseEvent event = await _fbDatabase.ref('/responses/$userId/$reportId').once(DatabaseEventType.value);
    final data = event.snapshot.value as Map<dynamic, dynamic>?;

    if (data == null) return Response(userId: userId, reportId: reportId);

    return Response.fromMap(userId, reportId, data);
  }

  ///////////////////////////////////////////////////////////////////////////////////////
  /// Methods for Firebase Storage
  ///////////////////////////////////////////////////////////////////////////////////////
  
  /// Fetch the images from the report of a specific used and report
  Future<List<String>> fetchReportImagesFromUserAndReport(String userId, String reportId) async {

    logMsg('report_repository', msg: 'fetchReportImagesFromUserAndReport');
    
    final Reference rPhotos = _fbStorage.ref('/user-reports-photos/$userId/$reportId');

    final ListResult photosList = await rPhotos.listAll();
    //print('fetchImagesFromReport quantity : ${ photosList.items.length }');
    List<String> photosUrlList = [];
    String pivot;
    for(Reference photoRef in photosList.items) {
      pivot = await photoRef.getDownloadURL();      
      photosUrlList.add(pivot);
      //print('fetchImagesFromReport : B : ${ photosUrlList.length }');
    }
    //print('fetchImagesFromReport : C : ${ photosUrlList.length }');
    return photosUrlList;
  }

  /// Fetch the images from the response of a specific used and report
  Future<List<String>> fetchResponseImagesFromUserAndReport(String userId, String reportId) async {

    logMsg('report_repository', msg: 'fetchResponseImagesFromUserAndReport');
    
    final Reference rPhotos = _fbStorage.ref('/response-photos/$userId/$reportId');

    final ListResult photosList = await rPhotos.listAll();
    //print('fetchResponseImagesFromReport quantity : ${ photosList.items.length }');
    List<String> photosUrlList = [];
    String pivot;
    for(Reference photoRef in photosList.items) {
      pivot = await photoRef.getDownloadURL();      
      photosUrlList.add(pivot);
      //print('fetchImagesFromReport : B : ${ photosUrlList.length }');
    }
    //print('fetchImagesFromReport : C : ${ photosUrlList.length }');
    return photosUrlList;
  }

  /// Upload an image file to firebase storage for a specific user and report
  Future<String> uploadResponseImage(
    Uint8List imageBytes, 
    String imageName, 
    String userId, 
    String reportId,
  ) async {
    logMsg('report_repository', msg: 'uploadResponseImage');

    late String publicUrlPhoto;
    final Reference rPhotos = _fbStorage.ref('/response-photos/$userId/$reportId/$imageName');

    try {
      await rPhotos.putData(imageBytes);
      publicUrlPhoto = await rPhotos.getDownloadURL();
    } on FirebaseException catch (e) {
      logMsg('report_repository', msg: 'uploadResponseImage > error : $e');
      publicUrlPhoto = "";
      // e.g, e.code == 'canceled'
    }
    return publicUrlPhoto;
  }

  // Generic helper for fetching images
  Future<List<String>> _fetchImages(String path) async {
    final ListResult result = await _fbStorage.ref(path).listAll();
    return Future.wait(result.items.map((ref) => ref.getDownloadURL()));
  }

  Future<List<String>> fetchReportImages(
      String userId,
      String reportId,
  ) => _fetchImages('/user-reports-photos/$userId/$reportId');

  Future<List<String>> fetchResponseImages(
      String userId,
      String reportId,
  ) => _fetchImages('/response-photos/$userId/$reportId');
}