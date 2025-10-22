// Copyright 2025 The Room Reservation App Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/services/firestore_service/firestore_auth_service.dart';
import 'package:room_reservation_mobile_app/app/utils/mounted_state_mixin.dart';

/// Contoh halaman home dengan fitur logout
class FirestoreHomePage extends StatefulWidget {
  const FirestoreHomePage({super.key});

  @override
  State<FirestoreHomePage> createState() => _FirestoreHomePageState();
}

class _FirestoreHomePageState extends State<FirestoreHomePage>
    with MountedStateMixin {
  // Auth service
  late final Future<FirestoreAuthService> _authService =
      FirestoreAuthService.getInstance();

  // Loading state
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder(
              future: _authService,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final authService = snapshot.data!;

                return FutureBuilder(
                  future: authService.getCurrentUser(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final user = userSnapshot.data;

                    if (user == null) {
                      return const Center(
                        child: Text(
                          'Anda belum login. Silakan login terlebih dahulu.',
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status message
                          if (_statusMessage.isNotEmpty)
                            Container(
                              color: Colors.blue.shade50,
                              width: double.infinity,
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _statusMessage,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Welcome message
                          Text(
                            'Selamat datang, ${user.firstName}!',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),

                          // User info card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Informasi User',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const Divider(),
                                  ListTile(
                                    leading: const Icon(Icons.person),
                                    title: const Text('Nama'),
                                    subtitle: Text(
                                      '${user.firstName} ${user.lastName}',
                                    ),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.email),
                                    title: const Text('Email'),
                                    subtitle: Text(user.email ?? '-'),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.account_circle),
                                    title: const Text('Username'),
                                    subtitle: Text(user.employeeId ?? '-'),
                                  ),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.admin_panel_settings,
                                    ),
                                    title: const Text('Role'),
                                    subtitle: Text('${user.role}'),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Logout button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _logout,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Logout'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  /// Logout user
  Future<void> _logout() async {
    if (!canContinue) return;

    setStateIfMounted(() {
      _isLoading = true;
      _statusMessage = 'Logging out...';
    });

    try {
      final authService = await _authService;
      await authService.logout();

      setStateIfMounted(() {
        _statusMessage = 'Logout berhasil';
      });

      // Navigate back to login page
      if (canContinue && mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setStateIfMounted(() {
        _statusMessage = 'Error logout: ${e.toString()}';
      });
    } finally {
      setStateIfMounted(() {
        _isLoading = false;
      });
    }
  }
}
