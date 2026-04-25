class Response {
  final String userId;
  final String reportId;
  String message;
  String authorityId;
  String authorityName;
  int creationTimestamp;
  bool visible;

  Response({
    required this.userId,
    required this.reportId,
    this.message = '',
    this.authorityId = '',
    this.authorityName = '',
    this.creationTimestamp = 0,
    this.visible = true,
  });

  factory Response.fromMap(String userId, String reportId, Map<dynamic, dynamic> map) {
    return Response(
      userId: userId,
      reportId: reportId,
      message: map['message']?.toString() ?? '',
      authorityId: map['authorityId']?.toString() ?? '',
      authorityName: map['authorityName']?.toString() ?? '',
      creationTimestamp: map['creationTimestamp'] as int? ?? 0,
      visible: map['visible'] as bool? ?? true,
    );
  }
}