/// Shared date-range and bucketing helpers for Sales (Module 22) and Reports
/// (Module 23). All calculations use the device local timezone.
library;

enum SalesDateRangePreset {
  today,
  thisWeek,
  thisMonth,
  custom,
}

class SalesDateRange {
  const SalesDateRange({
    required this.preset,
    required this.startInclusive,
    required this.endExclusive,
    this.customStart,
    this.customEnd,
  });

  final SalesDateRangePreset preset;
  final DateTime startInclusive;
  final DateTime endExclusive;
  final DateTime? customStart;
  final DateTime? customEnd;

  bool contains(DateTime instant) {
    return !instant.isBefore(startInclusive) && instant.isBefore(endExclusive);
  }
}

/// Normalizes [instant] to local midnight for consistent daily bucketing.
DateTime localDateBucket(DateTime instant) {
  final local = instant.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Inclusive start, exclusive end — midnight boundaries in local time.
DateTime startOfLocalDay(DateTime day) {
  final bucket = localDateBucket(day);
  return DateTime(bucket.year, bucket.month, bucket.day);
}

DateTime endOfLocalDayExclusive(DateTime day) {
  final start = startOfLocalDay(day);
  return start.add(const Duration(days: 1));
}

/// ISO week — Monday is the first day of the week.
DateTime startOfLocalWeek(DateTime day) {
  final bucket = localDateBucket(day);
  final weekdayOffset = bucket.weekday - DateTime.monday;
  return bucket.subtract(Duration(days: weekdayOffset));
}

DateTime startOfLocalMonth(DateTime day) {
  final bucket = localDateBucket(day);
  return DateTime(bucket.year, bucket.month);
}

DateTime endOfLocalMonthExclusive(DateTime day) {
  final start = startOfLocalMonth(day);
  return DateTime(start.year, start.month + 1);
}

SalesDateRange resolveSalesDateRange({
  required SalesDateRangePreset preset,
  DateTime? customStart,
  DateTime? customEnd,
  DateTime? now,
}) {
  final anchor = now ?? DateTime.now();
  final todayStart = startOfLocalDay(anchor);

  return switch (preset) {
    SalesDateRangePreset.today => SalesDateRange(
        preset: preset,
        startInclusive: todayStart,
        endExclusive: endOfLocalDayExclusive(anchor),
      ),
    SalesDateRangePreset.thisWeek => SalesDateRange(
        preset: preset,
        startInclusive: startOfLocalWeek(anchor),
        endExclusive: endOfLocalDayExclusive(anchor),
      ),
    SalesDateRangePreset.thisMonth => SalesDateRange(
        preset: preset,
        startInclusive: startOfLocalMonth(anchor),
        endExclusive: endOfLocalDayExclusive(anchor),
      ),
    SalesDateRangePreset.custom => _resolveCustomRange(
        customStart: customStart,
        customEnd: customEnd,
      ),
  };
}

SalesDateRange _resolveCustomRange({
  DateTime? customStart,
  DateTime? customEnd,
}) {
  final start = customStart ?? DateTime.now();
  final end = customEnd ?? start;
  final normalizedStart = startOfLocalDay(start);
  final normalizedEnd = startOfLocalDay(end.isBefore(start) ? start : end);

  return SalesDateRange(
    preset: SalesDateRangePreset.custom,
    startInclusive: normalizedStart,
    endExclusive: endOfLocalDayExclusive(normalizedEnd),
    customStart: normalizedStart,
    customEnd: normalizedEnd,
  );
}

String salesDateRangeLabel(SalesDateRange range) {
  String format(DateTime value) {
    return '${value.month}/${value.day}/${value.year}';
  }

  return switch (range.preset) {
    SalesDateRangePreset.today => 'Today',
    SalesDateRangePreset.thisWeek => 'This week',
    SalesDateRangePreset.thisMonth => 'This month',
    SalesDateRangePreset.custom =>
      '${format(range.customStart ?? range.startInclusive)} – '
          '${format(range.customEnd ?? range.endExclusive.subtract(const Duration(days: 1)))}',
  };
}

enum TrendGranularity {
  daily,
  weekly,
  monthly,
  yearly,
}

/// Buckets [instant] to the start of its trend period in local time.
DateTime trendBucketStart(DateTime instant, TrendGranularity granularity) {
  final local = localDateBucket(instant);

  return switch (granularity) {
    TrendGranularity.daily => local,
    TrendGranularity.weekly => startOfLocalWeek(local),
    TrendGranularity.monthly => startOfLocalMonth(local),
    TrendGranularity.yearly => DateTime(local.year),
  };
}

DateTime trendBucketEndExclusive(
  DateTime bucketStart,
  TrendGranularity granularity,
) {
  return switch (granularity) {
    TrendGranularity.daily => bucketStart.add(const Duration(days: 1)),
    TrendGranularity.weekly => bucketStart.add(const Duration(days: 7)),
    TrendGranularity.monthly =>
      DateTime(bucketStart.year, bucketStart.month + 1),
    TrendGranularity.yearly => DateTime(bucketStart.year + 1),
  };
}

String trendBucketLabel(DateTime bucketStart, TrendGranularity granularity) {
  return switch (granularity) {
    TrendGranularity.daily =>
      '${bucketStart.month}/${bucketStart.day}/${bucketStart.year}',
    TrendGranularity.weekly =>
      'Week of ${bucketStart.month}/${bucketStart.day}/${bucketStart.year}',
    TrendGranularity.monthly =>
      '${_monthName(bucketStart.month)} ${bucketStart.year}',
    TrendGranularity.yearly => '${bucketStart.year}',
  };
}

String _monthName(int month) {
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return names[month - 1];
}

Iterable<DateTime> iterateTrendBuckets({
  required SalesDateRange range,
  required TrendGranularity granularity,
}) sync* {
  var cursor = trendBucketStart(range.startInclusive, granularity);
  final end = range.endExclusive;

  while (cursor.isBefore(end)) {
    yield cursor;
    cursor = trendBucketEndExclusive(cursor, granularity);
  }
}
