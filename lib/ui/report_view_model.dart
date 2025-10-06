import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:guadalupereportadashboard/data/report.dart';
import 'package:guadalupereportadashboard/data/report_repository.dart';

/// Provider implementation : ChangeNotifier(Observable)
class ReportViewModel extends ChangeNotifier {
  
  final ReportRepository _reportRepository = ReportRepository();

  Map<String, Report> _reportMap = <String, Report>{};
  UnmodifiableMapView<String, Report> get reportMap => UnmodifiableMapView(_reportMap);

  List<String> _currentReportPhotos = [];
  UnmodifiableListView<String> get currentReportPhotos => UnmodifiableListView(_currentReportPhotos);

  ReportViewModel() : super() {
    _reportRepository.fetchAllReports(_reportNotification);
  }

  void _reportNotification() {
    print('ReportViewModel > reportNotification');
    _reportMap = _reportRepository.reportMap;
    notifyListeners();
  }

  void fetchReportsByDateRange() {
    _reportRepository.fetchReportByDateRange('', '', _reportNotification);
  }

  void getPhotos(String userId, String reportId) {
    print('ReportViewModel > getPhotos');
    _reportRepository.fetchImagesFromUserAndReport(userId, reportId)
      .then((List<String> reportList){
        _currentReportPhotos = reportList;
        //print('getPhotos : then : ${ _currentReportPhotos.length }');
         notifyListeners();
      })
      .onError((error, stackTrace) {
        _currentReportPhotos = [];
        //print('getPhotos : error : ${ stackTrace.toString() }');
        notifyListeners();
      });
  }
}