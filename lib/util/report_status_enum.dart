enum ReportStatusEnum {

  created(0, "REPORTADO"),
  inProgress(1, "EN PROGRESO"),
  done(2, "ATENDIDO"),
  canceled(666, "ANULADO");

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