// Copyright 2025 The Room Reservation App Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// FirestoreClient
///
/// A simple wrapper around Firestore that provides common CRUD operations
/// and other utilities to work with Firestore database.
///
/// Example usage:
///
/// ```dart
/// // Create a client for 'users' collection
/// final usersClient = await FirestoreClient.create('users');
///
/// // Create a new user
/// final newUser = {
///   'name': 'John Doe',
///   'email': 'john@example.com',
///   'createdAt': FieldValue.serverTimestamp(),
/// };
/// final docRef = await usersClient.add(newUser);
/// print('Created user with ID: ${docRef.id}');
///
/// // Get a user by ID
/// final userSnapshot = await usersClient.get(docRef.id);
/// final userData = userSnapshot.data() as Map<String, dynamic>;
/// print('User data: $userData');
///
/// // Query users by email
/// final querySnapshot = await usersClient.query(
///   field: 'email',
///   isEqualTo: 'john@example.com',
/// );
/// for (var doc in querySnapshot.docs) {
///   print('Found user: ${doc.data()}');
/// }
///
/// // Update a user
/// await usersClient.update(docRef.id, {'lastLogin': DateTime.now()});
///
/// // Delete a user
/// await usersClient.delete(docRef.id);
/// ```
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// A client wrapper for Firestore that provides basic CRUD operations
/// This class simplifies the interaction with Firestore by providing common methods
class FirestoreClient {
  /// Firestore instance
  final FirebaseFirestore _firestore;

  /// Collection reference
  final CollectionReference<Map<String, dynamic>> _collectionRef;

  /// Collection path
  final String _collectionPath;

  /// Private constructor
  FirestoreClient._({
    required FirebaseFirestore firestore,
    required String collectionPath,
  }) : _firestore = firestore,
       _collectionPath = collectionPath,
       _collectionRef = firestore.collection(collectionPath);

  /// Factory method to create a FirestoreClient instance
  /// This method initializes Firebase if it's not already initialized
  static Future<FirestoreClient> create(String collectionPath) async {
    try {
      // Initialize Firebase if not already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // Get Firestore instance
      final firestore = FirebaseFirestore.instance;

      return FirestoreClient._(
        firestore: firestore,
        collectionPath: collectionPath,
      );
    } catch (e) {
      debugPrint('Error initializing FirestoreClient: $e');
      rethrow;
    }
  }

  /// Get collection reference
  CollectionReference<Map<String, dynamic>> getCollectionRef() {
    return _collectionRef;
  }

  /// Get collection path
  String get collectionPath => _collectionPath;

  /// Get document reference for a specific document ID
  DocumentReference<Map<String, dynamic>> document(String documentId) {
    return _collectionRef.doc(documentId);
  }

  /// Create a new document in the collection with auto-generated ID
  /// Returns the document reference for the created document
  Future<DocumentReference<Map<String, dynamic>>> add(
    Map<String, dynamic> data,
  ) async {
    try {
      return await _collectionRef.add(data);
    } catch (e) {
      debugPrint('Error adding document: $e');
      rethrow;
    }
  }

  /// Create a new document in the collection with specific ID
  /// Returns void as there's no document reference to return
  Future<void> set(
    String documentId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    try {
      await _collectionRef.doc(documentId).set(data, SetOptions(merge: merge));
    } catch (e) {
      debugPrint('Error setting document: $e');
      rethrow;
    }
  }

  /// Update an existing document in the collection
  /// Returns void as there's no document reference to return
  Future<void> update(String documentId, Map<String, dynamic> data) async {
    try {
      await _collectionRef.doc(documentId).update(data);
    } catch (e) {
      debugPrint('Error updating document: $e');
      rethrow;
    }
  }

  /// Delete a document from the collection
  /// Returns void as there's no document reference to return
  Future<void> delete(String documentId) async {
    try {
      await _collectionRef.doc(documentId).delete();
    } catch (e) {
      debugPrint('Error deleting document: $e');
      rethrow;
    }
  }

  /// Get a document by ID
  /// Returns the document snapshot for the specified document ID
  Future<DocumentSnapshot<Map<String, dynamic>>> get(String documentId) async {
    try {
      return await _collectionRef.doc(documentId).get();
    } catch (e) {
      debugPrint('Error getting document: $e');
      rethrow;
    }
  }

  /// Get all documents in the collection
  /// Returns a query snapshot containing all documents in the collection
  Future<QuerySnapshot<Map<String, dynamic>>> getAll() async {
    try {
      return await _collectionRef.get();
    } catch (e) {
      debugPrint('Error getting all documents: $e');
      rethrow;
    }
  }

