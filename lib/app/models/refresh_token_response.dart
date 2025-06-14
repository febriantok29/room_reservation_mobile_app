class RefreshTokenResponse {
  String? accessToken;
  num? accessTokenExpiresIn;
  DateTime? accessTokenExpiresAt;
  String? refreshToken;
  num? refreshTokenExpiresIn;
  DateTime? refreshTokenExpiresAt;

  RefreshTokenResponse({
    this.accessToken,
    this.accessTokenExpiresIn,
    this.accessTokenExpiresAt,
    this.refreshToken,
    this.refreshTokenExpiresIn,
    this.refreshTokenExpiresAt,
  });

  RefreshTokenResponse.fromJson(dynamic json) {
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
      'accessToken': accessToken,
      'accessTokenExpiresIn': accessTokenExpiresIn,
      'accessTokenExpiresAt': accessTokenExpiresAt?.toIso8601String(),
      'refreshToken': refreshToken,
      'refreshTokenExpiresIn': refreshTokenExpiresIn,
      'refreshTokenExpiresAt': refreshTokenExpiresAt?.toIso8601String(),
    };
  }
}
