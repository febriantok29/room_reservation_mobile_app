# Reservation Status Flow - Full Automation System

## 📋 Overview

Sistem reservasi menggunakan **full automation** untuk status management. Tidak ada manual approval dari admin - reservasi yang pass CSP validation akan langsung dikonfirmasi otomatis.

**Peran Admin:** Support only (reschedule, cancel, extend) - bukan approver.

---

## 🔄 Status Flow Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                    USER SUBMIT RESERVATION                       │
│                              ↓                                   │
│                      CSP VALIDATION                              │
│                              ↓                                   │
│                    ✓ Pass Validation                             │
│                              ↓                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  STATUS: CONFIRMED                                        │   │
│  │  ────────────────────────────────────────────────────────  │   │
│  │  • Auto-approved (no manual approval needed)              │   │
│  │  • confirmedAt = now                                      │   │
│  │  • Menunggu waktu pelaksanaan                             │   │
│  │                                                            │   │
│  │  User can:  Cancel, Reschedule                            │   │
│  │  Admin can: Cancel, Reschedule, View                      │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              ↓                                   │
│              (30 minutes before startTime)                       │
│                              ↓                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  STATUS: UPCOMING                                         │   │
│  │  ────────────────────────────────────────────────────────  │   │
│  │  • Auto-transition when: now >= startTime - 30 minutes    │   │
│  │  • Segera dimulai dalam 30 menit                          │   │
│  │                                                            │   │
│  │  User can:  Cancel (urgent)                               │   │
│  │  Admin can: Cancel, View                                  │   │
│  │  Cannot:    Reschedule (too close to start)               │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              ↓                                   │
│                  (startTime reached)                             │
│                              ↓                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  STATUS: ONGOING                                          │   │
│  │  ────────────────────────────────────────────────────────  │   │
│  │  • Auto-transition when: now >= startTime                 │   │
│  │  • Reservasi sedang berlangsung                           │   │
│  │                                                            │   │
│  │  User can:  View only                                     │   │
│  │  Admin can: Extend (with CSP validation), Add notes       │   │
│  │  Cannot:    Cancel, Reschedule                            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              ↓                                   │
│                   (endTime reached)                              │
│                              ↓                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  STATUS: COMPLETED                                        │   │
│  │  ────────────────────────────────────────────────────────  │   │
│  │  • Auto-transition when: now >= endTime                   │   │
│  │  • Reservasi selesai                                      │   │
│  │  • Read-only                                              │   │
│  │                                                            │   │
│  │  User can:  View only                                     │   │
│  │  Admin can: View only                                     │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│                         OR                                       │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  STATUS: CANCELLED                                        │   │
│  │  ────────────────────────────────────────────────────────  │   │
│  │  • From: CONFIRMED or UPCOMING                            │   │
│  │  • Dibatalkan oleh user atau admin                        │   │
│  │  • cancellationReason required                            │   │
│  │  • cancelledAt = now                                      │   │
│  │  • cancelledBy = userId                                   │   │
│  │                                                            │   │
│  │  Read-only after cancelled                                │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📊 Status Transition Table

| From      | To        | Trigger                         | Auto/Manual | Who Can Do |
| --------- | --------- | ------------------------------- | ----------- | ---------- |
| -         | CONFIRMED | Submit + CSP valid              | Auto        | System     |
| CONFIRMED | UPCOMING  | 30 min before startTime         | Auto        | System     |
| CONFIRMED | CANCELLED | User/admin cancel               | Manual      | User/Admin |
| UPCOMING  | ONGOING   | startTime reached               | Auto        | System     |
| UPCOMING  | CANCELLED | User/admin cancel (urgent)      | Manual      | User/Admin |
| ONGOING   | COMPLETED | endTime reached                 | Auto        | System     |
| CANCELLED | -         | Cannot transition (final state) | -           | -          |
| COMPLETED | -         | Cannot transition (final state) | -           | -          |

---

## 🎯 Status Properties

### CONFIRMED

