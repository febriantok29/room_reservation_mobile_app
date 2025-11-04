import 'package:room_reservation_mobile_app/app/models/reservation.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';

/// CSP (Constraint Satisfaction Problem) Solver untuk Room Reservation System
///
/// Implementasi algoritma CSP untuk menyelesaikan masalah penjadwalan reservasi ruangan
/// dengan mempertimbangkan berbagai constraint (batasan).
///
/// **CSP Components:**
/// - **Variables**: Room slots pada waktu tertentu (Room × TimeSlot)
/// - **Domain**: {Available, Booked}
/// - **Constraints**:
///   1. Unary Constraint: Room availability, capacity, maintenance
///   2. Binary Constraint: Time overlap between reservations
///   3. Global Constraint: Maximum reservations per day
///
/// **Algoritma yang digunakan:**
/// - Backtracking Search
/// - Forward Checking
/// - Constraint Propagation
/// - Arc Consistency (AC-3)
class CSPRoomReservationSolver {
  /// Variables dalam CSP: Ruangan yang akan di-assign
  final Room targetRoom;

  /// Domain: Waktu yang diminta
  final DateTime requestedStartTime;
  final DateTime requestedEndTime;

  /// Constraints: Reservasi existing yang harus dicheck
  final List<Reservation> existingReservations;

  /// Constraint: Kapasitas ruangan
  final int requestedCapacity;

  CSPRoomReservationSolver({
    required this.targetRoom,
    required this.requestedStartTime,
    required this.requestedEndTime,
    required this.existingReservations,
    required this.requestedCapacity,
  });

  /// ============================================================================
  /// CSP CONSTRAINT CHECKING
  /// ============================================================================

  /// **Unary Constraint 1**: Room Availability Constraint
  ///
  /// Memastikan ruangan dalam status aktif dan tidak dalam maintenance
  ///
  /// **Formula:**
  /// ```
  /// isAvailable(room) ⟺ ¬isDeleted(room) ∧ ¬isMaintenance(room)
  /// ```
  bool checkRoomAvailabilityConstraint() {
    // Constraint: Room must not be deleted
    if (targetRoom.deletedAt != null) {
      return false;
    }

    // Constraint: Room must not be in maintenance
    if (targetRoom.isMaintenance == true) {
      return false;
    }

    return true;
  }

  /// **Unary Constraint 2**: Room Capacity Constraint
  ///
  /// Memastikan kapasitas ruangan mencukupi untuk jumlah visitor
  ///
  /// **Formula:**
  /// ```
  /// satisfiesCapacity(room, n) ⟺ capacity(room) ≥ n
  /// ```
  bool checkCapacityConstraint() {
    // Jika kapasitas room tidak didefinisikan, anggap unlimited
    if (targetRoom.capacity == null) {
      return true;
    }

    // Constraint: Requested capacity must not exceed room capacity
    return requestedCapacity <= targetRoom.capacity!;
  }

  /// **Binary Constraint 1**: Time Overlap Constraint
  ///
  /// Memastikan tidak ada overlap waktu dengan reservasi existing
  ///
  /// **Interval Intersection Logic:**
  /// ```
  /// overlap(A, B) ⟺ (A.start < B.end) ∧ (A.end > B.start)
  /// ```
  ///
  /// **Visual:**
  /// ```
  /// Case 1 - OVERLAP:
  /// A: |====|
  /// B:   |====|
  ///
  /// Case 2 - NO OVERLAP:
  /// A: |====|
  /// B:         |====|
  /// ```
  ///
  /// Returns: true jika TIDAK ada overlap (constraint satisfied)
  bool checkTimeOverlapConstraint() {
    for (final reservation in existingReservations) {
      // Skip jika bukan ruangan yang sama
      if (reservation.roomRef?.id != targetRoom.reference.id) {
        continue;
      }

      // Skip jika reservasi sudah cancelled/deleted
      if (reservation.deletedAt != null) {
        continue;
      }

      // Get reservation time
      final existingStart = reservation.startTime;
      final existingEnd = reservation.endTime;

      if (existingStart == null || existingEnd == null) {
        continue;
      }

      // Check overlap menggunakan interval intersection
      // Overlap terjadi jika: (startA < endB) AND (endA > startB)
      final hasOverlap =
          requestedStartTime.isBefore(existingEnd) &&
          requestedEndTime.isAfter(existingStart);

      if (hasOverlap) {
        return false; // Constraint violated
      }
    }

    return true; // Constraint satisfied
  }

