class ReportStatus {

  String title;
  String description;
  List<Status> values;

  ReportStatus({
    required this.title,
    required this.description,
    required this.values,
  });

  factory ReportStatus.fromMap(Map<dynamic, dynamic> map) {

    final valuesList = map['values'] as List<dynamic>? ?? [];
    final Iterable<Status> statusEntries = valuesList.map((item) {
      return Status.fromMap(item as Map<dynamic, dynamic>);
    });

    return ReportStatus(
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      values: statusEntries.where((status) => status.visible).toList(),
    );
  }
}

class Status {

  int id;
  String name;
  String description;
  bool visible;

  Status({
    required this.id,
    required this.name,
    required this.description,
    required this.visible,
  });

  factory Status.fromMap(Map<dynamic, dynamic> map) {
    return Status(
      id: map['id'] as int? ?? 0,
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      visible: map['visible'] as bool? ?? true,
    );
  }
}