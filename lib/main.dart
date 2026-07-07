import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rapa_track_mobile_app/app/pages/home_page.dart';
import 'package:rapa_track_mobile_app/app/pages/login_page.dart';
import 'package:rapa_track_mobile_app/app/pages/splash_screen_page.dart';
import 'package:rapa_track_mobile_app/app/states/authentication_state.dart';
import 'package:rapa_track_mobile_app/app/utils/navigation_handler.dart';
import 'package:rapa_track_mobile_app/app/utils/notification_handler.dart';
import 'package:rapa_track_mobile_app/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationHandlerUtil.initialize();

  runApp(const RoomReservationApp());
}

class RoomReservationApp extends StatefulWidget {
  const RoomReservationApp({super.key});

  @override
  State<RoomReservationApp> createState() => _RoomReservationAppState();
}

class _RoomReservationAppState extends State<RoomReservationApp> {
  final authenticationState = AuthenticationState();

  @override
  void initState() {
    super.initState();
    _initializeApplication();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationHandler.navigatorKey,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID')],
      locale: const Locale('id', 'ID'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: false),

      home: const SplashScreenPage(),
    );
  }

  Future<void> _initializeApplication() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      await initializeDateFormatting('id_ID', null);

      await authenticationState.initialize();
      await NotificationHandlerUtil.handleInitialMessage();

      if (!mounted) return;

      final user = authenticationState.user;
      final userId = user?.id;

      final initialPage = userId == null ? const LoginPage() : const HomePage();

      NavigationHandler.navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (_) => initialPage),
      );
    } catch (_) {
      if (mounted) {
        NavigationHandler.navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    }
  }
}
