import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/pages/login_page.dart';
import 'package:rapa_track_mobile_app/app/pages/reservation/reservation_list_page.dart';
import 'package:rapa_track_mobile_app/app/pages/room/room_list_page.dart';
import 'package:rapa_track_mobile_app/app/services/facility_service.dart';
import 'package:rapa_track_mobile_app/app/states/authentication_state.dart';
import 'package:rapa_track_mobile_app/app/utils/navigation_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _facilityService = FacilityService();
  String _apiResult = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authState = AuthenticationState();
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(title: Text('Home Page')),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              'User gan: ${user?.employeeId} dan ${user?.firstName} ${user?.lastName}',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() => _isLoading = true);
                      try {
                        final facilities = await _facilityService
                            .getFacilityList();
                        setState(() {
                          _apiResult =
                              'Berhasil mengambil ${facilities.length} fasilitas: ${facilities.map((f) => f.name).join(', ')}';
                        });
                      } catch (e) {
                        setState(() {
                          _apiResult = 'Error: $e';
                        });
                      } finally {
                        setState(() => _isLoading = false);
                      }
                    },
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Test API Facility'),
            ),
            const SizedBox(height: 16),
            Text(_apiResult),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: user == null
                  ? null
                  : () {
                      NavigationHandler.navigatorKey.currentState?.push(
                        MaterialPageRoute(
                          builder: (_) => RoomListPage(user: user),
                        ),
                      );
                    },
              child: const Text('Lihat Daftar Ruangan'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: user == null
                  ? null
                  : () {
                      NavigationHandler.navigatorKey.currentState?.push(
                        MaterialPageRoute(
                          builder: (_) => ReservationListPage(user: user),
                        ),
                      );
                    },
              child: const Text('Lihat Daftar Reservasi'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await authState.logout();

                NavigationHandler.navigatorKey.currentState?.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
