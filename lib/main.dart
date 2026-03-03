import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:room_reservation_mobile_app/app/pages/splash_page.dart';
import 'package:room_reservation_mobile_app/app/theme/app_theme.dart';
import 'package:room_reservation_mobile_app/app/utils/navigation_handler.dart';
import 'package:room_reservation_mobile_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeDateFormatting('id_ID', null);
  runApp(const ProviderScope(child: RoomReservationApp()));
}

class RoomReservationApp extends StatelessWidget {
  const RoomReservationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationHandler.navigatorKey,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Indonesian
      ],
      locale: const Locale('id', 'ID'),
      theme: AppTheme.light,
      home: const SplashPage(),
    );
  }
}
