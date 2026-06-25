import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/services/user_service.dart';

class UserSelectorSection extends StatefulWidget {
  final String? selectedUserId;

  const UserSelectorSection({super.key, this.selectedUserId});

  @override
  State<UserSelectorSection> createState() => _UserSelectorSectionState();

  static Future<Profile?> showBottomSheet({
    required BuildContext context,
    String? selectedUserId,
  }) {
    return showModalBottomSheet<Profile>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => UserSelectorSection(selectedUserId: selectedUserId),
    );
  }

  static Future<Profile?> showPage({
    required BuildContext context,
    String? selectedUserId,
  }) {
    return Navigator.of(context).push<Profile>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Pilih Pengguna')),
          body: UserSelectorSection(selectedUserId: selectedUserId),
        ),
      ),
    );
  }
}

class _UserSelectorSectionState extends State<UserSelectorSection> {
  String _searchKeyword = '';
  List<Profile> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _debounceTimer;

  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _userService.getUsers(search: _searchKeyword);

      if (mounted) {
        setState(() {
          _users = users;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat pengguna: ${e.toString()}';
        });
      }

      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSearchField(),
          Expanded(child: _buildUserList()),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari pengguna...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
        ),
        onChanged: (value) {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 800), () {
            setState(() {
              _searchKeyword = value;
            });
            _loadUsers();
          });
        },
      ),
    );
  }

  Widget _buildUserList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_users.isEmpty) {
      return const Center(child: Text('Tidak ada pengguna ditemukan'));
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final isSelected = user.employeeId == widget.selectedUserId;

        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          color: isSelected ? Colors.blue.shade50 : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: isSelected
                ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop(user);
            },
            borderRadius: BorderRadius.circular(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name.isNotEmpty
                              ? user.name
                              : 'Nama tidak tersedia',
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (user.email != null) ...[
                          const SizedBox(height: 4.0),
                          Text(
                            user.email!,
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                        if (user.employeeId != null) ...[
                          const SizedBox(height: 4.0),
                          Text(
                            'ID: ${user.employeeId}',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
