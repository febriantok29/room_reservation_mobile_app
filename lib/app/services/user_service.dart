import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:room_reservation_mobile_app/app/core/firestore/firestore_client.dart';
import 'package:room_reservation_mobile_app/app/enums/user_role.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/services/auth_service.dart';

class UserService {
  static UserService? _instance;

  UserService._internal();

  factory UserService() {
    _instance ??= UserService._internal();
    return _instance!;
  }

  static final _cachedUsers = <Profile>[];

  static Future<List<Profile>> getAllUsers() async {
    print('_cachedUsers gan: ${_cachedUsers.length}');

    if (_cachedUsers.isNotEmpty && _cachedUsers.length > 1) {
      return _cachedUsers.where((user) => user.role != UserRole.admin).toList();
    }

    final client = await FirestoreClient.create(Profile.collectionName);

    final snapshot = await client.getAll();
    //     .advancedQuery(
    //   conditions: <QueryCondition>[
    //     QueryCondition(field: 'role', isNotEqualTo: 'admin'),
    //     QueryCondition(field: 'deletedAt', isEqualTo: null),
    //   ],
    // );
    //     .query(field: 'role', isNotEqualTo: 'admin');

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final profile = Profile.fromJson(data, doc.id);
      _cachedUsers.add(profile);
    }

    return _cachedUsers;
  }

  static Future<Profile> getProfileByDoc(DocumentReference document) async {
    // Check cache first
    final cachedUser = _cachedUsers.where((user) => user.id == document.id);

    if (cachedUser.isNotEmpty) {
      return cachedUser.first;
    }

    // Query Firestore
    final firestoreClient = await FirestoreClient.create(
      Profile.collectionName,
    );

    final doc = await firestoreClient.get(document.id);

    if (!doc.exists) {
      throw 'Akun tidak ditemukan.';
    }

    final data = doc.data()!;

    final profile = Profile.fromJson(data, doc.id);
    _cachedUsers.add(profile);

    return profile;
  }

  static Future<Profile> getProfileByEmployeeId(String employeeId) async {
    // Check cache first
    final cachedUser = _cachedUsers.where(
      (user) => user.employeeId == employeeId,
    );

    if (cachedUser.isNotEmpty) {
      return cachedUser.first;
    }

    // Query Firestore
    final firestoreClient = await FirestoreClient.create(
      Profile.collectionName,
    );

    final snapshot = await firestoreClient.query(
      field: 'employeeId',
      isEqualTo: employeeId,
    );

    if (snapshot.docs.isEmpty) {
      throw 'Akun tidak ditemukan.';
    }

    // Create and cache profile
    final doc = snapshot.docs.first;

    final data = doc.data();

    final profile = Profile.fromJson(data, doc.id);
    _cachedUsers.add(profile);

    return profile;
  }

  static Future<List<Profile>> getUserByEmployeeIds(
    Set<String> employeeIds,
  ) async {
    // Filter cached users that match requested IDs
    final cachedUsers = _cachedUsers
        .where((user) => employeeIds.contains(user.employeeId))
        .toList();

    // Return if we found all requested users in cache
    if (cachedUsers.length == employeeIds.length) {
      return cachedUsers;
    }

    // Get uncached employee IDs
    final uncachedIds = employeeIds
        .where((id) => !cachedUsers.any((user) => user.employeeId == id))
        .toList();

    // Query Firestore for missing users
    final firestoreClient = await FirestoreClient.create(
      Profile.collectionName,
    );
    final snapshot = await firestoreClient.advancedQuery(
      conditions: <QueryCondition>[
        QueryCondition(field: 'employeeId', whereIn: uncachedIds),
      ],
    );

    final result = <Profile>[];

    final documents = snapshot.docs;

    for (final doc in documents) {
      final data = doc.data();

      final profile = Profile.fromJson(data, doc.id);
      _cachedUsers.add(profile);

      result.add(profile);
    }

    // Return combined results
    return [...cachedUsers, ...result];
  }

  static Future<void> generateSampleUsers() async {
    final maxDummy = 10;

    final authService = AuthService.getInstance();

    for (var i = 1; i <= maxDummy; i++) {
      final user = Profile.random();

      await authService.register(user);
    }
  }
}
