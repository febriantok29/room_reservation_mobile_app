import 'package:flutter_test/flutter_test.dart';
import 'package:room_reservation_mobile_app/app/utils/reservation_id_generator.dart';

void main() {
  group('ReservationIdGenerator', () {
    test('generateId should create correct format', () {
      final date = DateTime(2025, 1, 4);
      final id = ReservationIdGenerator.generateId(date: date, lastSequence: 0);

      expect(id, equals('RSV-20250104-01'));
    });

    test('generateId should increment sequence correctly', () {
      final date = DateTime(2025, 1, 4);
      final id1 = ReservationIdGenerator.generateId(
        date: date,
        lastSequence: 0,
      );
      final id2 = ReservationIdGenerator.generateId(
        date: date,
        lastSequence: 1,
      );
      final id3 = ReservationIdGenerator.generateId(
        date: date,
        lastSequence: 42,
      );

      expect(id1, equals('RSV-20250104-01'));
      expect(id2, equals('RSV-20250104-02'));
      expect(id3, equals('RSV-20250104-43'));
    });

    test('generateId should pad sequence with zeros', () {
      final date = DateTime(2025, 1, 4);
      final id = ReservationIdGenerator.generateId(date: date, lastSequence: 5);

      expect(id, equals('RSV-20250104-06'));
      expect(id.length, equals(15));
    });

    test('generateId should handle large sequence numbers', () {
      final date = DateTime(2025, 1, 4);
      final id = ReservationIdGenerator.generateId(
        date: date,
        lastSequence: 98,
      );

      expect(id, equals('RSV-20250104-99'));
    });

    test('generateId should throw error when exceeding max per day', () {
      final date = DateTime(2025, 1, 4);

      expect(
        () =>
            ReservationIdGenerator.generateId(date: date, lastSequence: 99),
        throwsException,
      );
    });

    test('isValidFormat should validate correct format', () {
      expect(ReservationIdGenerator.isValidFormat('RSV-20250104-01'), true);
      expect(ReservationIdGenerator.isValidFormat('RSV-20251231-99'), true);
    });

    test('isValidFormat should reject invalid formats', () {
      expect(
        ReservationIdGenerator.isValidFormat('RSV-20250104-001'),
        false,
      ); // Too long
      expect(
        ReservationIdGenerator.isValidFormat('RSV-2025010-01'),
        false,
      ); // Wrong date format
      expect(
        ReservationIdGenerator.isValidFormat('ABC-20250104-01'),
        false,
      ); // Wrong prefix
      expect(
        ReservationIdGenerator.isValidFormat('RSV2025010401'),
        false,
      ); // Missing separators
      expect(ReservationIdGenerator.isValidFormat(''), false); // Empty string
    });

    test('extractSequenceNumber should extract correct number', () {
      expect(
        ReservationIdGenerator.extractSequenceNumber('RSV-20250104-01'),
        equals(1),
      );
      expect(
        ReservationIdGenerator.extractSequenceNumber('RSV-20250104-42'),
        equals(42),
      );
      expect(
        ReservationIdGenerator.extractSequenceNumber('RSV-20250104-99'),
        equals(99),
      );
    });

    test('extractSequenceNumber should return 0 for invalid format', () {
      expect(
        ReservationIdGenerator.extractSequenceNumber('INVALID'),
        equals(0),
      );
      expect(ReservationIdGenerator.extractSequenceNumber(''), equals(0));
    });

    test('extractDate should extract correct date', () {
      final date = ReservationIdGenerator.extractDate('RSV-20250104-01');

      expect(date, isNotNull);
      expect(date!.year, equals(2025));
      expect(date.month, equals(1));
      expect(date.day, equals(4));
    });

    test('extractDate should return null for invalid format', () {
      expect(ReservationIdGenerator.extractDate('INVALID'), isNull);
      expect(ReservationIdGenerator.extractDate(''), isNull);
      expect(ReservationIdGenerator.extractDate('RSV-2025010-01'), isNull);
    });

    test('generateDatePrefixRange should create correct range', () {
      final date = DateTime(2025, 1, 4);
      final (today, tomorrow) = ReservationIdGenerator.generateDatePrefixRange(
        date,
      );

      expect(today, equals('RSV-20250104'));
      expect(tomorrow, equals('RSV-20250105'));
    });

    test('generateDatePrefixRange should handle month boundaries', () {
      final date = DateTime(2025, 1, 31);
      final (today, tomorrow) = ReservationIdGenerator.generateDatePrefixRange(
        date,
      );

      expect(today, equals('RSV-20250131'));
      expect(tomorrow, equals('RSV-20250201'));
    });

    test('generateDatePrefixRange should handle year boundaries', () {
      final date = DateTime(2025, 12, 31);
      final (today, tomorrow) = ReservationIdGenerator.generateDatePrefixRange(
        date,
      );

      expect(today, equals('RSV-20251231'));
      expect(tomorrow, equals('RSV-20260101'));
    });

    test('IDs should be sortable chronologically', () {
      final id1 = ReservationIdGenerator.generateId(
        date: DateTime(2025, 1, 1),
        lastSequence: 0,
      );
      final id2 = ReservationIdGenerator.generateId(
        date: DateTime(2025, 1, 2),
        lastSequence: 0,
      );
      final id3 = ReservationIdGenerator.generateId(
        date: DateTime(2025, 1, 2),
        lastSequence: 1,
      );

      final sorted = [id3, id1, id2]..sort();

      expect(sorted, equals([id1, id2, id3]));
    });

    test('Same day IDs should increment correctly', () {
      final date = DateTime(2025, 1, 4);
      final ids = List.generate(
        5,
        (index) =>
            ReservationIdGenerator.generateId(date: date, lastSequence: index),
      );

      expect(ids[0], equals('RSV-20250104-01'));
      expect(ids[1], equals('RSV-20250104-02'));
      expect(ids[2], equals('RSV-20250104-03'));
      expect(ids[3], equals('RSV-20250104-04'));
      expect(ids[4], equals('RSV-20250104-05'));
    });
  });
}
