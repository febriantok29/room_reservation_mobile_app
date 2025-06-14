import 'profile.dart';

class LoginResponse {
  String? id;
  String? username;
  String? firstName;
  String? email;
  String? role;
  String? accessToken;
  num? accessTokenExpiresIn;
  DateTime? accessTokenExpiresAt;
  String? refreshToken;
  num? refreshTokenExpiresIn;
  DateTime? refreshTokenExpiresAt;

  LoginResponse({
    this.id,
    this.username,
    this.firstName,
    this.email,
    this.role,
    this.accessToken,
    this.accessTokenExpiresIn,
    this.accessTokenExpiresAt,
    this.refreshToken,
    this.refreshTokenExpiresIn,
    this.refreshTokenExpiresAt,
  });

  LoginResponse.fromJson(dynamic json) {
    id = json['id'];
    username = json['username'];
    firstName = json['firstName'];
    email = json['email'];
    role = json['role'];
    accessToken = json['accessToken'];
    accessTokenExpiresIn = json['accessTokenExpiresIn'];
    accessTokenExpiresAt = DateTime.tryParse(
      '${json['accessTokenExpiresAt']}',
    )?.toLocal();
    refreshToken = json['refreshToken'];
    refreshTokenExpiresIn = json['refreshTokenExpiresIn'];
    refreshTokenExpiresAt = DateTime.tryParse(
      '${json['refreshTokenExpiresAt']}',
    )?.toLocal();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'firstName': firstName,
      'email': email,
      'role': role,
      'accessToken': accessToken,
      'accessTokenExpiresIn': accessTokenExpiresIn,
      'accessTokenExpiresAt': accessTokenExpiresAt?.toIso8601String(),
      'refreshToken': refreshToken,
      'refreshTokenExpiresIn': refreshTokenExpiresIn,
      'refreshTokenExpiresAt': refreshTokenExpiresAt?.toIso8601String(),
    };
  }

  // Getter untuk mendapatkan UserData dari LoginResponse
  Profile get userData => Profile(
    id: id,
    username: username,
    firstName: firstName,
    email: email,
    role: role,
  );
}
