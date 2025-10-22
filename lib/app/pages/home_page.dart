import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/examples/admin_register_page.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/pages/login_page.dart';
import 'package:room_reservation_mobile_app/app/pages/room/room_list_page.dart';
import 'package:room_reservation_mobile_app/app/states/auth_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _menus = <_HomePageButton>[];

  @override
  Widget build(BuildContext context) {
    final user = AuthState.currentUser;
    final menus = _getMenus(user);

    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text('Hello, ${user?.name ?? 'Guest'}!'),

            SizedBox(height: 24.0),

            ...menus.map((menu) {
              return GestureDetector(
                onTap: () => menu.onPressed(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                  margin: EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: menu.color,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Icon(menu.icon, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          menu.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            ElevatedButton(onPressed: _doLogout, child: Text('Logout')),
          ],
        ),
      ),
    );
  }

  List<_HomePageButton> _getMenus(Profile? user) {
    if (user == null) {
      return [];
    }

    if (_menus.isNotEmpty) {
      return _menus;
    }

    final isAdmin = user.isAdmin;

    _menus.addAll([
      if (isAdmin)
        _HomePageButton.admin(
          title: 'Admin Register',
          icon: Icons.admin_panel_settings,
          color: Colors.red,
          page: const AdminRegisterPage(),
        ),
      _HomePageButton(
        title: 'Room List',
        icon: Icons.meeting_room,
        color: Colors.blue,
        page: RoomListPage(user: user),
      ),
    ]);

    setState(() {});

    return _menus;
  }

  Future<void> _doLogout() async {
    await AuthState.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }
}

class _HomePageButton {
  final String title;
  final IconData icon;
  final Color color;
  final Widget? page;
  final Function()? onTap;
  final bool isAdminOnly;

  const _HomePageButton({
    required this.title,
    required this.icon,
    required this.color,
    this.page,
    this.onTap,
  }) : isAdminOnly = false,
       assert(page != null || onTap != null, 'page or onTap must be provided');

  const _HomePageButton.admin({
    required this.title,
    required this.icon,
    required this.color,
    this.page,
    this.onTap,
  }) : isAdminOnly = true,
       assert(page != null || onTap != null, 'page or onTap must be provided');

  void onPressed(BuildContext context) {
    if (onTap != null) {
      onTap!();
    } else if (page != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page!));
    }
  }
}