**Display:** "Terkonfirmasi"  
**Color:** Blue (#2196F3)  
**Description:** "Reservasi Anda sudah dikonfirmasi dan menunggu waktu pelaksanaan"

**Permissions:**

- ✅ Can be cancelled
- ✅ Can be rescheduled
- ❌ Cannot be extended

**Fields Set:**

```dart
confirmedAt: DateTime.now()
status: ReservationStatus.confirmed
```

---

### UPCOMING

**Display:** "Akan Segera Dimulai"  
**Color:** Orange (#FF9800)  
**Description:** "Reservasi akan segera dimulai dalam 30 menit"

**Permissions:**

- ✅ Can be cancelled (urgent)
- ❌ Cannot be rescheduled (too close)
- ❌ Cannot be extended

**Auto-transition:**

```dart
if (now >= startTime - 30 minutes) {
  status = UPCOMING
}
```

---

### ONGOING

**Display:** "Sedang Berlangsung"  
**Color:** Green (#4CAF50)  
**Description:** "Reservasi sedang berlangsung"

**Permissions:**

- ❌ Cannot be cancelled
- ❌ Cannot be rescheduled
- ✅ Can be extended (admin only, with CSP check)

**Auto-transition:**

```dart
if (now >= startTime) {
  status = ONGOING
}
```

---

### COMPLETED

**Display:** "Selesai"  
**Color:** Grey (#9E9E9E)  
**Description:** "Reservasi telah selesai"

**Permissions:**

- ❌ Cannot be modified (read-only)

**Auto-transition:**

```dart
if (now >= endTime) {
  status = COMPLETED
}
```

---

### CANCELLED

**Display:** "Dibatalkan"  
**Color:** Red (#F44336)  
**Description:** "Reservasi telah dibatalkan"

**Permissions:**

- ❌ Cannot be modified (final state)

**Fields Set:**

```dart
status: ReservationStatus.cancelled
cancellationReason: String (required)
cancelledAt: DateTime.now()
cancelledBy: userId
```

---

## 🛠️ Implementation Details

### Auto-Status Update (On-Demand)

**When:** Saat user buka app / fetch reservation list

```dart
Future<List<Reservation>> getReservationList(...) async {
  // ... fetch from Firestore ...

  for (final reservation in reservations) {
    // Auto-update status based on current time
    final updatedReservation = reservation.updateStatusIfNeeded();

    // If status changed, update in Firestore
    if (updatedReservation.status != reservation.status) {
      await updateReservationStatus(
        updatedReservation.id!,
        updatedReservation.status,
      );
    }
  }

  return reservations;
}
```

**Logic:**

```dart
ReservationStatus getComputedStatus() {
  if (status == ReservationStatus.cancelled) {
    return ReservationStatus.cancelled;
  }

  final now = DateTime.now();

  // COMPLETED: endTime passed
  if (endTime != null && endTime!.isBefore(now)) {
    return ReservationStatus.completed;
  }

  // ONGOING: startTime reached
  if (startTime != null && startTime!.isBefore(now)) {
    return ReservationStatus.ongoing;
  }

  // UPCOMING: 30 min before start
  if (startTime != null) {
    final diff = startTime!.difference(now);
    if (diff.inMinutes <= 30 && diff.inMinutes >= 0) {
      return ReservationStatus.upcoming;
    }
  }

  // Default: CONFIRMED
  return ReservationStatus.confirmed;
}
```

---

## 👤 User Actions

### 1. Cancel Reservation

**Available for:** CONFIRMED, UPCOMING

```dart
Future<void> cancelReservation(String reservationId, String reason) async {
  final reservation = await getReservationById(reservationId);

  if (!reservation.status.canBeCancelled) {
    throw Exception(
      'Reservasi dengan status ${reservation.status.displayName} tidak dapat dibatalkan'
    );
  }

  final cancelled = reservation.cancel(reason, currentUserId);
  await updateReservation(cancelled);
}
```

---

### 2. Reschedule Reservation (User)

**Available for:** CONFIRMED only

```dart
Future<void> rescheduleReservation(
  String reservationId,
  DateTime newStart,
  DateTime newEnd,
) async {
  final reservation = await getReservationById(reservationId);

  if (!reservation.status.canBeRescheduled) {
    throw Exception(
      'Reservasi dengan status ${reservation.status.displayName} tidak dapat di-reschedule'
    );
  }

  // CSP Validation for new time
  final tempReservation = reservation.copyWith(
    startDateTime: newStart,
    endDateTime: newEnd,
  );

  final cspResult = await validateReservationWithCSP(tempReservation);

  if (!cspResult.isValid) {
    // Show error + alternatives
    throw ValidationException('CSP validation failed');
  }

  final rescheduled = reservation.reschedule(
    newStart,
    newEnd,
    'User rescheduled',
  );

  await updateReservation(rescheduled);
}
```

---

## 👨‍💼 Admin Actions

### 1. Reschedule Reservation (Admin)

**Available for:** CONFIRMED only  
**Same as user reschedule** but admin can add notes

```dart
Future<void> adminRescheduleReservation(
  String reservationId,
  DateTime newStart,
  DateTime newEnd,
  String adminNote,
) async {
  // Same CSP validation as user
  // ...

  final rescheduled = reservation.reschedule(
    newStart,
    newEnd,
    adminNote, // Admin can add custom note
  );

  await updateReservation(rescheduled);
}
```

---

### 2. Extend Reservation (Admin Only)

**Available for:** ONGOING only  
**Critical:** Must validate with CSP to prevent conflicts

```dart
Future<void> extendReservation(
  String reservationId,
  DateTime newEndTime,
  String reason,
) async {
  final reservation = await getReservationById(reservationId);

  if (!reservation.status.canBeExtended) {
    throw Exception(
      'Reservasi dengan status ${reservation.status.displayName} tidak dapat di-extend'
    );
  }

  // CRITICAL: CSP validation untuk waktu tambahan
  // Cek apakah ada reservasi lain yang bentrok
  final tempReservation = reservation.copyWith(
    endDateTime: newEndTime,
  );

  final cspResult = await validateReservationWithCSP(tempReservation);

  if (!cspResult.isValid) {
    // Ada conflict dengan reservasi lain
    String errorMessage = 'Tidak dapat memperpanjang waktu:\n\n';

    for (final violation in cspResult.violations) {
      errorMessage += '• $violation\n';
    }

    throw ValidationException(errorMessage);
  }

  // CSP passed, safe to extend
  final extended = reservation.extend(newEndTime, reason);
  await updateReservation(extended);
}
```

**Example Scenario:**

```
Original: 09:00 - 12:00
Admin wants to extend to: 12:30

CSP checks:
- Is there a reservation starting at 12:15? → CONFLICT!
- Is there a reservation starting at 12:45? → OK, can extend to 12:30

If conflict:
  Show error: "Ada reservasi lain di ruangan ini jam 12:15"
  Suggest: "Maksimal perpanjangan sampai jam 12:14"

If no conflict:
  Allow extension
  Save: originalEndTime = 12:00, endTime = 12:30, wasExtended = true
```

---

## 📊 Tracking Fields

### Fields Added to Reservation Model

```dart
// Status tracking
final ReservationStatus status;
final DateTime? confirmedAt;

// Cancellation tracking
final String? cancellationReason;
final DateTime? cancelledAt;
final String? cancelledBy;

// Modification tracking
final DateTime? originalEndTime;  // Saved when extended
final bool wasRescheduled;         // True if ever rescheduled
final bool wasExtended;            // True if ever extended
final String? adminNotes;          // Admin notes for any action
```

### Usage Example

```dart
// Check if reservation was modified
if (reservation.wasRescheduled) {
  print('This reservation was rescheduled');
}

if (reservation.wasExtended) {
  print('Original end time: ${reservation.originalEndTime}');
  print('Extended end time: ${reservation.endTime}');
}

// Track cancellations
if (reservation.status == ReservationStatus.cancelled) {
  print('Cancelled by: ${reservation.cancelledBy}');
  print('Reason: ${reservation.cancellationReason}');
  print('At: ${reservation.cancelledAt}');
}
```

---

## 🎨 UI Display Examples

### Status Badge

```dart
Widget buildStatusBadge(Reservation reservation) {
  final status = reservation.status;

  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Color(int.parse(status.colorHex.substring(1), radix: 16) + 0xFF000000),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      status.displayName,
      style: TextStyle(color: Colors.white, fontSize: 12),
    ),
  );
}
```

### Action Buttons

```dart
Widget buildActionButtons(Reservation reservation) {
  return Row(
    children: [
      // Cancel button
      if (reservation.status.canBeCancelled)
        ElevatedButton(
          onPressed: () => _cancelReservation(reservation),
          child: Text('Batalkan'),
        ),

      // Reschedule button
      if (reservation.status.canBeRescheduled)
        ElevatedButton(
          onPressed: () => _rescheduleReservation(reservation),
          child: Text('Reschedule'),
        ),

      // Extend button (admin only)
      if (reservation.status.canBeExtended && isAdmin)
        ElevatedButton(
          onPressed: () => _extendReservation(reservation),
          child: Text('Perpanjang'),
        ),
    ],
  );
}
```

---

## 🔔 Notifications (Future Enhancement)

### Push Notifications

**1 Day Before:**

```
"Besok ada reservasi di ${room.name}"
"Jam ${startTime} - ${endTime}"
"Tap untuk melihat detail"
```

**30 Minutes Before (UPCOMING status):**

```
"Reservasi Anda 30 menit lagi dimulai"
"${room.name} - Jam ${startTime}"
"Jangan lupa hadir!"
```

**On Start (ONGOING status):**

```
"Reservasi Anda sudah dimulai"
"${room.name} - sampai jam ${endTime}"
```

---

## 📈 Analytics & Reports

### Admin Dashboard

**Statistics to Track:**

```dart
class ReservationStats {
  final int totalConfirmed;
  final int totalUpcoming;
  final int totalOngoing;
  final int totalCompleted;
  final int totalCancelled;

  final int totalRescheduled;
  final int totalExtended;

  final double cancellationRate; // cancelled / total
  final double completionRate;   // completed / total
}
```

**Useful Queries:**

- Reservations by status
- Cancellation reasons (top 5)
- Most rescheduled users
- Most extended rooms
- Average meeting duration
- Peak hours analysis

---

## ✅ Summary

**Key Features:**

1. ✅ **Full Automation** - No manual approval needed
2. ✅ **CSP Integration** - Only valid reservations are confirmed
3. ✅ **Auto Status Transitions** - Based on time (on-demand)
4. ✅ **Admin as Support** - Can reschedule, cancel, extend
5. ✅ **Extension with CSP** - Prevent conflicts when extending
6. ✅ **Complete Tracking** - All actions recorded with timestamps
7. ✅ **User-Friendly** - Clear status messages and colors

**No:**

- ❌ NO manual approval workflow
- ❌ NO "pending" status waiting for admin
- ❌ NO "rejected" status
- ❌ NO "no-show" tracking (meeting can be delegated)

**Perfect for:** Modern self-service room booking with intelligent automation! 🚀

---

**Document Version**: 1.0  
**Last Updated**: 2024-11-07  
**Status**: Implemented & Ready
