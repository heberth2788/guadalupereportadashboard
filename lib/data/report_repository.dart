import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:guadalupereportadashboard/data/report.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:guadalupereportadashboard/data/report_status.dart';
import 'package:guadalupereportadashboard/data/report_type.dart';
import 'package:guadalupereportadashboard/data/response.dart';
import 'package:guadalupereportadashboard/util/util.dart';
import 'package:guadalupereportadashboard/util/report_status_enum.dart';

class ReportRepository {

  final FirebaseDatabase _fbDatabase = FirebaseDatabase.instance;
  final FirebaseStorage _fbStorage = FirebaseStorage.instance;

  ///////////////////////////////////////////////////////////////////////////////////////
  /// Methods for Firebase Realtime Database
  ///////////////////////////////////////////////////////////////////////////////////////

  /// Fetch the report by date range(From - To)
  /// Called every time  data is changed
  Stream<Map<String, Report>> fetchReports(
    { required int timestampFrom,
      required int timestampTo }
      //String reportType,
      //String reportState,
  ) {
    logMsg('report_repository', msg: 'fetchReports > ${ getDatetimeFromTimestamp(timestampFrom) } - ${ getDatetimeFromTimestamp(timestampTo) }');

    DatabaseReference dfReports = _fbDatabase.ref('/reports');
    Query query = dfReports
        .orderByChild('creationTimestamp')
        .startAt(timestampFrom)
        .endAt(timestampTo);

    return query.onValue.map((DatabaseEvent event) {

      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? { };
      final Map<String, Report> reportMap = { };

      data.forEach((key, value) {
        reportMap[key] = Report.fromMap(key, value as Map<dynamic, dynamic>);
      });

      return reportMap;
    });
  }

  /// Update the status of the report.
  /// Possible status codes: Reported = 0, InProgress = 1, Done = 2, canceled = 666
  Future<void> updateReportStatus(String userId, String reportId, String date, ReportStatusEnum status) async {
    logMsg('report_repository', msg: 'updateReportStatus');

    final int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    final Map<String, int> updates = { };

    updates['/reports/$reportId/status'] = status.code;
    updates['/user-reports/$userId/$reportId/status'] = status.code;

    if (status == ReportStatusEnum.inProgress) {
      updates['/reports/$reportId/inProgressTimestamp'] = currentTimestamp;
      updates['/user-reports/$userId/$reportId/inProgressTimestamp'] = currentTimestamp;
    } else if (status == ReportStatusEnum.done) {
      updates['/reports/$reportId/doneTimestamp'] = currentTimestamp;
      updates['/user-reports/$userId/$reportId/doneTimestamp'] = currentTimestamp;
    } else if (status == ReportStatusEnum.canceled) {
      updates['/reports/$reportId/canceledTimestamp'] = currentTimestamp;
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

  /// Fetch the `report status` from firebase database
  /// Called every time `report status` data is changed
  Stream<ReportStatus> fetchReportStatusStream() {
    logMsg('report_repository', msg: 'fetchReportStatusStream');
    return _fbDatabase.ref('/report-status').onValue.map((DatabaseEvent event) {
      return ReportStatus.fromMap(event.snapshot.value as Map<dynamic, dynamic>);
    });
  }

  /// Fetch the `report type` from firebase database
  /// Called every time `report type` data is changed
  Stream<ReportType> fetchReportTypeStream() {
    logMsg('report_repository', msg: 'fetchReportTypeStream');
    return _fbDatabase.ref('/report-type').onValue.map((DatabaseEvent event) {
      return ReportType.fromMap(event.snapshot.value as Map<dynamic, dynamic>);
    });
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
    String userId,
    String reportId,
    Uint8List imageBytes, 
    String imageName,
  ) async {
    logMsg('report_repository', msg: 'uploadResponseImage');

    late String publicUrlImage;
    final Reference rImage = _fbStorage.ref('/response-photos/$userId/$reportId/$imageName');

    try {
      await rImage.putData(imageBytes);
      publicUrlImage = await rImage.getDownloadURL();
    } on FirebaseException catch (e) {
      logMsg('report_repository', msg: 'uploadResponseImage > error : $e');
      publicUrlImage = "";
      // e.g, e.code == 'canceled'
    }
    return publicUrlImage;
  }

  Future<void> deleteResponseImage(
      String userId,
      String reportId,
      String imageName,
  ) async {
    logMsg('report_repository', msg: 'deleteResponseImage');

    final Reference rImage = _fbStorage.ref('/response-photos/$userId/$reportId/$imageName');

    try {
      await rImage.delete();
    } on FirebaseException catch (e) {
      logMsg('report_repository', msg: 'deleteResponseImage > error : $e');
    }
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