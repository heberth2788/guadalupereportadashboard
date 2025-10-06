import 'package:firebase_database/firebase_database.dart';
import 'package:guadalupereportadashboard/data/report.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ReportRepository {

  final FirebaseDatabase _fbDatabase = FirebaseDatabase.instance;
  final FirebaseStorage _fbStorage = FirebaseStorage.instance;

  /* late DatabaseReference _dfReports;
  ReportRepository() {
    _dfReports = _fbDatabase.ref('/reports');
  } */

  /// Declare private varible with '_'
  final Map<String, Report> _reportMap = <String, Report>{};
  /// Declare get method for the private variable
  Map<String, Report> get reportMap => _reportMap;

  ///////////////////////////////////////////////////////////////////////////////////////
  /// Methods for fetching data from Firebase Database
  ///////////////////////////////////////////////////////////////////////////////////////

  /// Fetch the report by date range(From - To)
  /// Called every time  data is changed
  void fetchReportByDateRange(String dateFrom, String dateTo, Function() notifyCallback) {
    
    print('ReportRepository > fetchReportByDateRange > $dateFrom - $dateTo');

      DatabaseReference dfReports = _fbDatabase.ref('/day-users-reports');
      Query query = dfReports.orderByKey().startAt(dateFrom).endAt(dateTo);
      query.onValue.listen((DatabaseEvent event) {
        for (final DataSnapshot reportChild in event.snapshot.children) {
          final key = reportChild.key?.toString() ?? '';
          final userId = reportChild.child('userId').value?.toString() ?? '';
          final userName = reportChild.child('userName').value?.toString() ?? '';
          print('$key - $userName - $userId');
        }
      });
  }

  /// Fetch all the reports from firebase database
  /// Called every time  data is changed
  /// TODO : change to an asynchronous method
  void fetchAllReports(Function() notifyCallback) {

    print('ReportRepository > fetchAllReports');

    DatabaseReference dfReports = _fbDatabase.ref('/reports');

    // Called every time data is changed at the specific database reference
    dfReports.onValue.listen((DatabaseEvent event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return;
      }

      //_reportList = [];

      // Iterating the list of reports
      for (final DataSnapshot reportChild in event.snapshot.children) {
        //final report = reportChild.value;
        final key = reportChild.key?.toString() ?? '';
        final acc = double.parse(reportChild.child('acc').value?.toString() ?? '0.0');
        final alt = double.parse(reportChild.child('alt').value?.toString() ?? '0.0');
        final creationTimestamp = int.parse(reportChild.child('creationTimestamp').value?.toString() ?? '0');
        final description = reportChild.child('description').value?.toString() ?? '';
        final doneTimestamp = int.parse(reportChild.child('doneTimestamp').value?.toString() ?? '0');
        final inProgressTimestamp = int.parse(reportChild.child('inProgressTimestamp').value?.toString() ?? '0');
        final lat = double.parse(reportChild.child('lat').value?.toString() ?? '0.0');
        final lon = double.parse(reportChild.child('lon').value?.toString() ?? '0.0');
        final status = int.parse(reportChild.child('status').value?.toString() ?? '0');
        final title = reportChild.child('title').value?.toString() ?? '';
        final userId = reportChild.child('userId').value?.toString() ?? '';
        final userName = reportChild.child('userName').value?.toString() ?? '';
        final visible = bool.parse(reportChild.child('visible').value?.toString() ?? 'true');

        final report = Report(key);
        report.acc = acc;
        report.alt = alt;
        report.creationTimestamp = creationTimestamp;
        report.description = description;
        report.doneTimestamp = doneTimestamp;
        report.inProgressTimestamp = inProgressTimestamp;
        report.lat = lat;
        report.lon = lon;
        report.status = status;
        report.title = title;
        report.userId = userId;
        report.userName = userName;
        report.visible = visible;

        _reportMap[key] = report;
        print(report.toString());
      }
      notifyCallback();
    }, onError: (dynamic error) {
      print(error.toString());
    });
  }

  ///////////////////////////////////////////////////////////////////////////////////////
  /// Methods for fetching data from Firebase Storage
  ///////////////////////////////////////////////////////////////////////////////////////
  
  /// Fetch the images from a specific used and report
  Future<List<String>> fetchImagesFromUserAndReport(String userId, String reportId) async {
    
    Reference rPhotos = _fbStorage.ref('/user-reports-photos/$userId/$reportId');

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
}
