/// Model untuk statistik yang ditampilkan di home page
class HomeStatistics {
  /// Jumlah ruangan yang tersedia (tidak maintenance, tidak deleted)
  final int availableRooms;

  /// Jumlah reservasi yang aktif (approved dan belum selesai)
  final int activeReservations;

  /// Jumlah reservasi yang pending (menunggu approval)
  final int pendingReservations;

  /// Jumlah reservasi yang sudah selesai
  final int completedReservations;

  const HomeStatistics({
    required this.availableRooms,
    required this.activeReservations,
    required this.pendingReservations,
    this.completedReservations = 0,
  });

  /// Factory constructor untuk membuat instance dengan nilai default (semua 0)
  factory HomeStatistics.empty() {
    return const HomeStatistics(
      availableRooms: 0,
      activeReservations: 0,
      pendingReservations: 0,
      completedReservations: 0,
    );
  }

  /// Copy with method untuk membuat instance baru dengan beberapa field yang diubah
  HomeStatistics copyWith({
    int? availableRooms,
    int? activeReservations,
    int? pendingReservations,
    int? completedReservations,
  }) {
    return HomeStatistics(
      availableRooms: availableRooms ?? this.availableRooms,
      activeReservations: activeReservations ?? this.activeReservations,
      pendingReservations: pendingReservations ?? this.pendingReservations,
      completedReservations:
          completedReservations ?? this.completedReservations,
    );
  }

  @override
  String toString() {
    return 'HomeStatistics(availableRooms: $availableRooms, activeReservations: $activeReservations, pendingReservations: $pendingReservations, completedReservations: $completedReservations)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HomeStatistics &&
        other.availableRooms == availableRooms &&
        other.activeReservations == activeReservations &&
        other.pendingReservations == pendingReservations &&
        other.completedReservations == completedReservations;
  }

  @override
  int get hashCode {
    return availableRooms.hashCode ^
        activeReservations.hashCode ^
        pendingReservations.hashCode ^
        completedReservations.hashCode;
  }
}
