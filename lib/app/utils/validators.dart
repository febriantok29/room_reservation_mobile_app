typedef FieldValidator = String? Function(String?);

class Validators {
  Validators._();

  static FieldValidator required([String? fieldName]) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return '${fieldName ?? 'Kolom ini'} tidak boleh kosong';
      }
      return null;
    };
  }

  static FieldValidator minLength(int length, [String? fieldName]) {
    return (value) {
      if (value != null && value.trim().length < length) {
        return '${fieldName ?? 'Kolom ini'} minimal $length karakter';
      }
      return null;
    };
  }

  static FieldValidator maxLength(int length, [String? fieldName]) {
    return (value) {
      if (value != null && value.trim().length > length) {
        return '${fieldName ?? 'Kolom ini'} maksimal $length karakter';
      }
      return null;
    };
  }

  static FieldValidator email() {
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return (value) {
      if (value != null && value.trim().isNotEmpty && !pattern.hasMatch(value.trim())) {
        return 'Format email tidak valid';
      }
      return null;
    };
  }

  static FieldValidator compose(List<FieldValidator> validators) {
    return (value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}
