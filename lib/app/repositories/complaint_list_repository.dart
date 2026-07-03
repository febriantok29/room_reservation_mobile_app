import 'package:rapa_track_mobile_app/app/models/complaint.dart';
import 'package:rapa_track_mobile_app/app/repositories/data_list_repository.dart';
import 'package:rapa_track_mobile_app/app/services/complaint_list_service.dart';

/// Repository untuk Complaint list dengan pagination
class ComplaintListRepository extends DataListRepository<Complaint> {
  ComplaintListRepository() : super(ComplaintListService(), perPage: 20);
}