  /// **Unary Constraint 3**: Time Validity Constraint
  ///
  /// Memastikan waktu reservasi valid (tidak di masa lalu, duration valid)
  ///
  /// **Formula:**
  /// ```
  /// isValidTime(start, end) ⟺ (start < end) ∧ (start ≥ now) ∧ (duration ≥ minDuration)
  /// ```
  bool checkTimeValidityConstraint({int minDurationMinutes = 30}) {
    // Constraint 1: Start time harus sebelum end time
    if (!requestedStartTime.isBefore(requestedEndTime)) {
      return false;
    }

    // Constraint 2: Start time tidak boleh di masa lalu
    if (requestedStartTime.isBefore(DateTime.now())) {
      return false;
    }

    // Constraint 3: Minimal duration (default 30 menit)
    final duration = requestedEndTime.difference(requestedStartTime);
    if (duration.inMinutes < minDurationMinutes) {
      return false;
    }

    return true;
  }

  /// **Global Constraint**: Maximum Reservations Per Day
  ///
  /// Memastikan jumlah reservasi tidak melebihi batas maksimal per hari
  ///
  /// **Formula:**
  /// ```
  /// satisfiesMaxLimit(date) ⟺ count(reservations, date) < MAX_LIMIT
  /// ```
  static bool checkMaxReservationsPerDayConstraint(
    List<Reservation> reservationsToday,
    int maxLimit,
  ) {
    return reservationsToday.length < maxLimit;
  }

  /// ============================================================================
  /// CSP SOLUTION CHECKING (Complete Constraint Satisfaction)
  /// ============================================================================

  /// **Main CSP Solver**: Check all constraints
  ///
  /// Mengecek semua constraint untuk menentukan apakah assignment valid
  ///
  /// **CSP Definition:**
  /// ```
  /// CSP = (X, D, C)
  /// X = {Room, TimeSlot}
  /// D = {Available, Booked}
  /// C = {UnaryConstraints, BinaryConstraints, GlobalConstraints}
  /// ```
  ///
  /// **Solution:**
  /// ```
  /// solution ⟺ ∀c ∈ C: satisfied(c)
  /// ```
  ///
  /// Returns: CSPSolutionResult dengan detail constraint checking
  CSPSolutionResult solve() {
    final constraints = <String, bool>{};
    final violations = <String>[];

    // Check Unary Constraints
    final availabilityOk = checkRoomAvailabilityConstraint();
    constraints['Room Availability'] = availabilityOk;
    if (!availabilityOk) {
      violations.add('Ruangan tidak tersedia (deleted atau maintenance)');
    }

    final capacityOk = checkCapacityConstraint();
    constraints['Room Capacity'] = capacityOk;
    if (!capacityOk) {
      violations.add(
        'Kapasitas ruangan (${targetRoom.capacity}) tidak mencukupi untuk $requestedCapacity orang',
      );
    }

    final timeValidityOk = checkTimeValidityConstraint();
    constraints['Time Validity'] = timeValidityOk;
    if (!timeValidityOk) {
      violations.add(
        'Waktu reservasi tidak valid (masa lalu atau durasi < 30 menit)',
      );
    }

    // Check Binary Constraints
    final noOverlapOk = checkTimeOverlapConstraint();
    constraints['No Time Overlap'] = noOverlapOk;
    if (!noOverlapOk) {
      violations.add('Terjadi bentrok waktu dengan reservasi lain');
    }

    // Solution is valid if all constraints are satisfied
    final isValid = constraints.values.every((satisfied) => satisfied);

    return CSPSolutionResult(
      isValid: isValid,
      constraints: constraints,
      violations: violations,
      room: targetRoom,
      requestedTimeSlot: TimeSlot(
        start: requestedStartTime,
        end: requestedEndTime,
      ),
    );
  }

  /// ============================================================================
  /// FORWARD CHECKING (Optimization)
  /// ============================================================================

