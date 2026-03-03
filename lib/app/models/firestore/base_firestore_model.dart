import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:room_reservation_mobile_app/app/core/session/session_user_context.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/utils/date_formatter.dart';

abstract class BaseFirestoreModel {
  static const String createdByField = 'createdBy';
  static const String updatedByField = 'updatedBy';
  static const String deletedByField = 'deletedBy';
  static const String createdAtField = 'createdAt';
  static const String updatedAtField = 'updatedAt';
  static const String deletedAtField = 'deletedAt';

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
      createdByField: createdBy,
      updatedByField: updatedBy,
      deletedByField: deletedBy,
      createdAtField: createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      updatedAtField: updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      deletedAtField: deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    };
  }

  Map<String, dynamic> toJson() {
    final payload = {
      createdByField: createdBy,
      updatedByField: updatedBy,
      deletedByField: deletedBy,
      createdAtField: createdAt?.millisecondsSinceEpoch,
      updatedAtField: updatedAt?.millisecondsSinceEpoch,
      deletedAtField: deletedAt?.millisecondsSinceEpoch,
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

    createdBy = _getUserReference(map[createdByField]);
    updatedBy = _getUserReference(map[updatedByField]);
    deletedBy = _getUserReference(map[deletedByField]);

    createdAt = DateFormatter.getDateTime(map[createdAtField]);
    updatedAt = DateFormatter.getDateTime(map[updatedAtField]);
    deletedAt = DateFormatter.getDateTime(map[deletedAtField]);
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

  void prepareForCreate() {
    createdBy = SessionUserContext.currentUser?.reference;
    createdAt = DateTime.now();
  }

  void prepareForUpdate() {
    if (id == null) {
      throw 'Cannot prepare for update: Document ID is null';
    }

    updatedBy = SessionUserContext.currentUser?.reference;
    updatedAt = DateTime.now();
  }

  void markAsDeleted() {
    if (id == null) {
      throw 'Cannot mark as deleted: Document ID is null';
    }

    deletedBy = SessionUserContext.currentUser?.reference;
    deletedAt = DateTime.now();
  }
}
