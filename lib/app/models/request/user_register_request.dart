import 'package:room_reservation_mobile_app/app/enums/user_role.dart';
import 'package:room_reservation_mobile_app/app/models/firestore/base_firestore_model.dart';

class UserRegisterRequest extends BaseFirestoreModel {
  String? email;
  String? password;
  String? firstName;
  String? lastName;
  DateTime? dateOfBirth;
  UserRole role;

  UserRegisterRequest({
    this.email,
    this.password,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.role = UserRole.user,
  });

  @override
  void validate() {
    if (password == null || password!.isEmpty) {
      throw 'Silakan masukkan kata sandi.';
    }

    if (firstName == null || firstName!.isEmpty) {
      throw 'Silakan masukkan nama depan.';
    }

    if (dateOfBirth == null) {
      throw 'Silakan masukkan tanggal lahir.';
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final payload = super.toJson();

    payload.addAll({
      'email': email!.toLowerCase(),
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth?.toUtc().toIso8601String(),
      'role': role.name,
    });

    return payload;
  }
}
