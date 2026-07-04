import 'package:flutter_test/flutter_test.dart';
import 'package:room_reservation_mobile_app/app/enums/user_role.dart';
import 'package:room_reservation_mobile_app/app/services/auth_service.dart';

void main() {
  group('AuthTokenPayload', () {
    test('fromJson membaca payload lengkap', () {
      final payload = AuthTokenPayload.fromJson({
        'access_token': 'access-123',
        'refresh_token': 'refresh-456',
        'token_type': 'Bearer',
        'expires_in': 3600,
        'is_debug': true,
      });

      expect(payload.accessToken, 'access-123');
      expect(payload.refreshToken, 'refresh-456');
      expect(payload.tokenType, 'Bearer');
      expect(payload.expiresIn, 3600);
      expect(payload.isDebug, isTrue);
    });

    test('fromJson aman terhadap field yang hilang', () {
      final payload = AuthTokenPayload.fromJson(const {});

      expect(payload.accessToken, isEmpty);
      expect(payload.refreshToken, isNull);
      expect(payload.tokenType, 'Bearer');
      expect(payload.expiresIn, 0);
      expect(payload.isDebug, isFalse);
    });

    test('fromJson menerima expires_in bertipe string', () {
      final payload = AuthTokenPayload.fromJson(const {
        'access_token': 'a',
        'expires_in': '900',
      });

      expect(payload.expiresIn, 900);
    });
  });

  group('AuthMeResponse', () {
    test('fromJson membaca data user', () {
      final me = AuthMeResponse.fromJson(const {
        'id': '42',
        'name': 'Budi Santoso',
        'email': 'budi@example.com',
        'employee_id': '2599001HPI',
        'is_admin': true,
        'is_active': true,
      });

      expect(me.id, '42');
      expect(me.name, 'Budi Santoso');
      expect(me.email, 'budi@example.com');
      expect(me.employeeId, '2599001HPI');
      expect(me.isAdmin, isTrue);
      expect(me.isActive, isTrue);
    });

    test('toProfile memecah nama dan memetakan role admin', () {
      const me = AuthMeResponse(
        id: '42',
        name: 'Budi Agus Santoso',
        email: 'budi@example.com',
        employeeId: '2599001HPI',
        isAdmin: true,
        isActive: true,
      );

      final profile = me.toProfile();

      expect(profile.firstName, 'Budi');
      expect(profile.lastName, 'Agus Santoso');
      expect(profile.role, UserRole.admin);
      expect(profile.email, 'budi@example.com');
      expect(profile.employeeId, '2599001HPI');
    });

    test('toProfile untuk user non-admin dengan satu kata nama', () {
      const me = AuthMeResponse(
        id: '7',
        name: 'Sari',
        email: 'sari@example.com',
        employeeId: '2599002HPI',
        isAdmin: false,
        isActive: true,
      );

      final profile = me.toProfile();

      expect(profile.firstName, 'Sari');
      expect(profile.lastName, isNull);
      expect(profile.role, UserRole.user);
    });
  });

  group('AuthApiException', () {
    test('fromJson membaca pesan dan error code', () {
      final exception = AuthApiException.fromJson(
        statusCode: 401,
        payload: const {
          'message': 'Kredensial salah',
          'error_code': 'INVALID_CREDENTIALS',
        },
      );

      expect(exception.statusCode, 401);
      expect(exception.message, 'Kredensial salah');
      expect(exception.errorCode, 'INVALID_CREDENTIALS');
      expect(
        exception.toString(),
        'AuthApiException(401/INVALID_CREDENTIALS): Kredensial salah',
      );
    });

    test('fromJson memakai pesan default bila kosong', () {
      final exception = AuthApiException.fromJson(
        statusCode: 500,
        payload: const {},
      );

      expect(exception.message, 'Permintaan gagal');
      expect(exception.toString(), 'AuthApiException(500): Permintaan gagal');
    });
  });
}
