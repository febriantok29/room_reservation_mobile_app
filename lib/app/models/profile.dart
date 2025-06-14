class Profile {
  String? id;
  String? username;
  String? email;
  String? password;
  String? firstName;
  String? lastName;
  String? gender;
  String? phone;
  DateTime? dateOfBirth;
  String? address;
  String? role;
  String? createdBy;
  String? updatedBy;
  String? deletedBy;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  Profile({
    this.id,
    this.username,
    this.email,
    this.password,
    this.firstName,
    this.lastName,
    this.gender,
    this.phone,
    this.dateOfBirth,
    this.address,
    this.role,
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  Profile.fromJson(dynamic json) {
    id = json['id'];
    username = json['username'];
    email = json['email'];
    password = json['password'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    gender = json['gender'];
    phone = json['phone'];
    dateOfBirth = DateTime.tryParse('${json['dateOfBirth']}')?.toLocal();
    address = json['address'];
    role = json['role'];
    createdBy = json['createdBy'];
    updatedBy = json['updatedBy'];
    deletedBy = json['deletedBy'];
    createdAt = DateTime.tryParse('${json['createdAt']}')?.toLocal();
    updatedAt = DateTime.tryParse('${json['updatedAt']}')?.toLocal();
    deletedAt = DateTime.tryParse('${json['deletedAt']}')?.toLocal();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'phone': phone,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'address': address,
      'role': role,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'deletedBy': deletedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  String get name => '${firstName ?? ''} ${lastName ?? ''}'.trim();
}
