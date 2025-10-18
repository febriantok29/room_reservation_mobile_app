// Copyright 2025 The Room Reservation App Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Mixin untuk membantu pengecekan mounted pada operasi async
mixin MountedStateMixin<T extends StatefulWidget> on State<T> {
  /// Menjalankan setState hanya jika widget masih mounted
  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  /// Cek apakah operasi async dapat dilanjutkan
  /// Return false jika widget tidak lagi mounted
  bool get canContinue => mounted;
}
