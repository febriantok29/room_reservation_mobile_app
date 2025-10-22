import 'package:room_reservation_mobile_app/app/enums/user_role.dart';
import 'package:room_reservation_mobile_app/app/models/firestore/base_firestore_model.dart';

class Profile extends BaseFirestoreModel {
  static String collectionName = 's_users';

  String? employeeId;
  String? email;
  String? password;
  String? firstName;
  String? lastName;
  String? gender;
  String? phone;
  DateTime? dateOfBirth;
  DateTime? lastLoginAt;
  String? address;
  UserRole? role;

  Profile({
    super.id,
    this.employeeId,
    this.email,
    this.password,
    this.firstName,
    this.lastName,
    this.gender,
    this.phone,
    this.dateOfBirth,
    this.lastLoginAt,
    this.address,
    this.role,
    super.createdBy,
    super.updatedBy,
    super.deletedBy,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json, String documentId) {
    final profile = Profile(
      employeeId: json['employeeId'],
      email: json['email'],
      password: json['password'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      dateOfBirth: DateTime.tryParse('${json['dateOfBirth']}')?.toLocal(),
      gender: json['gender'],
      phone: json['phone'],
      lastLoginAt: DateTime.tryParse('${json['lastLoginAt']}')?.toLocal(),
      address: json['address'],
      role: UserRole.get('${json['role']}'),
    );

    profile.setCommonFields(json, documentId);

    return profile;
  }

  @override
  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'id': id,
      'employeeId': employeeId,
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'phone': phone,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'address': address,
      'role': role.toString(),
    };

    payload.addAll(super.toJson());

    return payload;
  }

  String get name => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  bool get isAdmin => role == UserRole.admin;
}
