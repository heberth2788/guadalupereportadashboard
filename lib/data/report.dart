import '../util/util.dart';
import '../util/report_status_enum.dart';

class Report {

  final String id;
  double acc;
  double alt;
  int creationTimestamp;
  String description;
  int doneTimestamp;
  int inProgressTimestamp;
  int canceledTimestamp;
  double lat;
  double lon;
  int status;
  String title;
  String userId;
  String userName;
  bool visible;

  Report({
    required this.id,
    this.acc = 0.0,
    this.alt = 0.0,
    this.creationTimestamp = 0,
    this.description = '',
    this.doneTimestamp = 0,
    this.inProgressTimestamp = 0,
    this.canceledTimestamp = 0,
    this.lat = 0.0,
    this.lon = 0.0,
    this.status = 0,
    this.title = '',
    this.userId = '',
    this.userName = '',
    this.visible = true,
  });

  factory Report.fromMap(String id, Map<dynamic, dynamic> map) {
    return Report(
      id: id,
      acc: (map['acc'] as num?)?.toDouble() ?? 0.0,
      alt: (map['alt'] as num?)?.toDouble() ?? 0.0,
      creationTimestamp: map['creationTimestamp'] as int? ?? 0,
      description: map['description']?.toString() ?? '',
      doneTimestamp: map['doneTimestamp'] as int? ?? 0,
      inProgressTimestamp: map['inProgressTimestamp'] as int? ?? 0,
      canceledTimestamp: map['canceledTimestamp'] as int? ?? 0,
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (map['lon'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as int? ?? 0,
      title: map['title']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      userName: map['userName']?.toString() ?? '',
      visible: map['visible'] as bool? ?? true,
    );
  }

  String getStatusDateTime() {
    final reportStatus = ReportStatusEnum.findByCode(status);

    if (reportStatus == ReportStatusEnum.created) {
      return getDatetimeFromTimestamp(creationTimestamp);
    } else if (reportStatus == ReportStatusEnum.inProgress) {
      return getDatetimeFromTimestamp(inProgressTimestamp);
    } else if (reportStatus == ReportStatusEnum.done) {
      return getDatetimeFromTimestamp(doneTimestamp);
    } else if (reportStatus == ReportStatusEnum.canceled) {
      return getDatetimeFromTimestamp(canceledTimestamp);
    }

    return '';
  }
}