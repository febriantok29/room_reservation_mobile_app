// // Copyright 2025 The Room Reservation App Authors
// // Use of this source code is governed by a BSD-style license that can be
// // found in the LICENSE file.
//
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:room_reservation_mobile_app/app/models/profile.dart';
// import 'package:room_reservation_mobile_app/app/services/firestore_service/firestore_auth_service.dart';
// import 'package:room_reservation_mobile_app/app/utils/mounted_state_mixin.dart';
//
// /// Contoh penggunaan FirestoreAuthService
// ///
// /// Contoh ini menunjukkan bagaimana menggunakan FirestoreAuthService untuk:
// /// 1. Register user baru
// /// 2. Login user
// /// 3. Mendapatkan user yang sedang login
// /// 4. Logout user
// /// 5. Update profile user
// /// 6. Mengganti password user
// class FirestoreAuthExamplePage extends StatefulWidget {
//   const FirestoreAuthExamplePage({super.key});
//
//   @override
//   State<FirestoreAuthExamplePage> createState() =>
//       _FirestoreAuthExamplePageState();
// }
//
// class _FirestoreAuthExamplePageState extends State<FirestoreAuthExamplePage>
//     with MountedStateMixin {
//   // Auth service
//   late final Future<FirestoreAuthService> _authService =
//       FirestoreAuthService.getInstance();
//
//   // Form controllers
//   final _usernameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _nameController = TextEditingController();
//
//   // Current user
//   Profile? _currentUser;
//
//   // Status
//   bool _isLoading = false;
//   String _statusMessage = '';
//
//   // Stream subscription untuk auth state changes
//   StreamSubscription? _authStateSubscription;
//
//   // Tab management akan dihandle oleh DefaultTabController
//
//   @override
//   void initState() {
//     super.initState();
//     _initAuth();
//   }
//
//   /// Inisialisasi auth service
//   Future<void> _initAuth() async {
//     setState(() {
//       _isLoading = true;
//       _statusMessage = 'Menginisialisasi auth service...';
//     });
//
//     try {
//       // Get auth service instance
//       final authService = await _authService;
//
//       // Listen for auth state changes
//       _authStateSubscription = authService.authStateChanges.listen((state) {
//         if (mounted) {
//           setState(() {
//             _statusMessage = state.message ?? 'Status berubah: ${state.status}';
//           });
//
//           // Refresh user data when auth state changes
//           _refreshUserData();
//         }
//       });
//
//       // Get current user
//       await _refreshUserData();
//     } catch (e) {
//       setState(() {
//         _statusMessage = 'Error: ${e.toString()}';
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   /// Refresh user data
//   Future<void> _refreshUserData() async {
//     if (!mounted) return;
//
//     try {
//       final authService = await _authService;
//       final user = await authService.getCurrentUser();
//
//       if (mounted) {
//         setState(() {
//           _currentUser = user;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error refreshing user data: $e');
//     }
//   }
//
//   /// Register new user
//   Future<void> _register() async {
//     if (!mounted) return;
//
//     // Validate form
//     final name = _nameController.text.trim();
//     final email = _emailController.text.trim();
//     final username = _usernameController.text.trim();
//     final password = _passwordController.text.trim();
//
//     if (name.isEmpty || email.isEmpty || username.isEmpty || password.isEmpty) {
//       if (mounted) {
//         setState(() {
//           _statusMessage = 'Semua field harus diisi';
//         });
//       }
//       return;
//     }
//
//     if (mounted) {
//       setState(() {
//         _isLoading = true;
//         _statusMessage = 'Mendaftarkan user baru...';
//       });
//     }
//
//     try {
//       final authService = await _authService;
//
//       await authService.register(
//         name: name,
//         email: email,
//         username: username,
//         password: password,
//       );
//
//       if (mounted) {
//         setState(() {
//           _statusMessage = 'Registrasi berhasil';
//         });
//
//         // Clear form
//         _nameController.clear();
//         _emailController.clear();
//         _usernameController.clear();
//         _passwordController.clear();
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _statusMessage = 'Error registrasi: ${e.toString()}';
//         });
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   /// Login user
//   Future<void> _login() async {
//     if (!mounted) return;
//
//     // Validate form
//     final credential = _usernameController.text.trim();
//     final password = _passwordController.text.trim();
//
//     if (credential.isEmpty || password.isEmpty) {
//       if (mounted) {
//         setState(() {
//           _statusMessage = 'Username/email dan password harus diisi';
//         });
//       }
//       return;
//     }
//
//     if (mounted) {
//       setState(() {
//         _isLoading = true;
//         _statusMessage = 'Melakukan login...';
//       });
//     }
//
//     try {
//       final authService = await _authService;
//
//       final user = await authService.login(
//         credential: credential,
//         password: password,
//       );
//
//       if (mounted) {
//         setState(() {
//           _currentUser = user;
//           _statusMessage = 'Login berhasil';
//         });
//
//         // Clear form
//         _usernameController.clear();
//         _passwordController.clear();
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _statusMessage = 'Error login: ${e.toString()}';
//         });
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   /// Logout user
//   Future<void> _logout() async {
//     if (!mounted) return;
//
//     setState(() {
//       _isLoading = true;
//       _statusMessage = 'Melakukan logout...';
//     });
//
//     try {
//       final authService = await _authService;
//       await authService.logout();
//
//       if (mounted) {
//         setState(() {
//           _currentUser = null;
//           _statusMessage = 'Logout berhasil';
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _statusMessage = 'Error logout: ${e.toString()}';
//         });
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   /// Update profile
//   Future<void> _updateProfile() async {
//     if (!mounted) return;
//
//     // Validate form
//     final name = _nameController.text.trim();
//     final email = _emailController.text.trim();
//     final username = _usernameController.text.trim();
//
//     if (name.isEmpty || email.isEmpty || username.isEmpty) {
//       if (mounted) {
//         setState(() {
//           _statusMessage = 'Nama, email, dan username harus diisi';
//         });
//       }
//       return;
//     }
//
//     if (_currentUser == null) {
//       if (mounted) {
//         setState(() {
//           _statusMessage = 'Tidak ada user yang login';
//         });
//       }
//       return;
//     }
//
//     if (mounted) {
//       setState(() {
//         _isLoading = true;
//         _statusMessage = 'Mengupdate profile...';
//       });
//     }
//
//     try {
//       // Parse name into first and last name
//       final nameParts = name.split(' ');
//       final firstName = nameParts.first;
//       final lastName = nameParts.length > 1
//           ? nameParts.sublist(1).join(' ')
//           : '';
//
//       final authService = await _authService;
//
//       final updatedProfile = Profile(
//         id: _currentUser!.id,
//         firstName: firstName,
//         lastName: lastName,
//         email: email,
//         username: username,
//         role: _currentUser!.role,
//       );
//
//       final result = await authService.updateProfile(updatedProfile);
//
//       if (mounted) {
//         setState(() {
//           if (result) {
//             _statusMessage = 'Profile berhasil diupdate';
//             _currentUser = updatedProfile;
//           } else {
//             _statusMessage = 'Gagal mengupdate profile';
//           }
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _statusMessage = 'Error update profile: ${e.toString()}';
//         });
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   /// Change password
//   Future<void> _changePassword() async {
//     if (!mounted) return;
//
//     // Validate form
//     final currentPassword = _usernameController.text
//         .trim(); // Reusing field for current password
//     final newPassword = _passwordController.text.trim();
//
//     if (currentPassword.isEmpty || newPassword.isEmpty) {
//       if (mounted) {
//         setState(() {
//           _statusMessage = 'Current password dan new password harus diisi';
//         });
//       }
//       return;
//     }
//
//     if (mounted) {
//       setState(() {
//         _isLoading = true;
//         _statusMessage = 'Mengganti password...';
//       });
//     }
//
//     try {
//       final authService = await _authService;
//
//       final result = await authService.changePassword(
//         currentPassword,
//         newPassword,
//       );
//
//       if (mounted) {
//         setState(() {
//           if (result) {
//             _statusMessage = 'Password berhasil diubah';
//
//             // Clear form
//             _usernameController.clear();
//             _passwordController.clear();
//           } else {
//             _statusMessage = 'Gagal mengubah password';
//           }
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _statusMessage = 'Error mengganti password: ${e.toString()}';
//         });
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Firestore Auth Example')),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 // Status message
//                 if (_statusMessage.isNotEmpty)
//                   Container(
//                     color: Colors.blue.shade50,
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(8.0),
//                     child: Text(
//                       _statusMessage,
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                   ),
//
//                 // Current user
//                 Card(
//                   margin: const EdgeInsets.all(8.0),
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Current User',
//                           style: Theme.of(context).textTheme.headlineSmall,
//                         ),
//                         const Divider(),
//                         if (_currentUser != null) ...[
//                           Text(
//                             'Name: ${_currentUser!.firstName} ${_currentUser!.lastName}',
//                           ),
//                           Text('Username: ${_currentUser!.username}'),
//                           Text('Email: ${_currentUser!.email}'),
//                           Text('Role: ${_currentUser!.role}'),
//                           const SizedBox(height: 16),
//                           ElevatedButton(
//                             onPressed: _logout,
//                             child: const Text('Logout'),
//                           ),
//                         ] else
//                           const Text('No user logged in'),
//                       ],
//                     ),
//                   ),
//                 ),
//
//                 // Tabs
//                 DefaultTabController(
//                   length: 4,
//                   child: Expanded(
//                     child: Column(
//                       children: [
//                         TabBar(
//                           onTap: (index) {
//                             setState(() {
//                               // Clear controllers when switching tabs
//                               _nameController.clear();
//                               _emailController.clear();
//                               _usernameController.clear();
//                               _passwordController.clear();
//
//                               // Populate controllers for update profile
//                               if (index == 2 && _currentUser != null) {
//                                 _nameController.text =
//                                     '${_currentUser!.firstName} ${_currentUser!.lastName}';
//                                 _emailController.text =
//                                     _currentUser!.email ?? '';
//                                 _usernameController.text =
//                                     _currentUser!.username ?? '';
//                               }
//                             });
//                           },
//                           tabs: const [
//                             Tab(text: 'Register'),
//                             Tab(text: 'Login'),
//                             Tab(text: 'Update'),
//                             Tab(text: 'Password'),
//                           ],
//                         ),
//                         Expanded(
//                           child: TabBarView(
//                             children: [
//                               // Register
//                               _buildRegisterForm(),
//
//                               // Login
//                               _buildLoginForm(),
//
//                               // Update Profile
//                               _buildUpdateProfileForm(),
//
//                               // Change Password
//                               _buildChangePasswordForm(),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//     );
//   }
//
//   /// Build register form
//   Widget _buildRegisterForm() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Register New User',
//             style: Theme.of(context).textTheme.headlineSmall,
//           ),
//           const SizedBox(height: 16),
//           TextField(
//             controller: _nameController,
//             decoration: const InputDecoration(
//               labelText: 'Full Name',
//               border: OutlineInputBorder(),
//             ),
//           ),
//           const SizedBox(height: 8),
//           TextField(
//             controller: _emailController,
//             decoration: const InputDecoration(
//               labelText: 'Email',
//               border: OutlineInputBorder(),
//             ),
//             keyboardType: TextInputType.emailAddress,
//           ),
//           const SizedBox(height: 8),
//           TextField(
//             controller: _usernameController,
//             decoration: const InputDecoration(
//               labelText: 'Username',
//               border: OutlineInputBorder(),
//             ),
//           ),
//           const SizedBox(height: 8),
//           TextField(
//             controller: _passwordController,
//             decoration: const InputDecoration(
//               labelText: 'Password',
//               border: OutlineInputBorder(),
//             ),
//             obscureText: true,
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: _register,
//               child: const Text('Register'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// Build login form
//   Widget _buildLoginForm() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Login', style: Theme.of(context).textTheme.headlineSmall),
//           const SizedBox(height: 16),
//           TextField(
//             controller: _usernameController,
//             decoration: const InputDecoration(
//               labelText: 'Username or Email',
//               border: OutlineInputBorder(),
//             ),
//           ),
//           const SizedBox(height: 8),
//           TextField(
//             controller: _passwordController,
//             decoration: const InputDecoration(
//               labelText: 'Password',
//               border: OutlineInputBorder(),
//             ),
//             obscureText: true,
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: _login,
//               child: const Text('Login'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// Build update profile form
//   Widget _buildUpdateProfileForm() {
//     final isLoggedIn = _currentUser != null;
//
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Update Profile',
//             style: Theme.of(context).textTheme.headlineSmall,
//           ),
//           const SizedBox(height: 16),
//           if (!isLoggedIn)
//             const Text('You must be logged in to update profile')
//           else ...[
//             TextField(
//               controller: _nameController,
//               decoration: const InputDecoration(
//                 labelText: 'Full Name',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _emailController,
//               decoration: const InputDecoration(
//                 labelText: 'Email',
//                 border: OutlineInputBorder(),
//               ),
//               keyboardType: TextInputType.emailAddress,
//             ),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _usernameController,
//               decoration: const InputDecoration(
//                 labelText: 'Username',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: isLoggedIn ? _updateProfile : null,
//                 child: const Text('Update Profile'),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   /// Build change password form
//   Widget _buildChangePasswordForm() {
//     final isLoggedIn = _currentUser != null;
//
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Change Password',
//             style: Theme.of(context).textTheme.headlineSmall,
//           ),
//           const SizedBox(height: 16),
//           if (!isLoggedIn)
//             const Text('You must be logged in to change password')
//           else ...[
//             TextField(
//               controller: _usernameController,
//               decoration: const InputDecoration(
//                 labelText: 'Current Password',
//                 border: OutlineInputBorder(),
//               ),
//               obscureText: true,
//             ),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _passwordController,
//               decoration: const InputDecoration(
//                 labelText: 'New Password',
//                 border: OutlineInputBorder(),
//               ),
//               obscureText: true,
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: isLoggedIn ? _changePassword : null,
//                 child: const Text('Change Password'),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     // Cancel auth state subscription to prevent setState after dispose
//     _authStateSubscription?.cancel();
//
//     // Clean up AuthService resources if needed
//     _authService
//         .then((service) {
//           // No need to call service.dispose() as it's a singleton
//           // Just cancel our subscription which we already did above
//         })
//         .catchError((_) {
//           // Ignore any errors during cleanup
//         });
//
//     // Dispose controllers
//     _nameController.dispose();
//     _emailController.dispose();
//     _usernameController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
// }
