class AuthToken {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  const AuthToken({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    DateTime? expiresAt;

    // Support legacy "expires_in" from direct API response
    if (json.containsKey('expires_in') && !json.containsKey('expires_at')) {
      final now = DateTime.now();
      final expiresInSecond = int.tryParse('${json['expires_in']}') ?? 90;
      expiresAt = now.add(Duration(seconds: expiresInSecond));
    } else if (json.containsKey('expires_at')) {
      expiresAt = DateTime.tryParse('${json['expires_at']}');
    }

    return AuthToken(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      expiresAt: expiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
    };
  }
}
