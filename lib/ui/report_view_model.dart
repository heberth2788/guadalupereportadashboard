import 'dart:collection';
import 'package:guadalupereportadashboard/util/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:guadalupereportadashboard/data/report.dart';
import 'package:guadalupereportadashboard/data/report_repository.dart';
import 'package:guadalupereportadashboard/util/report_status.dart';

import '../data/response.dart';

/// Provider implementation : ChangeNotifier(Observable)
class ReportViewModel extends ChangeNotifier {

  final ReportRepository _reportRepository;

  Map<String, Report> _reportMap = <String, Report> {};
  UnmodifiableMapView<String, Report> get reportMap => UnmodifiableMapView(_reportMap);

  Report _currentReport = Report(id: empty);
  Report get currentReport => _currentReport;

  List<String> _currentReportPhotos = [];
  UnmodifiableListView<String> get currentReportPhotos => UnmodifiableListView(_currentReportPhotos);
  
  Response _currentResponse = Response(userId: empty, reportId: empty);
  Response get currentResponse => _currentResponse;

  List<String> _currentResponsePhotos = [];
  UnmodifiableListView<String> get currentResponsePhotos => UnmodifiableListView(_currentResponsePhotos);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isImageUploadProcessFinished = true;
  bool get isImageUploadProcessFinished => _isImageUploadProcessFinished;

  bool _isSavingResponseData = false;
  bool get isSavingResponseData => _isSavingResponseData;

  bool get isMaxPhotosReached => _currentResponsePhotos.length < maxAllowedResponsePhotos;

  ReportViewModel({
    ReportRepository? repository,
  }): _reportRepository = repository ?? ReportRepository() {
    logMsg('report_view_model', msg: 'ReportViewModel');
    _reportRepository.fetchAllReports(_notifyReportsUpdate);
  }

  Future<void> fetchReportData(String reportId) async {
    logMsg('report_view_model', msg: 'fetchReportData');
    _isLoading = true;
    notifyListeners();

    // TODO: remove this delay (Added for testing purposes)
    await Future.delayed(Duration(seconds: 3));

    // Set the current report
    _currentReport = _reportMap[reportId] ?? Report(id: empty);

    await Future.wait([
      _fetchResponse(), // Get the response of the selected report
      _getPhotos(), // Get the photos of the selected report
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchResponse() async {
    logMsg('report_view_model', msg: '_fetchResponse');
    _currentResponse = await _reportRepository.fetchResponse(_currentReport.userId, _currentReport.id);
    logMsg('report_view_model', msg: '_fetchResponse > ${ _currentResponse.message }');
  }

  Future<void> _getPhotos() async {
    logMsg('report_view_model', msg: '_getPhotos');
    try {
      // Run both requests in parallel
      final List<List<String>> photosResult = await Future.wait([
        _reportRepository.fetchReportImages(_currentReport.userId, _currentReport.id),
        _reportRepository.fetchResponseImages(_currentReport.userId, _currentReport.id),
      ]);
      _currentReportPhotos = photosResult[0];
      _currentResponsePhotos = photosResult[1];
    } catch (e) {
      logMsg('report_view_model', msg: 'Error fetching photos: $e');
      _currentReportPhotos = [];
      _currentResponsePhotos = [];
    }
  }

  void _notifyReportsUpdate() {
    logMsg('report_view_model', msg: '_notifyReportsUpdate');
    _reportMap = _reportRepository.reportMap;
    final Report report = _reportMap[_currentReport.id] ?? Report(id: empty);
    _currentReport = report;

    notifyListeners();
  }

  /*void fetchReportsByDateRange() {
    _reportRepository.fetchReportByDateRange('', '', _reportNotification);
  }*/

  Future<void> uploadResponseImage(
      Uint8List imageBytes,
      String fileExtension,
      String userId,
      String reportId,
  ) async {
    logMsg('report_view_model', msg: 'uploadResponsePhoto');
    _isImageUploadProcessFinished = false;
    notifyListeners();

    final String imageName = '${ DateTime.now().millisecondsSinceEpoch }.$fileExtension';
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

  Future<void> upsertAuthorityResponseMessage(String message) async {
    logMsg('report_view_model', msg: 'saveAuthorityResponseMessage');
    _isSavingResponseData = true;
    notifyListeners();

    // TODO: remove this delay (Added for testing purposes)
    await Future.delayed(Duration(seconds: 3));

    await _reportRepository.saveResponseMessage(
      _currentReport.userId,
      _currentReport.id,
      message,
      _currentResponse.authorityId,
      _currentResponse.authorityName,
    );

    _isSavingResponseData = false;
    notifyListeners();
  }

  Future<void> updateReportStatus(
      String userId,
      String reportId,
      String date,
      ReportStatus status,
  ) async {
    logMsg('report_view_model', msg: 'updateReportStatus $status');
    _isSavingResponseData = true;
    notifyListeners();

    // TODO: remove this delay (Added for testing purposes)
    await Future.delayed(Duration(seconds: 3));

    await _reportRepository.updateReportStatus(userId, reportId, date, status);

    _isSavingResponseData = false;
    notifyListeners();
  }
}