  /// Query documents with simple where condition
  /// Returns a query snapshot containing documents that match the condition
  Query<Map<String, dynamic>> query({
    required dynamic field,
    dynamic isEqualTo,
    dynamic isNotEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic arrayContains,
    List<dynamic>? arrayContainsAny,
    List<dynamic>? whereIn,
    List<dynamic>? whereNotIn,
  }) {
    try {
      if (field == null) {
        throw ArgumentError('Field parameter cannot be null');
      }

      Query<Map<String, dynamic>> query = _collectionRef;

      if (isEqualTo != null) {
        query = query.where(field, isEqualTo: isEqualTo);
      }
      if (isNotEqualTo != null) {
        query = query.where(field, isNotEqualTo: isNotEqualTo);
      }
      if (isLessThan != null) {
        query = query.where(field, isLessThan: isLessThan);
      }
      if (isLessThanOrEqualTo != null) {
        query = query.where(field, isLessThanOrEqualTo: isLessThanOrEqualTo);
      }
      if (isGreaterThan != null) {
        query = query.where(field, isGreaterThan: isGreaterThan);
      }
      if (isGreaterThanOrEqualTo != null) {
        query = query.where(
          field,
          isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
        );
      }
      if (arrayContains != null) {
        query = query.where(field, arrayContains: arrayContains);
      }
      if (arrayContainsAny != null) {
        query = query.where(field, arrayContainsAny: arrayContainsAny);
      }
      if (whereIn != null) {
        query = query.where(field, whereIn: whereIn);
      }
      if (whereNotIn != null) {
        query = query.where(field, whereNotIn: whereNotIn);
      }

      return query;
    } catch (e) {
      debugPrint('Error querying documents: $e');
      rethrow;
    }
  }

  /// Stream all documents in the collection
  /// Returns a stream of query snapshots for real-time updates
  Stream<QuerySnapshot<Map<String, dynamic>>> stream() {
    return _collectionRef.snapshots();
  }

  /// Stream a specific document
  /// Returns a stream of document snapshots for real-time updates
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDocument(
    String documentId,
  ) {
    return _collectionRef.doc(documentId).snapshots();
  }

