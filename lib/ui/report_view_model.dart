import 'dart:collection';
import 'package:guadalupereportadashboard/util/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:guadalupereportadashboard/data/report.dart';
import 'package:guadalupereportadashboard/data/report_repository.dart';

/// Provider implementation : ChangeNotifier(Observable)
class ReportViewModel extends ChangeNotifier {
  
  final ReportRepository _reportRepository = ReportRepository();

  Map<String, Report> _reportMap = <String, Report> {};
  UnmodifiableMapView<String, Report> get reportMap => UnmodifiableMapView(_reportMap);

  List<String> _currentReportPhotos = [];
  UnmodifiableListView<String> get currentReportPhotos => UnmodifiableListView(_currentReportPhotos);

  List<String> _currentResponsePhotos = [];
  UnmodifiableListView<String> get currentResponsePhotos => UnmodifiableListView(_currentResponsePhotos);

  bool get isMaxPhotosReached => _currentResponsePhotos.length < maxAllowedResponsePhotos;

  bool _isImageUploadProcessFinished = true;
  bool get isImageUploadProcessFinished => _isImageUploadProcessFinished;

  ReportViewModel() : super() {
    _reportRepository.fetchAllReports(_reportNotification);
  }

  void _reportNotification() {
    logMsg('ReportViewModel', msg: '_reportNotification');
    _reportMap = _reportRepository.reportMap;
    notifyListeners();
  }

  void fetchReportsByDateRange() {
    _reportRepository.fetchReportByDateRange('', '', _reportNotification);
  }

  void getPhotos(String userId, String reportId) {
    logMsg('ReportViewModel', msg: 'getPhotos');

    _reportRepository.fetchReportImagesFromUserAndReport(userId, reportId)
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

    _reportRepository.fetchResponseImagesFromUserAndReport(userId, reportId)
      .then((List<String> responseList){
        _currentResponsePhotos = responseList;
        //print('getPhotos : then : ${ _currentResponsePhotos.length }');
         notifyListeners();
      })
      .onError((error, stackTrace) {
        _currentResponsePhotos = [];
        //print('getPhotos : error : ${ stackTrace.toString() }');
        notifyListeners();
      });
  }

  void uploadResponseImage(
    Uint8List imageBytes, 
    String fileExtention, 
    String userId, 
    String reportId,
  ) {
    logMsg('ReportViewModel', msg: 'uploadResponsePhoto');

    _isImageUploadProcessFinished = false;
    notifyListeners();

    final String imageName = '${ DateTime.now().millisecondsSinceEpoch }.$fileExtention';
    _reportRepository.uploadResponseImage(imageBytes, imageName, userId, reportId)
      .then((String urlResponsePhoto) {
        if (urlResponsePhoto.isNotEmpty) {
          logMsg('ReportViewModel', msg: 'uploadResponsePhoto > complete');
          _currentResponsePhotos.add(urlResponsePhoto);
        } else {
          logMsg('ReportViewModel', msg: 'uploadResponsePhoto > failed');
        }

        _isImageUploadProcessFinished = true;
        notifyListeners();
      })
      .onError((error, stackTrace) {
        logMsg('ReportViewModel', msg: 'uploadResponsePhoto > error : $error');

        _isImageUploadProcessFinished = false;
        notifyListeners();
      });
  }

  void saveAuthorityResponseMessage(
    String userId, 
    String reportId,
    String description,
    String authorityId,
    String authorityName,
  ) {
    logMsg('ReportViewModel', msg: 'saveAuthorityResponseMessage');
    _reportRepository.saveResponseMessage(userId, reportId, description, authorityId, authorityName)
    .then((void _) {
      logMsg('ReportViewModel', msg: 'saveAuthorityResponseMessage > complete');
    }).onError((error, stackTrace) {
      logMsg('ReportViewModel', msg: 'saveAuthorityResponseMessage > error : $error');
    });
    notifyListeners();
  }
}