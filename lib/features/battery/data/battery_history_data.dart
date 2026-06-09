/// Mock 7-day battery telemetry used by the battery history chart while the
/// real backend stream is being wired up. Each entry is "end-of-day" state.
class BatteryHistoryPoint {
  final String dayLabel; // Mon, Tue, ...
  final double chargePct; // 0-100, end-of-day battery state
  final double dischargedKwh; // energy drawn during the day
  final double runtimeHours; // active operating hours

  const BatteryHistoryPoint({
    required this.dayLabel,
    required this.chargePct,
    required this.dischargedKwh,
    required this.runtimeHours,
  });
}

class BatteryHistoryData {
  BatteryHistoryData._();

  static const List<BatteryHistoryPoint> last7Days = [
    BatteryHistoryPoint(dayLabel: 'Mon', chargePct: 92, dischargedKwh: 1.2, runtimeHours: 1.4),
    BatteryHistoryPoint(dayLabel: 'Tue', chargePct: 68, dischargedKwh: 2.1, runtimeHours: 2.6),
    BatteryHistoryPoint(dayLabel: 'Wed', chargePct: 84, dischargedKwh: 1.5, runtimeHours: 1.8),
    BatteryHistoryPoint(dayLabel: 'Thu', chargePct: 41, dischargedKwh: 3.4, runtimeHours: 4.1),
    BatteryHistoryPoint(dayLabel: 'Fri', chargePct: 73, dischargedKwh: 2.0, runtimeHours: 2.3),
    BatteryHistoryPoint(dayLabel: 'Sat', chargePct: 55, dischargedKwh: 2.8, runtimeHours: 3.5),
    BatteryHistoryPoint(dayLabel: 'Sun', chargePct: 78, dischargedKwh: 1.7, runtimeHours: 2.1),
  ];

  /// Convenience: pull just the y-values for a metric, in chart x-order.
  static List<double> chargeSeries() =>
      last7Days.map((p) => p.chargePct).toList(growable: false);

  static List<double> runtimeSeries() =>
      last7Days.map((p) => p.runtimeHours).toList(growable: false);
}