  /// Query documents with multiple conditions
  /// This is a more advanced query method that allows multiple conditions
  Query<Map<String, dynamic>> advancedQuery({
    required List<QueryCondition> conditions,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    try {
      Query<Map<String, dynamic>> query = _collectionRef;

      // Apply all conditions
      for (final condition in conditions) {
        query = query.where(
          condition.field,
          isEqualTo: condition.isEqualTo,
          isNotEqualTo: condition.isNotEqualTo,
          isLessThan: condition.isLessThan,
          isLessThanOrEqualTo: condition.isLessThanOrEqualTo,
          isGreaterThan: condition.isGreaterThan,
          isGreaterThanOrEqualTo: condition.isGreaterThanOrEqualTo,
          arrayContains: condition.arrayContains,
          arrayContainsAny: condition.arrayContainsAny,
          whereIn: condition.whereIn,
          whereNotIn: condition.whereNotIn,
        );
      }

      // Apply ordering if specified
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit if specified
      if (limit != null) {
        query = query.limit(limit);
      }

      return query;
    } catch (e) {
      debugPrint('Error with advanced query: $e');
      rethrow;
    }
  }

  /// Batch write operations
  /// Executes multiple operations in a single batch for atomicity
  Future<void> batch({List<BatchOperation> operations = const []}) async {
    try {
      final batch = _firestore.batch();

      for (final operation in operations) {
        final docRef = _collectionRef.doc(operation.documentId);

        switch (operation.type) {
          case BatchOperationType.set:
            batch.set(
              docRef,
              operation.data!,
              SetOptions(merge: operation.merge ?? false),
            );
            break;
          case BatchOperationType.update:
            batch.update(docRef, operation.data!);
            break;
          case BatchOperationType.delete:
            batch.delete(docRef);
            break;
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error in batch operation: $e');
      rethrow;
    }
  }

  /// Run a transaction
  /// Executes multiple operations in a transaction for consistency
  Future<T> transaction<T>(
    Future<T> Function(Transaction transaction) transactionHandler,
  ) async {
    try {
      return await _firestore.runTransaction(transactionHandler);
    } catch (e) {
      debugPrint('Error in transaction: $e');
      rethrow;
    }
  }

  /// Creates a subcollection client
  /// Useful for handling nested collections within documents
  Future<FirestoreClient> subcollection(
    String documentId,
    String subcollectionName,
  ) async {
    final subcollectionPath = '$_collectionPath/$documentId/$subcollectionName';
    return FirestoreClient.create(subcollectionPath);
  }

  /// Checks if a document exists
  Future<bool> exists(String documentId) async {
    try {
      final doc = await _collectionRef.doc(documentId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking if document exists: $e');
      rethrow;
    }
  }

  /// Count documents in collection (with optional query)
  Future<int> count({List<QueryCondition>? conditions}) async {
    try {
      Query query = _collectionRef;

      if (conditions != null) {
        for (final condition in conditions) {
          query = query.where(
            condition.field,
            isEqualTo: condition.isEqualTo,
            isNotEqualTo: condition.isNotEqualTo,
            isLessThan: condition.isLessThan,
            isLessThanOrEqualTo: condition.isLessThanOrEqualTo,
            isGreaterThan: condition.isGreaterThan,
            isGreaterThanOrEqualTo: condition.isGreaterThanOrEqualTo,
            arrayContains: condition.arrayContains,
            arrayContainsAny: condition.arrayContainsAny,
            whereIn: condition.whereIn,
            whereNotIn: condition.whereNotIn,
          );
        }
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      // If count() is not supported (older Firebase versions)
      try {
        final snapshot = await _collectionRef.get();
        return snapshot.size;
      } catch (e) {
        debugPrint('Error counting documents: $e');
        rethrow;
      }
    }
  }

  /// Perform prefix search on a field
  /// This implements the strategy of using isGreaterThanOrEqualTo and isLessThanOrEqualTo
  /// to search for documents where the field starts with a specific prefix
  ///
  /// Example usage:
  /// ```dart
  /// final results = await client.searchByPrefix(
  ///   field: 'name',
  ///   prefix: 'jo', // Will match 'john', 'joseph', etc.
  /// );
  /// ```
  Future<QuerySnapshot<Map<String, dynamic>>> searchByPrefix({
    required String field,
    required String prefix,
    int? limit,
    String? orderBy,
    bool descending = false,
  }) async {
    try {
      if (prefix.isEmpty) {
        return await getAll();
      }

      // For prefix search, we use the technique with Unicode character
      // We search for all values greater than or equal to the prefix
      // and less than or equal to prefix + \uf8ff (high-value Unicode char)
      final endPrefix = '$prefix\uf8ff';

      debugPrint('Searching $field with prefix: $prefix, end: $prefix\uf8ff');

      Query<Map<String, dynamic>> query = _collectionRef
          .where(field, isGreaterThanOrEqualTo: prefix)
          .where(field, isLessThanOrEqualTo: endPrefix);

      // Apply ordering if specified
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      } else {
        // Default order by the search field
        query = query.orderBy(field, descending: descending);
      }

      // Apply limit if specified
      if (limit != null) {
        query = query.limit(limit);
      }

      final result = await query.get();
      debugPrint('Prefix search results for $field: ${result.docs.length}');

      return result;
    } catch (e) {
      debugPrint('Error searching by prefix: $e');
      rethrow;
    }
  }

  /// Perform a multi-field search with a prefix
  /// This method allows searching across multiple fields for a prefix
  /// It returns a list of QuerySnapshot, one for each field search
  ///
  /// Example usage:
  /// ```dart
  /// final results = await client.multiFieldPrefixSearch(
  ///   fields: ['name', 'description', 'location'],
  ///   prefix: 'co',
  ///   limit: 10,
  /// );
  /// ```
  Future<List<QuerySnapshot<Map<String, dynamic>>>> multiFieldPrefixSearch({
    required List<String> fields,
    required String prefix,
    int? limit,
    bool descending = false,
  }) async {
    try {
      if (prefix.isEmpty) {
        return [await getAll()];
      }

      // Create a list to hold results from each field search
      final results = <QuerySnapshot<Map<String, dynamic>>>[];

      // Search each field
      for (final field in fields) {
        final snapshot = await searchByPrefix(
          field: field,
          prefix: prefix,
          limit: limit,
          orderBy: field,
          descending: descending,
        );

        results.add(snapshot);
      }

      return results;
    } catch (e) {
      debugPrint('Error in multi-field prefix search: $e');
      rethrow;
    }
  }

  /// Get Firestore instance
  FirebaseFirestore get firestore => _firestore;
}

/// A class representing a query condition for the advancedQuery method
class QueryCondition {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;

  QueryCondition({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
  });
}

/// Enum representing the type of batch operation
enum BatchOperationType { set, update, delete }

/// A class representing a batch operation
class BatchOperation {
  final BatchOperationType type;
  final String documentId;
  final Map<String, dynamic>? data;
  final bool? merge;

  BatchOperation.set(this.documentId, this.data, {this.merge = false})
    : type = BatchOperationType.set;

  BatchOperation.update(this.documentId, this.data)
    : type = BatchOperationType.update,
      merge = null;

  BatchOperation.delete(this.documentId)
    : type = BatchOperationType.delete,
      data = null,
      merge = null;
}
