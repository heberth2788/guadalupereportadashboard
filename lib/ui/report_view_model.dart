import 'dart:collection';
import 'package:guadalupereportadashboard/util/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:guadalupereportadashboard/data/report.dart';
import 'package:guadalupereportadashboard/data/report_repository.dart';

/// Provider implementation : ChangeNotifier(Observable)
class ReportViewModel extends ChangeNotifier {

  final ReportRepository _reportRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, Report> _reportMap = <String, Report> {};
  UnmodifiableMapView<String, Report> get reportMap => UnmodifiableMapView(_reportMap);

  List<String> _currentReportPhotos = [];
  UnmodifiableListView<String> get currentReportPhotos => UnmodifiableListView(_currentReportPhotos);

  List<String> _currentResponsePhotos = [];
  UnmodifiableListView<String> get currentResponsePhotos => UnmodifiableListView(_currentResponsePhotos);

  bool get isMaxPhotosReached => _currentResponsePhotos.length < maxAllowedResponsePhotos;

  bool _isImageUploadProcessFinished = true;
  bool get isImageUploadProcessFinished => _isImageUploadProcessFinished;

  ReportViewModel({
    ReportRepository? repository,
  }): _reportRepository = repository ?? ReportRepository() {
    logMsg('report_view_model', msg: 'ReportViewModel');
    _reportRepository.fetchAllReports(_reportNotification);
  }

  void _reportNotification() {
    logMsg('report_view_model', msg: '_reportNotification');
    _reportMap = _reportRepository.reportMap;
    notifyListeners();
  }

  void fetchReportsByDateRange() {
    _reportRepository.fetchReportByDateRange('', '', _reportNotification);
  }

  /*void getPhotos(String userId, String reportId) {
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
  }*/

  Future<void> getPhotos(String userId, String reportId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Run both requests in parallel
      final results = await Future.wait([
        _reportRepository.fetchReportImages(userId, reportId),
        _reportRepository.fetchResponseImages(userId, reportId),
      ]);
      _currentReportPhotos = results[0];
      _currentResponsePhotos = results[1];
    } catch (e) {
      logMsg('report_view_model', msg: 'Error fetching photos: $e');
      _currentReportPhotos = [];
      _currentResponsePhotos = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /*void uploadResponseImage(
    Uint8List imageBytes, 
    String fileExtention, 
    String userId, 
    String reportId,
  ) {
    logMsg('report_view_model', msg: 'uploadResponsePhoto');

    _isImageUploadProcessFinished = false;
    notifyListeners();

    final String imageName = '${ DateTime.now().millisecondsSinceEpoch }.$fileExtention';
    _reportRepository.uploadResponseImage(imageBytes, imageName, userId, reportId)
      .then((String urlResponsePhoto) {
        if (urlResponsePhoto.isNotEmpty) {
          logMsg('report_view_model', msg: 'uploadResponsePhoto > complete');
          _currentResponsePhotos.add(urlResponsePhoto);
        } else {
          logMsg('report_view_model', msg: 'uploadResponsePhoto > failed');
        }

        _isImageUploadProcessFinished = true;
        notifyListeners();
      })
      .onError((error, stackTrace) {
        logMsg('report_view_model', msg: 'uploadResponsePhoto > error : $error');

        _isImageUploadProcessFinished = false;
        notifyListeners();
      });
  }*/

  Future<void> uploadResponseImage(
      Uint8List imageBytes,
      String fileExtention,
      String userId,
      String reportId,
  ) async {
    logMsg('report_view_model', msg: 'uploadResponsePhoto');
    _isImageUploadProcessFinished = false;
    notifyListeners();

    final String imageName = '${ DateTime.now().millisecondsSinceEpoch }.$fileExtention';
    final String urlResponsePhoto = await _reportRepository.uploadResponseImage(imageBytes, imageName, userId, reportId);
    if (urlResponsePhoto.isNotEmpty) {
      logMsg('report_view_model', msg: 'uploadResponsePhoto > complete');
      _currentResponsePhotos.add(urlResponsePhoto);
    } else {
      logMsg('report_view_model', msg: 'uploadResponsePhoto > failed');
    }

    _isImageUploadProcessFinished = true;
    notifyListeners();
  }

  Future<void> saveAuthorityResponseMessage(
    String userId, 
    String reportId,
    String description,
    String authorityId,
    String authorityName,
  ) async {
    logMsg('report_view_model', msg: 'saveAuthorityResponseMessage');
    await _reportRepository.saveResponseMessage(userId, reportId, description, authorityId, authorityName);
    notifyListeners();
  }

  Future<void> updateReportStatus(
      String userId,
      String reportId,
      String date,
      ReportStatus status,
  ) async {
    logMsg('report_view_model', msg: 'updateReportStatus $status');
    await _reportRepository.updateReportStatus(userId, reportId, date, status);
    notifyListeners();
  }
}