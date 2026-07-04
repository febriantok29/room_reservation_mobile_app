import 'package:rapa_track_mobile_app/app/models/complaint.dart';
import 'package:rapa_track_mobile_app/app/repositories/data_list_repository.dart';
import 'package:rapa_track_mobile_app/app/services/complaint_service.dart';

class ComplaintListRepository extends DataListRepository<Complaint> {
  ComplaintListRepository() : super(ComplaintService(), perPage: 20);
}
