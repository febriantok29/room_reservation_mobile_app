import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:room_reservation_mobile_app/app/network/route_builder.dart';

void main() {
  group('RouteResponse', () {
    test('mendecode body JSON menjadi Map', () {
      final response = RouteResponse.fromHttpResponse(
        http.Response('{"success": true, "data": {"id": 1}}', 200),
      );

      expect(response.isSuccess, isTrue);
      expect(response.data, isA<Map<String, dynamic>>());
      expect(response.data['success'], isTrue);
      expect(response.data['data'], {'id': 1});
    });

    test('body bukan JSON dikembalikan sebagai string mentah', () {
      final response = RouteResponse.fromHttpResponse(
        http.Response('plain text', 200),
      );

      expect(response.data, 'plain text');
      expect(response.rawBody, 'plain text');
    });

    test('body kosong menghasilkan data null', () {
      final response = RouteResponse.fromHttpResponse(http.Response('', 204));

      expect(response.data, isNull);
      expect(response.isSuccess, isTrue);
    });

    test('isSuccess hanya untuk status 2xx', () {
      expect(
        RouteResponse.fromHttpResponse(http.Response('', 200)).isSuccess,
        isTrue,
      );
      expect(
        RouteResponse.fromHttpResponse(http.Response('', 299)).isSuccess,
        isTrue,
      );
      expect(
        RouteResponse.fromHttpResponse(http.Response('', 199)).isSuccess,
        isFalse,
      );
      expect(
        RouteResponse.fromHttpResponse(http.Response('', 401)).isSuccess,
        isFalse,
      );
      expect(
        RouteResponse.fromHttpResponse(http.Response('', 500)).isSuccess,
        isFalse,
      );
    });
  });
}
