enum UserRole {
  admin,
  user;

  static UserRole? get(dynamic value) {
    final stValue = value?.toString().toLowerCase();

    if (stValue == null || stValue.isEmpty) {
      return null;
    }

    for (final role in UserRole.values) {
      if (role.name.toLowerCase() == stValue) {
        return role;
      }
    }

    return null;
  }

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.user:
        return 'User';
    }
  }
}
