import 'package:room_reservation_mobile_app/app/enums/user_role.dart';
import 'package:room_reservation_mobile_app/app/models/firestore/base_firestore_model.dart';

class UserRegisterRequest extends BaseFirestoreModel {
  String? email;
  String? password;
  String? firstName;
  String? lastName;
  bool? gender;
  DateTime? dateOfBirth;
  String? phoneNumber;
  String? address;
  UserRole role;

  UserRegisterRequest({
    this.email,
    this.password,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
    this.address,
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

    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      // Make validation for phone number format
      // Make sure it only contains numbers, +, -, and spaces
      // Length must be between 7 and 15 characters
      // If start with +, the next character must be a number
      // If not start with +, the first character must be 0
      // Examples of valid phone numbers:
      // +6281234567890
      // 0812-3456-7890
      // 081234567890
      // +62 812 3456 7890
      // Examples of invalid phone numbers:
      // +A81234567890
      // 81234567890
      final phoneRegex = RegExp(
        r'^(?:\+?[0-9][0-9\s-]{6,14}|0[0-9\s-]{6,14})$',
      );

      if (!phoneRegex.hasMatch(phoneNumber!)) {
        throw 'Format nomor telepon tidak valid.';
      }

      // Reformat phone number to remove spaces and dashes.
      // So after store to database, the phone number will be like +6281234567890 or 081234567890
      phoneNumber = phoneNumber!.replaceAll(RegExp(r'[\s-]'), '');
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final payload = super.toJson();

    String? gender;
    if (this.gender != null) {
      gender = this.gender! ? 'M' : 'F';
    }

    payload.addAll({
      'email': email!.toLowerCase(),
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth?.toUtc().toIso8601String(),
      'role': role.name,
      'gender': gender,
      'address': address,
    });

    return payload;
  }
}
