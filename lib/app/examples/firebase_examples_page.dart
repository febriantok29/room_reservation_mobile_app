// Copyright 2025 The Room Reservation App Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/examples/firestore_crud_example_page.dart';
import 'package:room_reservation_mobile_app/app/examples/firestore_home_page.dart';
import 'package:room_reservation_mobile_app/app/examples/firestore_login_example_page.dart';
import 'package:room_reservation_mobile_app/app/examples/firestore_profile_example_page.dart';
import 'package:room_reservation_mobile_app/app/examples/firestore_register_example_page.dart';

/// Halaman contoh penggunaan Firebase Firestore
///
/// Halaman ini menyediakan akses ke berbagai contoh penggunaan Firebase Firestore
/// dalam aplikasi Room Reservation.
class FirebaseExamplesPage extends StatelessWidget {
  const FirebaseExamplesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Examples')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Intro text
          Text(
            'Firebase Firestore Examples',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Contoh-contoh ini menunjukkan bagaimana menggunakan Firebase Firestore '
            'untuk autentikasi dan operasi CRUD dalam aplikasi Room Reservation.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Authentication Examples
          _buildSectionTitle(context, 'Authentication Examples'),
          // Comprehensive Auth Example (commented out as it's still in development)
          // _buildExampleCard(
          //   context: context,
          //   title: 'Comprehensive Auth Example',
          //   description:
          //       'Contoh lengkap penggunaan FirestoreAuthService dengan fitur '
          //       'login, register, update profile, dan change password. '
          //       'Menggunakan pendekatan stream untuk real-time updates.',
          //   icon: Icons.security,
          //   onTap: () {
          //     // Navigator.push
          //   },
          // ),
          _buildExampleCard(
            context: context,
            title: 'Simple Login Example',
            description:
                'Contoh sederhana halaman login menggunakan FirestoreAuthService. '
                'Pendekatan sederhana tanpa stream.',
            icon: Icons.login,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FirestoreLoginExamplePage(),
                ),
              );
            },
          ),
          _buildExampleCard(
            context: context,
            title: 'Simple Register Example',
            description:
                'Contoh sederhana halaman registrasi pengguna baru '
                'menggunakan FirestoreAuthService.',
            icon: Icons.person_add,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FirestoreRegisterExamplePage(),
                ),
              );
            },
          ),
          _buildExampleCard(
            context: context,
            title: 'Profile Management Example',
            description:
                'Contoh halaman untuk melihat dan mengedit profil pengguna '
                'menggunakan FirestoreAuthService.',
            icon: Icons.account_circle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FirestoreProfileExamplePage(),
                ),
              );
            },
          ),
          _buildExampleCard(
            context: context,
            title: 'Home Page Example',
            description: 'Contoh halaman home dengan fitur logout.',
            icon: Icons.home,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FirestoreHomePage(),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // CRUD Examples
          _buildSectionTitle(context, 'CRUD Examples'),
          _buildExampleCard(
            context: context,
            title: 'Comprehensive CRUD Example',
            description:
                'Contoh lengkap operasi CRUD menggunakan FirestoreClient, '
                'termasuk query, batch operations, dan transactions.',
            icon: Icons.storage,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FirestoreCrudExamplePage(),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Additional Information
          _buildSectionTitle(context, 'Additional Information'),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Implementation Notes:'),
                  SizedBox(height: 8),
                  ListTile(
                    leading: Icon(Icons.info),
                    title: Text('FirestoreClient'),
                    subtitle: Text(
                      'Wrapper untuk Firestore API yang menyediakan '
                      'operasi CRUD dan query yang lebih mudah digunakan.',
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.security),
                    title: Text('FirestoreAuthService'),
                    subtitle: Text(
                      'Service untuk autentikasi user menggunakan '
                      'Firestore (bukan Firebase Auth) dengan fitur login, register, '
                      'profile management, dan session persistence.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build section title
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor),
      ),
    );
  }

  /// Build example card
  Widget _buildExampleCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: Icon(icon, size: 48, color: Theme.of(context).primaryColor),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}
