import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/services/user_service.dart';

class UserSelectorBottomSheet extends StatefulWidget {
  final String? selectedUserId;

  const UserSelectorBottomSheet({super.key, this.selectedUserId});

  @override
  State<UserSelectorBottomSheet> createState() =>
      _UserSelectorBottomSheetState();

  /// Menampilkan bottom sheet untuk memilih user
  static Future<Profile?> show({
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
      builder: (_) => UserSelectorBottomSheet(selectedUserId: selectedUserId),
    );
  }
}

class _UserSelectorBottomSheetState extends State<UserSelectorBottomSheet> {
  String _searchKeyword = '';
  List<Profile> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  /// Load daftar pengguna
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Ambil semua pengguna
      final users = await UserService.getAllUsers();

      // Filter berdasarkan keyword jika ada
      if (_searchKeyword.isNotEmpty) {
        final keyword = _searchKeyword.toLowerCase();
        setState(() {
          _users = users.where((user) {
            final name = user.name.toLowerCase();
            final email = user.email?.toLowerCase() ?? '';
            final employeeId = user.employeeId?.toLowerCase() ?? '';
            return name.contains(keyword) ||
                email.contains(keyword) ||
                employeeId.contains(keyword);
          }).toList();
        });
      } else {
        setState(() {
          _users = users;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Pilih Pengguna',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          _buildSearchField(),
          Expanded(child: _buildUserList()),
        ],
      ),
    );
  }

  /// Widget search field
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
          setState(() {
            _searchKeyword = value;
          });
          _loadUsers();
        },
      ),
    );
  }

  /// Widget daftar pengguna
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
