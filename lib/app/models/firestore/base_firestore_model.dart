import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';

abstract class BaseFirestoreModel {
  static final _dateFormat = DateFormat('EEEE, dd MMMM yyyy HH:mm:ss', 'id_ID');

  String? id;
  DocumentReference? reference;
  DocumentReference? createdBy;
  DocumentReference? updatedBy;
  DocumentReference? deletedBy;
  Profile? createdByProfile;
  Profile? updatedByProfile;
  Profile? deletedByProfile;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  String? get createdAtFormatted =>
      createdAt != null ? _dateFormat.format(createdAt!) : null;

  String? get updatedAtFormatted =>
      updatedAt != null ? _dateFormat.format(updatedAt!) : null;

  String? get deletedAtFormatted =>
      deletedAt != null ? _dateFormat.format(deletedAt!) : null;

  bool get isDeleted => deletedAt != null;

  BaseFirestoreModel({
    this.id,
    this.reference,
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.createdByProfile,
    this.updatedByProfile,
    this.deletedByProfile,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  void validate() {}

  Map<String, dynamic> toMap() {
    return {
      'createdBy': _getUserReference(createdBy?.id),
      'updatedBy': _getUserReference(updatedBy?.id),
      'deletedBy': _getUserReference(deletedBy?.id),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    };
  }

  Map<String, dynamic> toJson() {
    final payload = {
      'createdBy': _getUserReference(createdBy?.id),
      'updatedBy': _getUserReference(updatedBy?.id),
      'deletedBy': _getUserReference(deletedBy?.id),
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
    };

    if (id != null) {
      payload['id'] = id;
    }

    return payload;
  }

  void setCommonFields(
    Map<String, dynamic> map,
    String documentId, [
    DocumentReference? documentRef,
  ]) {
    id = documentId;
    reference = documentRef;

    createdBy = _getUserReference(map['createdBy']);
    updatedBy = _getUserReference(map['updatedBy']);
    deletedBy = _getUserReference(map['deletedBy']);

    createdAt = _getDateTime(map['createdAt']);
    updatedAt = _getDateTime(map['updatedAt']);
    deletedAt = _getDateTime(map['deletedAt']);
  }

  DocumentReference? _getUserReference(dynamic user) {
    if (user == null) return null;

    if (user is DocumentReference) {
      return user;
    }

    if (user is! String) {
      return null;
    }

    return FirebaseFirestore.instance.doc('${Profile.collectionName}/$user');
  }

  DateTime? _getDateTime(dynamic timestamp) {
    if (timestamp == null) return null;

    DateTime? result;

    if (timestamp is Timestamp) {
      result = timestamp.toDate();
    } else if (timestamp is int) {
      result = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      result = DateTime.tryParse('$timestamp');
    }

    return result?.toLocal();
  }

  void prepareForCreate(String? userId) {
    createdBy = _getUserReference(userId);

    final now = DateTime.now();
    createdAt = now;
  }

  void prepareForUpdate(String? userId) {
    if (id == null) {
      throw 'Cannot prepare for update: Document ID is null';
    }

    updatedBy = _getUserReference(userId);

    final now = DateTime.now();
    updatedAt = now;
  }

  void markAsDeleted(String? userId) {
    if (id == null) {
      throw 'Cannot mark as deleted: Document ID is null';
    }

    deletedBy = _getUserReference(userId);
    deletedAt = DateTime.now();
  }
}
