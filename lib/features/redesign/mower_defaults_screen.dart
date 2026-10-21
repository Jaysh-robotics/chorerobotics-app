import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/robot/mower_defaults.dart';
import '../../core/robot/robot_command_client.dart';
import 'chore_ui.dart';

class MowerDefaultsScreen extends StatefulWidget {
  const MowerDefaultsScreen({super.key});
  @override
  State<MowerDefaultsScreen> createState() => _MowerDefaultsScreenState();
}

class _MowerDefaultsScreenState extends State<MowerDefaultsScreen> {
  late MowerDefaults _draft;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  Timer? _timeout;
  String? _readId, _saveId, _error;
  bool _saving = false, _edited = false;
  int _height = 65, _angle = 45, _overlap = 10;
  String _pattern = 'straight', _zone = 'Front Yard';
  bool _enabled = true;
  Set<int> _days = {1, 3, 5};
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    final client = context.read<RobotCommandClient>();
    _load(client.mowerDefaults);
    _subscription = client.messages.listen(_onMessage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _readId = client.getMowerDefaults();
    });
  }

  void _load(MowerDefaults value) {
    _height = value.cutHeight;
    _angle = value.angle;
    _overlap = value.overlap;
    _pattern = value.pattern;
    _zone = value.zone;
    _enabled = value.enabled;
    _days = value.days.toSet();
    _time = TimeOfDay(hour: value.hour, minute: value.minute);
  }

  void _onMessage(Map<String, dynamic> message) {
    final p = message['payload'];
    if (message['type'] != 'command_ack' || p is! Map) return;
    final id = p['command_id'];
    if (id == null || (id != _saveId && id != _readId)) return;
    if (id == _readId) {
      _readId = null;
      if (p['status'] == 'accepted' && p['defaults'] is Map) {
        try {
          final value = MowerDefaults.fromJson(
            Map<String, dynamic>.from(p['defaults']),
          );
          context.read<RobotCommandClient>().mowerDefaults = value;
          if (!_edited) setState(() => _load(value));
        } catch (_) {
          setState(() => _error = 'Invalid defaults received from robot.');
        }
      }
      return;
    }
    _timeout?.cancel();
    _saveId = null;
    if (p['status'] == 'accepted') {
      context.read<RobotCommandClient>().mowerDefaults = _draft;
      context.go('/setup-ready/mower?confirmed=true');
    } else {
      setState(() {
        _saving = false;
        final message = p['message']?.toString();
        _error = message?.startsWith('unknown_type:') == true
            ? 'Robot server needs updating. Rebuild the Docker container, reconnect, then Save again.'
            : message ?? 'Save rejected.';
      });
    }
  }

  void _save() {
    if (_enabled && _days.isEmpty) {
      setState(() => _error = 'Select at least one scheduling day.');
      return;
    }
    _draft = MowerDefaults(
      cutHeight: _height,
      pattern: _pattern,
      angle: _angle,
      overlap: _overlap,
      enabled: _enabled,
      days: _days.toList()..sort(),
      hour: _time.hour,
      minute: _time.minute,
      zone: _zone,
    );
    final client = context.read<RobotCommandClient>();
    if (!client.isConnected) {
      client.mowerDefaults = _draft;
      context.go('/setup-ready/mower?confirmed=false');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    _saveId = client.saveMowerDefaults(_draft);
    _timeout = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _saveId = null;
          _saving = false;
          _error = 'Save not confirmed. Check connection and try again.';
        });
      }
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  void _change(VoidCallback change) => setState(() {
    _edited = true;
    change();
  });

  Widget _panel(Widget child) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: choreSurface,
      border: Border.all(color: choreBorder),
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );

  Widget _slider(
    String label,
    int value,
    int min,
    int max,
    String unit,
    String hint,
    ValueChanged<int> update,
  ) => _panel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: choreText(16))),
            Text('$value$unit', style: choreText(11)),
          ],
        ),
        SizedBox(
          height: 30,
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: 'Decrease $label',
                  iconSize: 14,
                  icon: const Icon(Icons.remove),
                  onPressed: value <= min
                      ? null
                      : () => _change(() => update(value - 1)),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    tickMarkShape: const RoundSliderTickMarkShape(
                      tickMarkRadius: 0,
                    ),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 4,
                    ),
                  ),
                  child: Slider(
                    label: label,
                    value: value.toDouble(),
                    min: min.toDouble(),
                    max: max.toDouble(),
                    divisions: max - min,
                    activeColor: choreOrange,
                    inactiveColor: const Color(0xFF353538),
                    thumbColor: Colors.white,
                    onChanged: (v) => _change(() => update(v.round())),
                  ),
                ),
              ),
              SizedBox(
                width: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: 'Increase $label',
                  iconSize: 14,
                  icon: const Icon(Icons.add),
                  onPressed: value >= max
                      ? null
                      : () => _change(() => update(value + 1)),
                ),
              ),
            ],
          ),
        ),
        Text(hint, style: choreText(9, color: choreMuted)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ChoreFrame(
    title: 'Chore Mower Defaults',
    back: '/connect-attachment/mower',
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 20),
      child: AbsorbPointer(
        absorbing: _saving,
        child: Column(
          children: [
            _slider(
              'Cutting Height',
              _height,
              25,
              100,
              ' mm',
              'Range from Attachment: 25-100 mm',
              (v) => _height = v,
            ),
            _panel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mowing Pattern', style: choreText(16)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final pattern in [
                        'straight',
                        'diagonal',
                        'checker',
                        'spiral',
                      ])
                        ChoiceChip(
                          label: Text(
                            '${pattern[0].toUpperCase()}${pattern.substring(1)}',
                          ),
                          selected: _pattern == pattern,
                          labelStyle: choreText(10),
                          selectedColor: choreOrange,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          showCheckmark: false,
                          onSelected: (_) => _change(() => _pattern = pattern),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            _slider(
              'Stripe Angle',
              _angle,
              0,
              180,
              '',
              '0-180',
              (v) => _angle = v,
            ),
            _slider(
              'Pass Overlap',
              _overlap,
              0,
              30,
              '%',
              '0-30%',
              (v) => _overlap = v,
            ),
            _panel(
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Scheduling', style: choreText(16))),
                      SizedBox(
                        height: 36,
                        child: Switch(
                          value: _enabled,
                          activeThumbColor: Colors.white,
                          activeTrackColor: choreOrange,
                          onChanged: (v) => _change(() => _enabled = v),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      for (var day = 0; day < 7; day++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: SizedBox(
                              height: 42,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  backgroundColor: _days.contains(day)
                                      ? choreOrange
                                      : choreSurface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    side: const BorderSide(color: choreBorder),
                                  ),
                                ),
                                onPressed: !_enabled
                                    ? null
                                    : () => _change(() {
                                        if (!_days.add(day)) _days.remove(day);
                                      }),
                                child: Semantics(
                                  selected: _days.contains(day),
                                  label: const [
                                    'Sunday',
                                    'Monday',
                                    'Tuesday',
                                    'Wednesday',
                                    'Thursday',
                                    'Friday',
                                    'Saturday',
                                  ][day],
                                  child: Text(
                                    'SMTWTFS'[day],
                                    style: choreText(11),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: !_enabled
                              ? null
                              : () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: _time,
                                  );
                                  if (picked != null && mounted) {
                                    _change(() => _time = picked);
                                  }
                                },
                          child: Text(
                            '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                            style: choreText(10),
                          ),
                        ),
                      ),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _zone,
                          isExpanded: true,
                          style: choreText(10),
                          underline: const SizedBox.shrink(),
                          items: [
                            for (final zone in [
                              'Front Yard',
                              'Back Yard',
                              'Side Yard',
                            ])
                              DropdownMenuItem(value: zone, child: Text(zone)),
                          ],
                          onChanged: !_enabled
                              ? null
                              : (v) => _change(() => _zone = v!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_error != null)
              Text(_error!, style: choreText(12, color: Colors.orange)),
            const SizedBox(height: 12),
            ChorePill(
              _saving ? 'Saving...' : 'Save',
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    ),
  );
}
