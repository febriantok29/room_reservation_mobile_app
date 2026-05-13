import 'package:room_reservation_mobile_app/app/core/auth/auth_token_manager.dart';
import 'package:room_reservation_mobile_app/app/enums/user_role.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/network/route_builder.dart';

class AuthService {
  AuthService._() {
    _tokenManager.configureRefreshHandler((refreshToken) async {
      return refreshTokenFromApi(refreshToken: refreshToken);
    });
  }

  static AuthService? _instance;
  final AuthTokenManager _tokenManager = AuthTokenManager.instance;

  factory AuthService.getInstance() {
    _instance ??= AuthService._();
    return _instance!;
  }

  String? get accessToken => _tokenManager.accessToken;
  String? get refreshToken => _tokenManager.refreshToken;

  Future<void> restoreApiSession() {
    return _tokenManager.ensureLoaded();
  }

  Future<AuthTokenPayload> loginToApi({
    required String login,
    required String password,
  }) async {
    final router = RouteBuilder.noAuth(
      'Auth.login',
      tokenManager: _tokenManager,
    );

    final response = await router.post({'login': login, 'password': password});

    final json = _readJsonMap(response);

    if (!response.isSuccess || json['success'] != true) {
      throw AuthApiException.fromJson(
        statusCode: response.statusCode,
        payload: json,
      );
    }

    final payload = AuthTokenPayload.fromJson(
      _readJsonMapFrom(json, key: 'data'),
    );

    await _tokenManager.saveTokens(
      accessToken: payload.accessToken,
      refreshToken: payload.refreshToken,
      expiresInSeconds: payload.expiresIn,
    );

    return payload;
  }

  Future<AuthTokenData?> refreshTokenFromApi({String? refreshToken}) async {
    final tokenToRefresh = refreshToken ?? _tokenManager.refreshToken;

    if (tokenToRefresh == null || tokenToRefresh.isEmpty) {
      return null;
    }

    final response = await RouteBuilder.noAuth(
      'Auth.refresh',
      tokenManager: _tokenManager,
    ).post({'refresh_token': tokenToRefresh});

    final json = _readJsonMap(response);

    if (!response.isSuccess || json['success'] != true) {
      await _tokenManager.clear();
      throw AuthApiException.fromJson(
        statusCode: response.statusCode,
        payload: json,
      );
    }

    final payload = AuthTokenPayload.fromJson(
      _readJsonMapFrom(json, key: 'data'),
    );

    final resolvedRefreshToken = payload.refreshToken ?? tokenToRefresh;

    await _tokenManager.saveTokens(
      accessToken: payload.accessToken,
      refreshToken: resolvedRefreshToken,
      expiresInSeconds: payload.expiresIn,
    );

    return AuthTokenData(
      accessToken: payload.accessToken,
      refreshToken: resolvedRefreshToken,
      expiresAt: DateTime.now().add(Duration(seconds: payload.expiresIn)),
    );
  }

  Future<AuthMeResponse> getMeFromApi() async {
    final response = await RouteBuilder(
      'Auth.me',
      tokenManager: _tokenManager,
    ).get();
    final json = _readJsonMap(response);

    if (!response.isSuccess || json['success'] != true) {
      throw AuthApiException.fromJson(
        statusCode: response.statusCode,
        payload: json,
      );
    }

    return AuthMeResponse.fromJson(_readJsonMapFrom(json, key: 'data'));
  }

  Future<Profile> getMyProfileFromApi() async {
    final me = await getMeFromApi();
    return me.toProfile();
  }

  Future<void> logoutApiSession() {
    return _logoutAndClearToken();
  }

  Future<void> _logoutAndClearToken() async {
    await _tokenManager.ensureLoaded();

    if (_tokenManager.hasAccessToken) {
      try {
        await RouteBuilder(
          'Auth.logout',
          tokenManager: _tokenManager,
          enableAutoRefreshToken: false,
        ).post(<String, dynamic>{});
      } catch (_) {}
    }

    await _tokenManager.clear();
  }

  Map<String, dynamic> _readJsonMap(RouteResponse response) {
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }

    throw AuthApiException(
      statusCode: response.statusCode,
      message: 'Format respons API tidak valid',
    );
  }

  Map<String, dynamic> _readJsonMapFrom(
    Map<String, dynamic> source, {
    required String key,
  }) {
    final data = source[key];

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw AuthApiException(
      statusCode: 500,
      message: 'Data respons API tidak valid pada key "$key"',
    );
  }
}

class AuthTokenPayload {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final int expiresIn;
  final bool isDebug;

  const AuthTokenPayload({
    required this.accessToken,
    this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.isDebug,
  });

  factory AuthTokenPayload.fromJson(Map<String, dynamic> json) {
    return AuthTokenPayload(
      accessToken: '${json['access_token'] ?? ''}',
      refreshToken: json['refresh_token']?.toString(),
      tokenType: '${json['token_type'] ?? 'Bearer'}',
      expiresIn: int.tryParse('${json['expires_in'] ?? 0}') ?? 0,
      isDebug: json['is_debug'] == true,
    );
  }
}

class AuthMeResponse {
  final String id;
  final String name;
  final String email;
  final String employeeId;
  final bool isAdmin;
  final bool isActive;

  const AuthMeResponse({
    required this.id,
    required this.name,
    required this.email,
    required this.employeeId,
    required this.isAdmin,
    required this.isActive,
  });

  factory AuthMeResponse.fromJson(Map<String, dynamic> json) {
    return AuthMeResponse(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      email: '${json['email'] ?? ''}',
      employeeId: '${json['employee_id'] ?? ''}',
      isAdmin: json['is_admin'] == true,
      isActive: json['is_active'] == true,
    );
  }

  Profile toProfile() {
    final chunks = name.trim().split(RegExp(r'\s+'));
    final firstName = chunks.isNotEmpty ? chunks.first : null;
    final lastName = chunks.length > 1 ? chunks.sublist(1).join(' ') : null;

    return Profile(
      id: id,
      employeeId: employeeId,
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: isAdmin ? UserRole.admin : UserRole.user,
      isActive: isActive,
    );
  }
}

class AuthApiException implements Exception {
  final int statusCode;
  final String message;
  final String? errorCode;

  const AuthApiException({
    required this.statusCode,
    required this.message,
    this.errorCode,
  });

  factory AuthApiException.fromJson({
    required int statusCode,
    required Map<String, dynamic> payload,
  }) {
    return AuthApiException(
      statusCode: statusCode,
      message: '${payload['message'] ?? 'Permintaan gagal'}',
      errorCode: payload['error_code']?.toString(),
    );
  }

  @override
  String toString() {
    final normalizedError = (errorCode == null || errorCode!.isEmpty)
        ? null
        : errorCode;

    if (normalizedError == null) {
      return 'AuthApiException($statusCode): $message';
    }

    return 'AuthApiException($statusCode/$normalizedError): $message';
  }
}
