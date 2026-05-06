import 'dart:async';
import 'dart:collection';
import 'package:guadalupereportadashboard/util/constants.dart';
import 'package:guadalupereportadashboard/util/util.dart';
import 'package:flutter/foundation.dart';
import 'package:guadalupereportadashboard/data/report.dart';
import 'package:guadalupereportadashboard/data/report_repository.dart';
import 'package:guadalupereportadashboard/util/report_status_enum.dart';
import 'package:guadalupereportadashboard/data/report_status.dart';
import 'package:guadalupereportadashboard/data/report_type.dart';
import 'package:guadalupereportadashboard/data/response.dart';

/// Provider implementation : ChangeNotifier(Observable)
class ReportViewModel extends ChangeNotifier {

  final ReportRepository _reportRepository;

  Map<String, Report> _reportMap = <String, Report> { };
  UnmodifiableMapView<String, Report> get reportMap => UnmodifiableMapView(_reportMap);

  Report _currentReport = Report(id: empty);
  Report get currentReport => _currentReport;

  List<String> _currentReportPhotos = [];
  UnmodifiableListView<String> get currentReportPhotos => UnmodifiableListView(_currentReportPhotos);
  
  Response _currentResponse = Response(userId: empty, reportId: empty);
  Response get currentResponse => _currentResponse;

  List<String> _currentResponsePhotos = [];
  UnmodifiableListView<String> get currentResponsePhotos => UnmodifiableListView(_currentResponsePhotos);

  //region States for date filters: DateFrom and DateTo
  DateTime _dateFrom = getDateTimeAtStartOfDay(DateTime.now().subtract(const Duration(days: rangeDays)));
  DateTime get dateFrom => _dateFrom;

  DateTime _dateTo = getDateTimeAtEndOfDay(DateTime.now());
  DateTime get dateTo => _dateTo;
  //endregion

  /// To manage Report's Status dropdown button list
  ReportStatus _reportStatus = ReportStatus(title: empty, description: empty, values: []);
  ReportStatus get reportStatus => _reportStatus;

  /// Selected Report's Status from dropdown button list
  Status _selectedStatus = Status(id: 0, name: empty, description: empty, visible: true);
  Status get selectedStatus => _selectedStatus;

  /// To manage Report's Type dropdown button list
  ReportType _reportType = ReportType(title: empty, description: empty, values: []);
  ReportType get reportType => _reportType;

  /// Selected Report's Type from dropdown button list
  Type _selectedType = Type(id: 0, name: empty, description: empty, visible: true);
  Type get selectedType => _selectedType;

  /// To show shimmer for report and response cards
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// To show loading when saving response data
  bool _isSavingResponseData = false;
  bool get isSavingResponseData => _isSavingResponseData;

  /// To allow uploading more photos or not
  bool get isMaxPhotosReached => _currentResponsePhotos.length < maxResponsePhotosAllowed;

  /// To show or hide report and response cards
  bool _showReportCards = false;
  bool get showReportCards => _showReportCards;

  //region Stream subscriptions list
  final List<StreamSubscription> _subscriptions = [];
  StreamSubscription? _reportsSubscription;
  //endregion

  ReportViewModel({
    ReportRepository? repository,
  }): _reportRepository = repository ?? ReportRepository() {
    logMsg('report_view_model', msg: 'ReportViewModel');

    _subscriptions.add(
      _reportRepository.fetchReportStatusStream().listen((ReportStatus status) {
        logMsg('report_view_model', msg: 'fetchReportStatusStream');
        _reportStatus = status;
        _selectedStatus = status.values.first;

        notifyListeners();
      })
    );

    _subscriptions.add(
      _reportRepository.fetchReportTypeStream().listen((ReportType type) {
        logMsg('report_view_model', msg: 'fetchReportTypeStream');
        _reportType = type;
        _selectedType = type.values.first;

        notifyListeners();
      })
    );

    _updateReportStream();
  }

  void _updateReportStream() {
    logMsg('report_view_model', msg: '_updateReportStream');
    _reportsSubscription?.cancel();

    _reportsSubscription = _reportRepository.fetchReports(
      _dateFrom,
      _dateTo,
    ).listen((Map<String, Report> reports) {
      logMsg('report_view_model', msg: 'fetchReports listen id: ${ _selectedStatus.id }');

      // If the status is uninitialized(0) or all(1), show all reports
      if (_selectedStatus.id == 0 || _selectedStatus.id == 1) {
        _reportMap = reports;
      } else { // Otherwise, filter the reports by status
        _reportMap = Map.fromEntries(
            reports.entries.where((MapEntry<String, Report> entry) {
              final Report report = entry.value;
              return report.status == _selectedStatus.id; // TODO: Add report type filter
            })
        );
      }
      _currentReport = _reportMap[_currentReport.id] ?? Report(id: empty);

      notifyListeners();
    });
  }

