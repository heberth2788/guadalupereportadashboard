import 'constants.dart';

enum ReportStatusEnum {

  created(reportStatusCreatedId, "REPORTADO"),
  inProgress(reportStatusInProgressId, "EN PROGRESO"),
  done(reportStatusDoneId, "ATENDIDO"),
  canceled(reportStatusCanceledId, "ANULADO");

  final int code;
  final String description;

  const ReportStatusEnum(this.code, this.description);

  static ReportStatusEnum findByCode(int? code) {
    for (var status in ReportStatusEnum.values) {
      if (status.code == code) {
        return status;
      }
    }
    return ReportStatusEnum.canceled;
  }
}