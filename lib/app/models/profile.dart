import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:room_reservation_mobile_app/app/enums/user_role.dart';
import 'package:room_reservation_mobile_app/app/models/firestore/base_firestore_model.dart';
import 'package:room_reservation_mobile_app/app/models/request/user_register_request.dart';
import 'package:room_reservation_mobile_app/app/utils/date_formatter.dart';

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

  @override
  DocumentReference? get reference =>
      FirebaseFirestore.instance.collection(collectionName).doc(id);

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
      dateOfBirth: DateFormatter.getDateTime('${json['dateOfBirth']}'),
      gender: json['gender'],
      phone: json['phone'],
      lastLoginAt: DateFormatter.getDateTime('${json['lastLoginAt']}'),
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

  static UserRegisterRequest random() {
    final random = Random();

    final firstNames = ['John', 'Jane', 'Alex', 'Emily', 'Michael', 'Sarah'];
    final lastNames = ['Doe', 'Smith', 'Johnson', 'Brown', 'Davis', 'Miller'];

    final firstName = firstNames[random.nextInt(firstNames.length)];
    final lastName = lastNames[random.nextInt(lastNames.length)];
    final email =
        '${firstName.toLowerCase()}.${lastName.toLowerCase()}@example.com';
    final dateOfBirth = DateTime.now().subtract(
      Duration(days: (18 + random.nextInt(33)) * 365),
    );
    final gender = random.nextBool();
    final password = 'aaaaaa';

    final address = '${random.nextInt(999)} Main St, Cityville';

    return UserRegisterRequest(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      role: UserRole.user,
      gender: gender,
      address: address,
    );
  }
}