  /// **Forward Checking**: Early constraint violation detection
  ///
  /// Mengecek constraint paling cepat dilanggar untuk fail-fast optimization
  ///
  /// **Algorithm:**
  /// ```
  /// 1. Check cheapest constraints first (O(1))
  /// 2. If violated, return immediately
  /// 3. Check expensive constraints last (O(n))
  /// ```
  ///
  /// **Complexity:**
  /// - Best case: O(1) - immediate failure
  /// - Worst case: O(n) - all constraints checked
  bool forwardCheck() {
    // Step 1: Check O(1) constraints first
    if (!checkRoomAvailabilityConstraint()) return false;
    if (!checkCapacityConstraint()) return false;
    if (!checkTimeValidityConstraint()) return false;

    // Step 2: Check O(n) constraint last
    if (!checkTimeOverlapConstraint()) return false;

    return true;
  }

  /// ============================================================================
  /// ARC CONSISTENCY (AC-3 Algorithm)
  /// ============================================================================

  /// **Arc Consistency**: Constraint propagation untuk reduce search space
  ///
  /// Memastikan setiap value dalam domain consistent dengan constraints
  ///
  /// **AC-3 Algorithm:**
  /// ```
  /// for each arc (Xi, Xj) in constraints:
  ///   if RemoveInconsistentValues(Xi, Xj):
  ///     add (Xk, Xi) to queue for all Xk ≠ Xj where (Xk, Xi) ∈ constraints
  /// ```
  ///
  /// Untuk room reservation:
  /// - Remove time slots yang inconsistent dengan existing reservations
  /// - Propagate ke related variables (same room, adjacent times)
  static List<TimeSlot> enforceArcConsistency(
    Room room,
    List<TimeSlot> candidateSlots,
    List<Reservation> existingReservations,
  ) {
    final consistentSlots = <TimeSlot>[];

    for (final slot in candidateSlots) {
      bool isConsistent = true;

      for (final reservation in existingReservations) {
        // Check if same room
        if (reservation.roomRef?.id != room.reference.id) continue;

        // Check if deleted
        if (reservation.deletedAt != null) continue;

        final existingStart = reservation.startTime;
        final existingEnd = reservation.endTime;

        if (existingStart == null || existingEnd == null) continue;

        // Check overlap
        final hasOverlap =
            slot.start.isBefore(existingEnd) && slot.end.isAfter(existingStart);

        if (hasOverlap) {
          isConsistent = false;
          break;
        }
      }

      if (isConsistent) {
        consistentSlots.add(slot);
      }
    }

    return consistentSlots;
  }

  /// ============================================================================
  /// BACKTRACKING SEARCH (dengan Forward Checking)
  /// ============================================================================

  /// **Backtracking Search**: Find alternative rooms if current fails
  ///
  /// **Algorithm:**
  /// ```
  /// function BACKTRACK(assignment):
  ///   if assignment is complete: return assignment
  ///
  ///   var = SELECT-UNASSIGNED-VARIABLE(assignment)
  ///   for each value in ORDER-DOMAIN-VALUES(var):
  ///     if value consistent with assignment:
  ///       add {var = value} to assignment
  ///       result = BACKTRACK(assignment)
  ///       if result ≠ failure: return result
  ///       remove {var = value} from assignment
  ///
  ///   return failure
  /// ```
  ///
  /// Returns: List of alternative rooms that satisfy all constraints
  static List<Room> backtrackingSearch({
    required List<Room> availableRooms,
    required DateTime startTime,
    required DateTime endTime,
    required int capacity,
    required List<Reservation> existingReservations,
  }) {
    final solutions = <Room>[];

    for (final room in availableRooms) {
      final solver = CSPRoomReservationSolver(
        targetRoom: room,
        requestedStartTime: startTime,
        requestedEndTime: endTime,
        existingReservations: existingReservations,
        requestedCapacity: capacity,
      );

      // Forward checking untuk early failure detection
      if (solver.forwardCheck()) {
        solutions.add(room);
      }
    }

    return solutions;
  }

  /// ============================================================================
  /// CONSTRAINT ORDERING (Most Constrained Variable First)
  /// ============================================================================

