import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:room_reservation_mobile_app/app/enum/user_role.dart';

class UserRegisterRequest {
  String? username;
  String? email;
  String? password;
  String? firstName;
  UserRole role;

  UserRegisterRequest({
    this.username,
    this.email,
    this.password,
    this.firstName,
    this.role = UserRole.user,
  });

  void validate() {
    if (email == null || email!.isEmpty) {
      throw 'Silakan masukkan email.';
    }

    if (password == null || password!.isEmpty) {
      throw 'Silakan masukkan kata sandi.';
    }

    if (firstName == null || firstName!.isEmpty) {
      throw 'Silakan masukkan nama depan.';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'firstName': firstName,
      'role': role.name,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
