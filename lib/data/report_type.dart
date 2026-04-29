class ReportType {

  String title;
  String description;
  List<Type> values;

  ReportType({
    required this.title,
    required this.description,
    required this.values,
  });

  factory ReportType.fromMap(Map<dynamic, dynamic> map) {

    final valuesList = map['values'] as List<dynamic>? ?? [];
    final Iterable<Type> typeEntries = valuesList.map((item) {
      return Type.fromMap(item as Map<dynamic, dynamic>);
    });

    return ReportType(
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      values: typeEntries.where((type) => type.visible).toList(),
    );
  }
}

class Type {

  int id;
  String name;
  String description;
  bool visible;

  Type({
    required this.id,
    required this.name,
    required this.description,
    required this.visible,
  });

  factory Type.fromMap(Map<dynamic, dynamic> map) {
    return Type(
      id: map['id'] as int? ?? 0,
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      visible: map['visible'] as bool? ?? true,
    );
  }
}