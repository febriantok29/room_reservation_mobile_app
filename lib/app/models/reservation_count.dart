/// Model untuk jumlah reservasi berdasarkan status
class ReservationCount {
  /// Jumlah reservasi yang aktif (approved dan belum selesai)
  final int active;

  /// Jumlah reservasi yang pending (menunggu approval)
  final int pending;

  /// Jumlah reservasi yang sudah selesai
  final int completed;

  const ReservationCount({
    required this.active,
    required this.pending,
    required this.completed,
  });

  /// Factory constructor untuk membuat instance dengan nilai default (semua 0)
  factory ReservationCount.empty() {
    return const ReservationCount(active: 0, pending: 0, completed: 0);
  }

  /// Total semua reservasi
  int get total => active + pending + completed;

  /// Copy with method untuk membuat instance baru dengan beberapa field yang diubah
  ReservationCount copyWith({int? active, int? pending, int? completed}) {
    return ReservationCount(
      active: active ?? this.active,
      pending: pending ?? this.pending,
      completed: completed ?? this.completed,
    );
  }

  @override
  String toString() {
    return 'ReservationCount(active: $active, pending: $pending, completed: $completed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ReservationCount &&
        other.active == active &&
        other.pending == pending &&
        other.completed == completed;
  }

  @override
  int get hashCode {
    return active.hashCode ^ pending.hashCode ^ completed.hashCode;
  }
}
