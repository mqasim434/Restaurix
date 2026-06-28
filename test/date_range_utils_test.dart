import 'package:restaurix/core/utils/date_range_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('date range utils', () {
    test('today range covers local midnight boundaries', () {
      final now = DateTime(2024, 6, 21, 15, 30);
      final range = resolveSalesDateRange(
        preset: SalesDateRangePreset.today,
        now: now,
      );

      expect(range.startInclusive, DateTime(2024, 6, 21));
      expect(range.endExclusive, DateTime(2024, 6, 22));
      expect(range.contains(DateTime(2024, 6, 21, 0, 0)), isTrue);
      expect(range.contains(DateTime(2024, 6, 21, 23, 59, 59)), isTrue);
      expect(range.contains(DateTime(2024, 6, 22, 0, 0)), isFalse);
    });

    test('localDateBucket normalizes to local midnight', () {
      final bucket = localDateBucket(DateTime(2024, 6, 21, 18, 45));
      expect(bucket, DateTime(2024, 6, 21));
    });

    test('this week starts on Monday', () {
      final wednesday = DateTime(2024, 6, 19, 12);
      final range = resolveSalesDateRange(
        preset: SalesDateRangePreset.thisWeek,
        now: wednesday,
      );

      expect(range.startInclusive, DateTime(2024, 6, 17));
      expect(range.endExclusive, DateTime(2024, 6, 20));
    });

    test('custom range swaps inverted dates', () {
      final range = resolveSalesDateRange(
        preset: SalesDateRangePreset.custom,
        customStart: DateTime(2024, 6, 25),
        customEnd: DateTime(2024, 6, 20),
      );

      expect(range.startInclusive, DateTime(2024, 6, 25));
      expect(range.endExclusive, DateTime(2024, 6, 26));
    });
  });
}
