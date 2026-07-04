import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_reservation_mobile_app/app/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildLoginPage() {
  return const ProviderScope(child: MaterialApp(home: LoginPage()));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LoginPage', () {
    testWidgets('menampilkan form login lengkap', (tester) async {
      await tester.pumpWidget(_buildLoginPage());
      await tester.pumpAndSettle();

      expect(find.text('Reservasi Ruangan'), findsOneWidget);
      expect(find.text('No. Induk Pegawai / Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.byIcon(Icons.login_rounded), findsOneWidget);
    });

    testWidgets('menampilkan error saat form kosong disubmit', (tester) async {
      await tester.pumpWidget(_buildLoginPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(
        find.text('No. Induk Pegawai / Email dan password harus diisi'),
        findsOneWidget,
      );
    });

    testWidgets('toggle visibilitas password berfungsi', (tester) async {
      await tester.pumpWidget(_buildLoginPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('mengisi kredensial terakhir dari SharedPreferences', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'employeeId': '2599001HPI'});

      await tester.pumpWidget(_buildLoginPage());
      await tester.pumpAndSettle();

      expect(find.text('2599001HPI'), findsOneWidget);
    });
  });
}
