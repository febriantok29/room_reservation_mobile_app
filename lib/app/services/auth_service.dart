import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:room_reservation_mobile_app/app/core/firestore/firestore_client.dart';
import 'package:room_reservation_mobile_app/app/models/firestore/base_firestore_model.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/request/user_register_request.dart';

class AuthService {
  AuthService._();

  static AuthService? _instance;

  factory AuthService.getInstance() {
    _instance ??= AuthService._();
    return _instance!;
  }

  Future<Profile> login({
    required String credential,
    required String password,
  }) async {
    final client = await FirestoreClient.create(Profile.collectionName);

    final isEmail = credential.contains('@');
    final fieldName = isEmail ? 'email' : 'employeeId';

    credential = isEmail ? credential.toLowerCase() : credential.toUpperCase();

    final hashedPassword = _hashPassword(password);

    final snapshot = await client.advancedQuery(
      conditions: [
        QueryCondition(field: fieldName, isEqualTo: credential),
        QueryCondition(field: 'password', isEqualTo: hashedPassword),
        QueryCondition(
          field: BaseFirestoreModel.deletedAtField,
          isEqualTo: null,
        ),
      ],
    );

    if (snapshot.docs.isEmpty) {
      throw 'Akun tidak ditemukan, silakan periksa kembali No. Induk Pegawai/email, dan password Anda.';
    }

    final document = snapshot.docs.first;

    if (!document.exists) {
      throw 'Akun tidak ditemukan, silakan periksa kembali No. Induk Pegawai/email, dan password Anda.';
    }

    final user = document.data();
    final id = document.id;

    final profile = Profile.fromJson(user, id);

    profile.lastLoginAt = DateTime.now();
    profile.prepareForUpdate();

    final updatedData = profile.toJson();
    client.update(id, updatedData);

    return profile;
  }

  Future<void> register(UserRegisterRequest request) async {
    final firestoreClient = await FirestoreClient.create(
      Profile.collectionName,
    );

    request.validate();

    request.prepareForCreate();
    final newUserData = request.toJson();

    final hashedPassword = _hashPassword(request.password!);
    final employeeId = await _generateEmployeeId(request.dateOfBirth!);

    newUserData['employeeId'] = employeeId;
    newUserData['password'] = hashedPassword;

    await firestoreClient.set(employeeId, newUserData);
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<String> _generateEmployeeId(DateTime dateOfBirth) async {
    final firestore = FirebaseFirestore.instance;
    final client = firestore.collection(Profile.collectionName);

    final now = DateTime.now();
    final yearPart = now.year.toString().substring(2, 4);
    final dobYearPart = dateOfBirth.year.toString().substring(2, 4);

    // Query only for the current year's employee IDs to get the sequence
    final yearPrefix = yearPart;
    final query = client
        .where('employeeId', isGreaterThanOrEqualTo: yearPrefix)
        .where('employeeId', isLessThan: '$yearPrefix\uffff');

    final snapshot = await query.get();

    final sequenceNumber = snapshot.docs.length + 1;

    final sequencePart = sequenceNumber.toString().padLeft(3, '0');
    final employeeId = '$yearPart$dobYearPart${sequencePart}HPI';

    return employeeId;
  }
}
