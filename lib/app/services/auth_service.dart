import 'package:room_reservation_mobile_app/app/models/auth_token.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/network/route_builder.dart';

class AuthService {
  Future<AuthToken> login({
    required String credential,
    required String password,
    int? accessTokenTtl,
    int? refreshTokenTtl,
  }) async {
    final router = RouteBuilder.noAuth('Auth.login');

    final payload = <String, dynamic>{
      'login': credential,
      'password': password,
    };

    if (accessTokenTtl != null && refreshTokenTtl != null) {
      payload['is_debug'] = true;
      payload['access_token_ttl'] = accessTokenTtl;
      payload['refresh_token_ttl'] = refreshTokenTtl;
    }

    final response = await router.post(body: payload);

    if (response == null || response is! Map<String, dynamic>) {
      throw 'Format respons tidak valid';
    }

    final data = response['data'] ?? response;
    if (data['access_token'] == null) {
      throw data['message'] ?? 'Login gagal, periksa kembali kredensial Anda.';
    }

    return AuthToken.fromJson(data);
  }

  Future<Profile?> getMe() async {
    final router = RouteBuilder('Auth.me');
    final response = await router.get();

    if (response is! Map<String, dynamic>) {
      return null;
    }

    final data = response['data'] ?? response;

    return Profile.fromJson(data);
  }

  Future<AuthToken?> refreshToken({
    required String refreshToken,
    int? accessTokenTtl,
    int? refreshTokenTtl,
  }) async {
    final router = RouteBuilder.noAuth('Auth.refresh');

    final payload = <String, dynamic>{'refresh_token': refreshToken};

    if (accessTokenTtl != null && refreshTokenTtl != null) {
      payload['is_debug'] = true;
      payload['access_token_ttl'] = accessTokenTtl;
      payload['refresh_token_ttl'] = refreshTokenTtl;
    }

    final response = await router.post(body: payload);

    if (response is! Map<String, dynamic>) {
      return null;
    }
    final data = response['data'] ?? response;

    if (data['access_token'] != null) {
      return AuthToken.fromJson(data);
    }

    return null;
  }
}
