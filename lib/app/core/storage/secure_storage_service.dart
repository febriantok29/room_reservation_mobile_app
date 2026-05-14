import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  Future<void> writeJson(String key, Map<String, dynamic> values) async {
    final stringValue = jsonEncode(values);
    await _storage.write(key: key, value: stringValue);
  }

  Future<Map<String, dynamic>?> readJson(String key) async {
    final stringValue = await _storage.read(key: key);

    if (stringValue == null) {
      return null;
    }

    try {
      final decodedValue = jsonDecode(stringValue);

      if (decodedValue is! Map<String, dynamic>) {
        return null;
      }

      return decodedValue;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeJsonList(String key, List<Map<String, dynamic>> values) {
    return _storage.write(key: key, value: jsonEncode(values));
  }

  Future<List<Map<String, dynamic>>?> readJsonList(String key) async {
    final stringValue = await _storage.read(key: key);

    if (stringValue == null) {
      return null;
    }

    try {
      final decodedValue = jsonDecode(stringValue);

      if (decodedValue is! List<Map<String, dynamic>>) {
        return null;
      }

      return decodedValue;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeTypedList<T>(String key, List<T> values) async {
    final stringValue = jsonEncode(values);
    await _storage.write(key: key, value: stringValue);
  }

  Future<List<T>?> readTypedList<T>(String key) async {
    final stringValue = await _storage.read(key: key);

    if (stringValue == null) {
      return null;
    }

    try {
      final decodedValue = jsonDecode(stringValue);

      if (decodedValue is! List<T>) {
        return null;
      }

      return decodedValue;
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }

  Future<void> deleteAll() {
    return _storage.deleteAll();
  }
}
