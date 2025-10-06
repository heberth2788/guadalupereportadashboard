
class Report {
  
  String id;

  double? acc;
  double? alt;
  int? creationTimestamp;
  String? description;
  int? doneTimestamp;
  int? inProgressTimestamp;
  double? lat;
  double? lon;
  int? status;
  String? title;
  String? userId;
  String? userName;
  bool? visible;

  Report(this.id); 

  @override
  String toString() {
    final str = '$id | $acc | $alt | $creationTimestamp | $description | $doneTimestamp | $inProgressTimestamp | $lat | $lon | $status | $title | $userId | $userName | $visible';
    return str;
  }
}