import 'package:intl/intl.dart';

/// Base model untuk semua model yang menggunakan REST API
abstract class BaseModel {
  static final _dateFormat = DateFormat('EEEE, dd MMMM yyyy HH:mm:ss', 'id_ID');

  String? id;
  String? createdBy;
  String? updatedBy;
  String? deletedBy;
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

  BaseModel({
    this.id,
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  void setCommonFieldsFromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    createdBy = json['created_by']?.toString();
    updatedBy = json['updated_by']?.toString();
    deletedBy = json['deleted_by']?.toString();
    createdAt = DateTime.tryParse('${json['created_at'] ?? ''}')?.toLocal();
    updatedAt = DateTime.tryParse('${json['updated_at'] ?? ''}')?.toLocal();
    deletedAt = DateTime.tryParse('${json['deleted_at'] ?? ''}')?.toLocal();
  }
}