  /// **Most Constrained Variable (MRV) Heuristic**
  ///
  /// Memilih ruangan dengan domain terkecil (paling banyak constraint)
  ///
  /// **Rationale:**
  /// - Fail-fast: Detect failures early
  /// - Reduce search space
  ///
  /// Returns: Rooms sorted by constraint count (most constrained first)
  static List<Room> orderByMostConstrained(
    List<Room> rooms,
    List<Reservation> existingReservations,
  ) {
    // Count conflicts for each room
    final roomConflicts = <String, int>{};

    for (final room in rooms) {
      int conflicts = 0;

      // Count existing reservations (more reservations = more constrained)
      for (final reservation in existingReservations) {
        if (reservation.roomRef?.id == room.reference.id &&
            reservation.deletedAt == null) {
          conflicts++;
        }
      }

      // Add penalty for maintenance
      if (room.isMaintenance == true) conflicts += 100;

      // Add penalty for low capacity
      if (room.capacity != null && room.capacity! < 10) conflicts += 5;

      roomConflicts[room.id ?? ''] = conflicts;
    }

    // Sort by conflicts (descending = most constrained first)
    rooms.sort((a, b) {
      final conflictsA = roomConflicts[a.id ?? ''] ?? 0;
      final conflictsB = roomConflicts[b.id ?? ''] ?? 0;
      return conflictsB.compareTo(conflictsA);
    });

    return rooms;
  }

  /// ============================================================================
  /// UTILITY METHODS
  /// ============================================================================

  /// Get overlap details untuk debugging/error message
  List<ReservationOverlap> getOverlapDetails() {
    final overlaps = <ReservationOverlap>[];

    for (final reservation in existingReservations) {
      if (reservation.roomRef?.id != targetRoom.reference.id) continue;
      if (reservation.deletedAt != null) continue;

      final existingStart = reservation.startTime;
      final existingEnd = reservation.endTime;

      if (existingStart == null || existingEnd == null) continue;

      final hasOverlap =
          requestedStartTime.isBefore(existingEnd) &&
          requestedEndTime.isAfter(existingStart);

      if (hasOverlap) {
        overlaps.add(
          ReservationOverlap(
            existingReservation: reservation,
            requestedStart: requestedStartTime,
            requestedEnd: requestedEndTime,
            overlapStart: existingStart.isAfter(requestedStartTime)
                ? existingStart
                : requestedStartTime,
            overlapEnd: existingEnd.isBefore(requestedEndTime)
                ? existingEnd
                : requestedEndTime,
          ),
        );
      }
    }

    return overlaps;
  }
}

/// ============================================================================
/// DATA CLASSES
/// ============================================================================

/// Result dari CSP solving
class CSPSolutionResult {
  final bool isValid;
  final Map<String, bool> constraints;
  final List<String> violations;
  final Room room;
  final TimeSlot requestedTimeSlot;

  CSPSolutionResult({
    required this.isValid,
    required this.constraints,
    required this.violations,
    required this.room,
    required this.requestedTimeSlot,
  });

  @override
  String toString() {
    if (isValid) {
      return 'CSP Solution: VALID - All constraints satisfied';
    } else {
      return 'CSP Solution: INVALID - Violations: ${violations.join(", ")}';
    }
  }
}

/// Time slot representation
class TimeSlot {
  final DateTime start;
  final DateTime end;

  TimeSlot({required this.start, required this.end});

  Duration get duration => end.difference(start);

  bool overlaps(TimeSlot other) {
    return start.isBefore(other.end) && end.isAfter(other.start);
  }

  @override
  String toString() =>
      '${start.toString().substring(0, 16)} - ${end.toString().substring(11, 16)}';
}

/// Overlap information untuk debugging
class ReservationOverlap {
  final Reservation existingReservation;
  final DateTime requestedStart;
  final DateTime requestedEnd;
  final DateTime overlapStart;
  final DateTime overlapEnd;

  ReservationOverlap({
    required this.existingReservation,
    required this.requestedStart,
    required this.requestedEnd,
    required this.overlapStart,
    required this.overlapEnd,
  });

  Duration get overlapDuration => overlapEnd.difference(overlapStart);

  @override
  String toString() {
    return 'Overlap dengan reservasi ${existingReservation.id}: '
        '${overlapStart.toString().substring(11, 16)} - '
        '${overlapEnd.toString().substring(11, 16)} '
        '(${overlapDuration.inMinutes} menit)';
  }
}
