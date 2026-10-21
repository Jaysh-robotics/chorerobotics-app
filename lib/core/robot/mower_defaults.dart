class MowerDefaults {
  const MowerDefaults({
    this.cutHeight = 65,
    this.pattern = 'straight',
    this.angle = 45,
    this.overlap = 10,
    this.enabled = true,
    this.days = const [1, 3, 5],
    this.hour = 8,
    this.minute = 0,
    this.zone = 'Front Yard',
  });

  final int cutHeight, angle, overlap, hour, minute;
  final String pattern, zone;
  final bool enabled;
  // Sunday = 0, matching the existing schedule protocol.
  final List<int> days;

  Map<String, dynamic> toJson() => {
    'cut_height_mm': cutHeight,
    'pattern': pattern,
    'stripe_angle_degrees': angle,
    'pass_overlap_percent': overlap,
    'schedule': {
      'enabled': enabled,
      'days': days,
      'hour': hour,
      'minute': minute,
      'zone_name': zone,
    },
  };

  factory MowerDefaults.fromJson(Map<String, dynamic> json) {
    final schedule = json['schedule'] as Map;
    final result = MowerDefaults(
      cutHeight: json['cut_height_mm'] as int,
      pattern: json['pattern'] as String,
      angle: json['stripe_angle_degrees'] as int,
      overlap: json['pass_overlap_percent'] as int,
      enabled: schedule['enabled'] as bool,
      days: List<int>.from(schedule['days'] as List),
      hour: schedule['hour'] as int,
      minute: schedule['minute'] as int,
      zone: schedule['zone_name'] as String,
    );
    if (result.cutHeight < 25 ||
        result.cutHeight > 100 ||
        result.angle < 0 ||
        result.angle > 180 ||
        result.overlap < 0 ||
        result.overlap > 30 ||
        result.hour < 0 ||
        result.hour > 23 ||
        result.minute < 0 ||
        result.minute > 59 ||
        ![
          'straight',
          'diagonal',
          'checker',
          'spiral',
        ].contains(result.pattern) ||
        !['Front Yard', 'Back Yard', 'Side Yard'].contains(result.zone) ||
        result.days.any((day) => day < 0 || day > 6) ||
        result.days.toSet().length != result.days.length ||
        (result.enabled && result.days.isEmpty)) {
      throw const FormatException('Invalid mower defaults');
    }
    return result;
  }
}
