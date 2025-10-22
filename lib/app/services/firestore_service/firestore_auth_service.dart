import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:room_reservation_mobile_app/app/core/firestore/firestore_client.dart';
import 'package:room_reservation_mobile_app/app/enums/user_role.dart';
import 'package:room_reservation_mobile_app/app/exceptions/exceptions.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/request/user_register_request.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk menangani autentikasi pengguna dengan Firestore
class FirestoreAuthService {
  /// Key untuk menyimpan data di SharedPreferences
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  /// Collection path untuk user di Firestore
  static const String _usersCollection = 'users';

  /// Singleton instance
  static FirestoreAuthService? _instance;

  /// Firestore client
  late final FirestoreClient _firestoreClient;

  /// SharedPreferences instance
  late SharedPreferences _prefs;

  /// Private constructor
  FirestoreAuthService._();

  /// Factory method untuk mendapatkan instance FirestoreAuthService
  static Future<FirestoreAuthService> getInstance() async {
    if (_instance == null) {
      _instance = FirestoreAuthService._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  /// Inisialisasi service
  Future<void> _initialize() async {
    try {
      // Initialize Firebase if not already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      _prefs = await SharedPreferences.getInstance();
      _firestoreClient = await FirestoreClient.create(_usersCollection);

      // Check if user is logged in from local storage
    } catch (e) {
      debugPrint('Error initializing FirestoreAuthService: $e');
      rethrow;
    }
  }

  /// Cek apakah user sudah login
  bool isLoggedIn() {
    return _prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Register a new user using UserRegisterRequest
  Future<Profile> register({required UserRegisterRequest request}) async {
    try {
      // Validasi request
      request.validate();

      // Check if email already exists
      final emailQuery = _firestoreClient.getCollectionRef().where(
        'email',
        isEqualTo: request.email,
      );

      final emailSnapshot = await emailQuery.get();

      if (emailSnapshot.docs.isNotEmpty) {
        throw ValidationException(
          'Email sudah digunakan, silakan gunakan email lain',
        );
      }

      // Hash password before saving
      final hashedPassword = _hashPassword(request.password!);

      // Create user object dengan password yang sudah di-hash
      final userData = request.toJson();
      userData['password'] = hashedPassword;

      final employeeId = await _generateEmployeeId();
      userData['employeeId'] = employeeId;

      // Save to Firestore
      final docRef = await _firestoreClient.add(userData);
      final userId = docRef.id;

      // Buat Profile object untuk dikembalikan
      final profile = Profile.fromJson(userData, userId);

      return profile;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _generateEmployeeId() async {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final prefix = '$year$month';

    // Query untuk mendapatkan nomor urut tertinggi dalam bulan ini
    final query = _firestoreClient
        .getCollectionRef()
        .where('employeeId', isGreaterThanOrEqualTo: prefix)
        .where('employeeId', isLessThan: '${prefix}999')
        .orderBy('employeeId', descending: true)
        .limit(1);

    final snapshot = await query.get();
    int nextNumber = 1;

    if (snapshot.docs.isNotEmpty) {
      final lastDoc = snapshot.docs.first;
      final lastEmployeeId = lastDoc['employeeId'] as String;
      final lastNumberStr = lastEmployeeId.substring(
        6,
        9,
      ); // Ambil bagian nomor urut
      final lastNumber = int.tryParse(lastNumberStr) ?? 0;
      nextNumber = lastNumber + 1;
    }

    final numberStr = nextNumber.toString().padLeft(3, '0');
    final numberStrHPI = 'HPI';
    final employeeId = '$prefix$numberStr$numberStrHPI';

    return employeeId;
  }

  /// Login user dengan credential dan password
  Future<Profile> login({
    required String credential,
    required String password,
  }) async {
    // Determine if credential is email or username
    final isEmail = credential.contains('@');
    final fieldName = isEmail ? 'email' : 'username';

    // Query user by credential
    final query = _firestoreClient.getCollectionRef().where(
      fieldName,
      isEqualTo: credential,
    );

    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) {
      throw ValidationException('User not found');
    }

    // Get the user document
    final doc = snapshot.docs.first;
    final userData = doc.data() as Map<String, dynamic>;
    final userId = doc.id;

    // Check password
    final hashedPassword = _hashPassword(password);

    if (userData['password'] != hashedPassword) {
      throw ValidationException('Invalid password');
    }

    // Check if user is active
    if (userData['isActive'] != true) {
      throw ValidationException('User account is inactive');
    }

    // Update last login
    await _firestoreClient.document(userId).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });

    // Create Profile object
    final profile = Profile(
      id: userId,
      email: userData['email'] as String,
      employeeId: userData['username'] as String,
      firstName: userData['firstName'] as String,
      lastName: userData['lastName'] as String? ?? '',
      role: UserRole.get('${userData['role']}'),
    );

    // Save user data to local storage
    await saveUserData(profile);

    return profile;
  }

  /// Hash password dengan SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Menyimpan data user ke local storage
  Future<void> saveUserData(Profile profile) async {
    try {
      await Future.wait([
        _prefs.setString(_userIdKey, profile.id ?? ''),
        _prefs.setString(_userDataKey, jsonEncode(profile.toJson())),
        _prefs.setBool(_isLoggedInKey, true),
      ]);
    } catch (e) {
      throw StateError('Failed to save user data: ${e.toString()}');
    }
  }

  /// Mendapatkan data user dari cache
  Profile? getUserData() {
    try {
      final userDataString = _prefs.getString(_userDataKey);
      if (userDataString == null || userDataString.isEmpty) return null;

      final userData = jsonDecode(userDataString) as Map<String, dynamic>;
      return Profile.fromJson(userData, '');
    } catch (e) {
      debugPrint('Error getting user data from cache: $e');
      return null;
    }
  }

  /// Mendapatkan user ID dari local storage
  String? getUserId() {
    final userId = _prefs.getString(_userIdKey);
    if (userId == null || userId.isEmpty) return null;
    return userId;
  }

  /// Mendapatkan data user yang sedang login
  Future<Profile?> getCurrentUser({bool forceRefresh = false}) async {
    try {
      if (!isLoggedIn()) return null;

      // Gunakan cache jika ada dan tidak diminta refresh
      if (!forceRefresh) {
        final cachedUser = getUserData();
        if (cachedUser != null) return cachedUser;
      }

      // Fetch dari Firestore
      final userId = getUserId();
      if (userId == null) return null;

      final docSnapshot = await _firestoreClient.get(userId);
      if (!docSnapshot.exists) return null;

      final userData = docSnapshot.data() as Map<String, dynamic>?;
      if (userData == null) return null;

      // Create Profile object
      final profile = Profile(
        id: docSnapshot.id,
        email: userData['email'] as String,
        employeeId: userData['username'] as String,
        firstName: userData['firstName'] as String,
        lastName: userData['lastName'] as String? ?? '',
        role: UserRole.get('${userData['role']}'),
      );

      // Update cache
      await _prefs.setString(_userDataKey, jsonEncode(profile.toJson()));

      return profile;
    } catch (e) {
      // Return cached data jika gagal fetch
      debugPrint('Failed to get current user: ${e.toString()}');
      return getUserData();
    }
  }

  /// Logout user dan hapus data dari local storage
  Future<void> logout() async {
    // Clear local storage
    await Future.wait([
      _prefs.remove(_userIdKey),
      _prefs.remove(_userDataKey),
      _prefs.setBool(_isLoggedInKey, false),
    ]);
  }

  /// Update profile user
  Future<bool> updateProfile(Profile profile) async {
    if (!isLoggedIn()) return false;

    final userId = getUserId();
    if (userId == null) return false;

    try {
      // Check if email is changed and if it exists
      final currentProfile = await getCurrentUser();
      if (currentProfile != null && currentProfile.email != profile.email) {
        final emailQuery = _firestoreClient.getCollectionRef().where(
          'email',
          isEqualTo: profile.email,
        );

        final emailSnapshot = await emailQuery.get();
        for (final doc in emailSnapshot.docs) {
          if (doc.id != userId) {
            throw ValidationException('Email already exists');
          }
        }
      }

      // Check if username is changed and if it exists
      if (currentProfile != null &&
          currentProfile.employeeId != profile.employeeId) {
        final usernameQuery = _firestoreClient.getCollectionRef().where(
          'username',
          isEqualTo: profile.employeeId,
        );

        final usernameSnapshot = await usernameQuery.get();
        for (final doc in usernameSnapshot.docs) {
          if (doc.id != userId) {
            throw ValidationException('Username already exists');
          }
        }
      }

      // Update profile in Firestore
      await _firestoreClient.update(userId, {
        'email': profile.email,
        'username': profile.employeeId,
        'firstName': profile.firstName,
        'lastName': profile.lastName,
        'role': profile.role,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local storage
      await saveUserData(profile);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (!isLoggedIn()) return false;

    final userId = getUserId();
    if (userId == null) return false;

    try {
      // Get current user data
      final docSnapshot = await _firestoreClient.get(userId);
      if (!docSnapshot.exists) return false;

      final userData = docSnapshot.data() as Map<String, dynamic>?;
      if (userData == null) return false;

      // Verify current password
      final hashedCurrentPassword = _hashPassword(currentPassword);
      if (userData['password'] != hashedCurrentPassword) {
        throw ValidationException('Current password is incorrect');
      }

      // Update password
      final hashedNewPassword = _hashPassword(newPassword);
      await _firestoreClient.update(userId, {
        'password': hashedNewPassword,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}