  void onChangeReportStatusFilter(String? newReportStatus) {
    logMsg('report_view_model', msg: 'onChangeReportStatus');
    _selectedStatus = _reportStatus.values.where((Status status) => status.name == newReportStatus).first;
    _showReportCards = false;
    _updateReportStream();
  }

  void onChangeReportTypeFilter(String? newReportType) {
    logMsg('report_view_model', msg: 'onChangeReportType');
    _selectedType = _reportType.values.where((Type type) => type.name == newReportType).first;
    _showReportCards = false;
    _updateReportStream();
  }

  void onChangeDateFrom(DateTime newDateFrom) {
    logMsg('report_view_model', msg: 'onChangeDateFrom');
    _dateFrom = newDateFrom;
    _showReportCards = false;
    _updateReportStream();
  }

  void onChangeDateTo(DateTime newDateTo) {
    logMsg('report_view_model', msg: 'onChangeDateTo');
    _dateTo = newDateTo;
    _showReportCards = false;
    _updateReportStream();
  }

  Future<void> fetchReportData(String reportId) async {
    logMsg('report_view_model', msg: 'fetchReportData');
    _isLoading = true;
    notifyListeners();

    // TODO: remove this delay (Added for testing purposes)
    await Future.delayed(Duration(seconds: 1));

    // Set the current report
    _currentReport = _reportMap[reportId] ?? Report(id: empty);

    await Future.wait([
      _fetchResponse(), // Get the response of the selected report
      _getPhotos(), // Get the photos of the selected report
    ]);

    _showReportCards = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchResponse() async {
    logMsg('report_view_model', msg: '_fetchResponse');
    _currentResponse = await _reportRepository.fetchResponse(_currentReport.userId, _currentReport.id);
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

  Future<void> uploadResponseImage(
      Uint8List imageBytes,
      String fileExtension,
  ) async {
    logMsg('report_view_model', msg: 'uploadResponsePhoto');
    _isSavingResponseData = true;
    notifyListeners();

    // TODO: remove this delay (Added for testing purposes)
    await Future.delayed(Duration(seconds: 1));

    final String imageName = '${ DateTime.now().millisecondsSinceEpoch }.$fileExtension';
    final String publicUrlImage = await _reportRepository.uploadResponseImage(
      currentReport.userId,
      currentReport.id,
      imageBytes,
      imageName,
    );

    if (publicUrlImage.isNotEmpty) {
      logMsg('report_view_model', msg: 'uploadResponsePhoto > complete');
      _currentResponsePhotos.add(publicUrlImage);
    } else {
      logMsg('report_view_model', msg: 'uploadResponsePhoto > failed');
    }

    _isSavingResponseData = false;
    notifyListeners();
  }

  Future<void> deleteResponseImage(String publicImageUrl) async {
    logMsg('report_view_model', msg: 'deleteResponseImage');
    _isSavingResponseData = true;
    notifyListeners();

    // TODO: remove this delay (Added for testing purposes)
    await Future.delayed(Duration(seconds: 1));

    final decodedImageUrl = Uri.decodeFull(publicImageUrl);
    String imageName = decodedImageUrl.split('/').last.split('?').first;

    await _reportRepository.deleteResponseImage(
        currentReport.userId,
        currentReport.id,
        imageName,
    );
    _currentResponsePhotos.remove(publicImageUrl);

    _isSavingResponseData = false;
    notifyListeners();
  }

  Future<void> upsertAuthorityResponseMessage(String message) async {
    logMsg('report_view_model', msg: 'saveAuthorityResponseMessage');
    _currentResponse.message = message;
    _isSavingResponseData = true;
    notifyListeners();

    // TODO: remove this delay (Added for testing purposes)
    await Future.delayed(Duration(seconds: 1));

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
      ReportStatusEnum status,
  ) async {
    logMsg('report_view_model', msg: 'updateReportStatus $status');
    _isSavingResponseData = true;
    notifyListeners();

    // TODO: remove this delay (Added for testing purposes)
    await Future.delayed(Duration(seconds: 1));

    await _reportRepository.updateReportStatus(userId, reportId, date, status);

    // If the selected status filter is neither uninitialized(0) not all(1), hide report cards
    if (_selectedStatus.id != 0 && _selectedStatus.id != 1) {
      _showReportCards = false;
    }
    _isSavingResponseData = false;
    notifyListeners();
  }

  @override
  void dispose() {
    logMsg('report_view_model', msg: 'dispose');

    // Cancel subscriptions to prevent memory leaks
    _reportsSubscription?.cancel();
    for (var subscription in _subscriptions) { subscription.cancel(); }

    super.dispose();
  }
}