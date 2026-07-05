import 'package:rapa_track_mobile_app/app/enums/user_role.dart';
import 'package:rapa_track_mobile_app/app/models/base_model.dart';

class Profile extends BaseModel {
  String? employeeId;
  String? email;
  String? firstName;
  String? lastName;
  DateTime? dateOfBirth;
  bool isActive;
  UserRole? role;

  Profile({
    super.id,
    this.employeeId,
    this.email,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.isActive = true,
    this.role,
    super.createdBy,
    super.updatedBy,
    super.deletedBy,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    final fullName = '${json['name'] ?? ''}'.trim();
    final firstNameRaw = json['first_name']?.toString();
    final lastNameRaw = json['last_name']?.toString();

    String? firstName;
    String? lastName;

    if (firstNameRaw != null && firstNameRaw.isNotEmpty) {
      firstName = firstNameRaw;
      lastName = lastNameRaw;
    } else if (fullName.isNotEmpty) {
      final chunks = fullName
          .split(RegExp(r'\s+'))
          .where((e) => e.isNotEmpty)
          .toList();
      firstName = chunks.isNotEmpty ? chunks.first : null;
      lastName = chunks.length > 1 ? chunks.sublist(1).join(' ') : null;
    } else {
      firstName = null;
      lastName = null;
    }

    final isAdmin = json['is_admin'] == true;

    final profile = Profile(
      employeeId: json['employee_id']?.toString(),
      email: json['email']?.toString(),
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: DateTime.tryParse(
        '${json['date_of_birth'] ?? ''}',
      )?.toLocal(),
      isActive: json['is_active'] != false,
      role: isAdmin ? UserRole.admin : UserRole.user,
    );

    profile.setCommonFieldsFromJson(json);

    return profile;
  }

  String get name => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  String get initials {
    final first = (firstName?.isNotEmpty == true) ? firstName![0].toUpperCase() : '';
    final last = (lastName?.isNotEmpty == true) ? lastName![0].toUpperCase() : '';
    if (first.isEmpty) return 'U';
    return last.isNotEmpty ? '$first$last' : first;
  }

  bool get isAdmin => role == UserRole.admin;
}
