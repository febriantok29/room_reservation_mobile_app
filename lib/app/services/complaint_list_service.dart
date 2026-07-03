import 'package:rapa_track_mobile_app/app/models/complaint.dart';
import 'package:rapa_track_mobile_app/app/services/data_list_service.dart';

/// Concrete implementation untuk Complaint list dengan pagination
class ComplaintListService extends DataListService<Complaint> {
  @override
  String get routeKey => 'Complaint.list';

  @override
  Complaint fromJson(Map<String, dynamic> json) => Complaint.fromJson(json);
}
