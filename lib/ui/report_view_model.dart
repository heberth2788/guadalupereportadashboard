import 'dart:collection';
import 'package:guadalupereportadashboard/util/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:guadalupereportadashboard/data/report.dart';
import 'package:guadalupereportadashboard/data/report_repository.dart';
import 'package:guadalupereportadashboard/util/report_status.dart';

/// Provider implementation : ChangeNotifier(Observable)
class ReportViewModel extends ChangeNotifier {

  final ReportRepository _reportRepository;

  Map<String, Report> _reportMap = <String, Report> {};
  UnmodifiableMapView<String, Report> get reportMap => UnmodifiableMapView(_reportMap);

  Report _currentReport = Report(id: emptyReportId);
  Report get currentReport => _currentReport;

  List<String> _currentReportPhotos = [];
  UnmodifiableListView<String> get currentReportPhotos => UnmodifiableListView(_currentReportPhotos);

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
    _reportRepository.fetchAllReports(_reportNotification);
  }

  void _reportNotification() {
    logMsg('report_view_model', msg: '_reportNotification');
    _reportMap = _reportRepository.reportMap;
    final Report report = _reportMap[_currentReport.id] ?? Report(id: emptyReportId);
    _currentReport = report;
    notifyListeners();
  }

  void fetchReportsByDateRange() {
    _reportRepository.fetchReportByDateRange('', '', _reportNotification);
  }

  Future<void> getPhotos(String userId, String reportId) async {
    _isLoading = true;
    notifyListeners();

    // TODO: remove this delay (Added for testing purposes)
    await Future.delayed(Duration(seconds: 3));

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

  Future<void> saveAuthorityResponseMessage(
    String userId, 
    String reportId,
    String description,
    String authorityId,
    String authorityName,
  ) async {
    logMsg('report_view_model', msg: 'saveAuthorityResponseMessage');
    _isSavingResponseData = true;
    notifyListeners();

    // TODO: remove this delay (Added for testing purposes)
    await Future.delayed(Duration(seconds: 3));

    await _reportRepository.saveResponseMessage(userId, reportId, description, authorityId, authorityName);

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

  void setSelectedReport(String reportId) {
    logMsg('report_view_model', msg: 'setSelectedReport $reportId');
    final Report report = _reportMap[reportId] ?? Report(id: emptyReportId);

    _currentReport = report;
    notifyListeners();
  }
}