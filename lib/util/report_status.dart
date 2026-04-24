enum ReportStatus {
  created(0, "REPORTADO"),
  inProgress(1, "EN PROGRESO"),
  done(2, "ATENDIDO"),
  canceled(666, "ANULADO");

  final int code;
  final String description;

  const ReportStatus(this.code, this.description);

  static ReportStatus findByCode(int? code) {
    for (var status in ReportStatus.values) {
      if (status.code == code) {
        return status;
      }
    }
    return ReportStatus.canceled;
  }
}