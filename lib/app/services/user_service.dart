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

  static Future<List<Profile>> getAllUsers({bool forceRefresh = false}) async {
    if (forceRefresh == false && _cachedUsers.isNotEmpty) {
      return _cachedUsers.where((user) => user.role != UserRole.admin).toList();
    }

    final client = await FirestoreClient.create(Profile.collectionName);

    final snapshot = await client
        .query(field: 'role', isNotEqualTo: UserRole.admin.name)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final profile = Profile.fromJson(data, doc.id);
      _updateCache(profile);
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
    _updateCache(profile);

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

    final snapshot = await firestoreClient
        .query(field: 'employeeId', isEqualTo: employeeId)
        .get();

    if (snapshot.docs.isEmpty) {
      throw 'Akun tidak ditemukan.';
    }

    // Create and cache profile
    final doc = snapshot.docs.first;

    final data = doc.data();

    final profile = Profile.fromJson(data, doc.id);
    _updateCache(profile);

    return profile;
  }

  static Future<List<Profile>> getUserByDocIds(
    Set<String> employeeDocIds,
  ) async {
    if (employeeDocIds.isEmpty) {
      return [];
    }

    // Filter cached users that match requested IDs
    final cachedUsers = _cachedUsers
        .where((user) => employeeDocIds.contains(user.employeeId))
        .toList();

    // Return if we found all requested users in cache
    if (cachedUsers.length == employeeDocIds.length) {
      return cachedUsers;
    }

    // Get uncached employee IDs
    final uncachedIds = employeeDocIds
        .difference(cachedUsers.map((e) => e.employeeId).toSet())
        .toList();

    // Query Firestore for missing users
    final client = await FirestoreClient.create(Profile.collectionName);
    final snapshot = await client
        .query(field: FieldPath.documentId, whereIn: uncachedIds)
        .get();

    final fetchedRooms = <Profile>[];

    final documents = snapshot.docs;

    for (final doc in documents) {
      if (!doc.exists) continue;

      final data = doc.data();

      final profile = Profile.fromJson(data, doc.id);

      fetchedRooms.add(profile);

      _updateCache(profile);
    }

    // Return combined results
    return [...cachedUsers, ...fetchedRooms];
  }

  static void logout(Profile profile) {
    _cachedUsers.removeWhere((u) => u.id == profile.id);
  }

  static Future<void> generateSampleUsers() async {
    final maxDummy = 10;

    final authService = AuthService.getInstance();

    for (var i = 1; i <= maxDummy; i++) {
      final user = Profile.random();

      await authService.register(user);
    }
  }

  static void _updateCache(Profile profile) {
    if (profile.id == null) return;

    final index = _cachedUsers.indexWhere((u) => u.id == profile.id);

    if (index >= 0) {
      _cachedUsers[index] = profile;
    } else {
      _cachedUsers.add(profile);
    }
  }
}
