import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:room_reservation_mobile_app/app/core/firestore/firestore_client.dart';
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
    final firestore = FirebaseFirestore.instance;
    final firestoreClient = firestore.collection(Profile.collectionName);

    final isEmail = credential.contains('@');
    final fieldName = isEmail ? 'email' : 'employeeId';

    credential = isEmail ? credential.toLowerCase() : credential.toUpperCase();

    final query = firestoreClient.where(fieldName, isEqualTo: credential);

    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) {
      throw 'Akun tidak ditemukan, silakan periksa kembali No. Induk Pegawai/email, dan password Anda.';
    }

    final doc = snapshot.docs.first;
    final userData = doc.data();

    final id = doc.id;

    final profile = Profile.fromJson(userData, id);

    final hashedPassword = _hashPassword(password);

    if (profile.password != hashedPassword) {
      throw 'Akun tidak ditemukan, silakan periksa kembali No. Induk Pegawai/email, dan password Anda.';
    }

    if (profile.deletedAt != null) {
      throw 'Akun Anda telah dinonaktifkan. Silakan hubungi admin untuk informasi lebih lanjut.';
    }

    profile.lastLoginAt = DateTime.now();
    profile.prepareForUpdate();

    final updatedData = profile.toJson();
    firestoreClient.doc(id).update(updatedData);

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

  @Deprecated('In `Firebase` implementation, logout is managed by Firebase SDK')
  Future logout() async {}

  @Deprecated(
    'In `Firebase` implementation, access token is managed by Firebase SDK',
  )
  bool isRefreshTokenExpired() {
    return false;
  }

  @Deprecated(
    'In `Firebase` implementation, access token is managed by Firebase SDK',
  )
  Future<bool> refreshTokenIfNeeded() async {
    return false;
  }

  @Deprecated(
    'In `Firebase` implementation, access token is managed by Firebase SDK',
  )
  Future<bool> ensureValidToken() async {
    return true;
  }

  @Deprecated(
    'In `Firebase` implementation, access token is managed by Firebase SDK',
  )
  String? getAccessToken() {
    final random = Random();

    final hasToken = random.nextBool();
    if (!hasToken) {
      return null;
    }

    return 'dummy_access_token';
  }
}
