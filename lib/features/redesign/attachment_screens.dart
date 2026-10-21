import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/robot/robot_command_client.dart';
import 'chore_ui.dart';

class ChoreAttachment {
  const ChoreAttachment(
    this.id,
    this.name,
    this.readyWidth,
    this.readyHeight,
    this.readyTop,
  );
  final String id, name;
  final double readyWidth, readyHeight, readyTop;
}

const choreAttachments = [
  ChoreAttachment('mower', 'Chore Mower', 244, 163, 282),
  ChoreAttachment('trimmer', 'Chore Trimmer', 307, 230, 246),
  ChoreAttachment('irrigator', 'Chore Irrigator', 275, 206, 233),
  ChoreAttachment('collector', 'Chore Collector', 273, 182, 271),
  ChoreAttachment('blower', 'Chore Blower', 264, 176, 263),
  ChoreAttachment('plow', 'Chore Plow', 284, 151, 290),
  ChoreAttachment('patrol', 'Chore Patrol', 255, 257, 192),
];

ChoreAttachment? findAttachment(String id) {
  for (final item in choreAttachments) {
    if (item.id == id) return item;
  }
  return null;
}

class AttachmentSelectionScreen extends StatelessWidget {
  const AttachmentSelectionScreen({super.key});
  @override
  Widget build(BuildContext context) => ChoreFrame(
    title: 'Select Attachment',
    body: GridView.builder(
      padding: const EdgeInsets.fromLTRB(29, 9, 27, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 148,
      ),
      itemCount: choreAttachments.length + 1,
      itemBuilder: (context, index) {
        final attachment = choreAttachments[index == 7 ? 5 : index];
        return Semantics(
          button: true,
          label: attachment.name,
          child: Material(
            clipBehavior: Clip.antiAlias,
            color: const Color(0xFF0B0C0C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: choreBorder),
            ),
            child: InkWell(
              onTap: () => context.go('/connect-attachment/${attachment.id}'),
              child: Stack(
                children: [
                  if (index != 7)
                    Positioned(
                      top: 3,
                      left: 1,
                      right: 1,
                      height: 120,
                      child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            Colors.white,
                            Colors.transparent,
                          ],
                          stops: [0, .68, 1],
                        ).createShader(bounds),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: index == 0
                              ? LayoutBuilder(
                                  builder: (context, constraints) => ClipRect(
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: -constraints.maxWidth * .0698,
                                          top: -13,
                                          width: constraints.maxWidth * 1.0833,
                                          height: 130,
                                          child: Image.asset(
                                            '${flowAssets}mower-card.png',
                                            fit: BoxFit.fill,
                                            filterQuality: FilterQuality.high,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Image.asset(
                                  '$flowAssets${attachment.id}-card.png',
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.high,
                                ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 10,
                    left: 12,
                    right: 8,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                attachment.name,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF5F5F7),
                                ),
                              ),
                              Text(
                                'Ready',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: Color(0xFF2EDB7D),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 21,
                          height: 21,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SvgPicture.asset(
                                '${flowAssets}play-ring.svg',
                                width: 21,
                                height: 21,
                              ),
                              const Icon(
                                Icons.play_arrow,
                                color: choreOrange,
                                size: 15,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class AttachmentSetupScreen extends StatefulWidget {
  const AttachmentSetupScreen({super.key});
  @override
  State<AttachmentSetupScreen> createState() => _AttachmentSetupScreenState();
}

class _AttachmentSetupScreenState extends State<AttachmentSetupScreen> {
  bool? _manual;
  @override
  Widget build(BuildContext context) => ChoreFrame(
    title: 'Attachment Setup',
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 31),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 0, 22),
              child: Text(
                'How would you like to add your attachment?',
                style: choreText(12, weight: FontWeight.w200),
              ),
            ),
            _option('Auto Detect', 'Robot Identifies it for you', false),
            const SizedBox(height: 12),
            _option('Manual Select', 'Pick from the attachment list', true),
            const SizedBox(height: 21),
            Center(
              child: ChorePill(
                'Continue',
                onPressed: () {
                  if (_manual == true) {
                    context.go('/attachments');
                  } else {
                    context.go('/connect-attachment/mower?mode=auto');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _option(String title, String subtitle, bool manual) => Material(
    color: choreSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: _manual == manual ? choreOrange : choreBorder),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _manual = manual),
      child: Container(
        height: 82,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: choreText(18, weight: FontWeight.w500)),
            Text(subtitle, style: choreText(12, weight: FontWeight.w200)),
          ],
        ),
      ),
    ),
  );
}

class ConnectAttachmentScreen extends StatefulWidget {
  const ConnectAttachmentScreen({
    super.key,
    required this.attachmentId,
    this.autoDetect = false,
  });
  final String attachmentId;
  final bool autoDetect;
  @override
  State<ConnectAttachmentScreen> createState() =>
      _ConnectAttachmentScreenState();
}

class _ConnectAttachmentScreenState extends State<ConnectAttachmentScreen> {
  final _serial = TextEditingController();
  StreamSubscription<Map<String, dynamic>>? _subscription;
  Timer? _timeout;
  Timer? _retryTimer;
  bool _retrying = false;
  String? _commandId, _error;
  bool _confirmed = false;
  bool _waiting = true;
  late String _attachmentId = widget.attachmentId;

  @override
  void initState() {
    super.initState();
    _subscription = context.read<RobotCommandClient>().messages.listen(
      _onMessage,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _request();
    });
    _retryTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_confirmed && !_waiting) _retry();
    });
  }

  Future<void> _retry() async {
    if (_retrying) return;
    _retrying = true;
    try {
      final client = context.read<RobotCommandClient>();
      if (!client.isConnected) await client.connect();
      if (mounted) _request();
    } finally {
      _retrying = false;
    }
  }

  void _request() {
    _timeout?.cancel();
    final client = context.read<RobotCommandClient>();
    setState(() {
      _confirmed = false;
      _error = null;
      _waiting = true;
    });
    _commandId = widget.autoDetect
        ? client.sendAttachmentDetect()
        : client.sendAttachmentSelected(
            _attachmentId,
            supported: true,
            serialNumber: _serial.text.trim(),
          );
    if (_commandId != null) {
      _timeout = Timer(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            _commandId = null;
            _waiting = false;
            _error = 'No acknowledgement. Tap Retry.';
          });
        }
      });
    } else {
      setState(() => _waiting = false);
    }
  }

  void _onMessage(Map<String, dynamic> message) {
    final payload = message['payload'];
    if (message['type'] != 'command_ack' ||
        payload is! Map ||
        _commandId == null ||
        payload['command_id'] != _commandId) {
      return;
    }
    _timeout?.cancel();
    _retryTimer?.cancel();
    setState(() {
      _waiting = false;
      _confirmed = payload['status'] == 'accepted';
      if (widget.autoDetect && _confirmed) {
        final detected = payload['attachment']?.toString();
        _confirmed = detected != null && findAttachment(detected) != null;
        if (_confirmed) _attachmentId = detected!;
      }
      _error = _confirmed
          ? null
          : (widget.autoDetect
                ? 'No supported attachment detected. Choose Manual Select.'
                : payload['message']?.toString() ??
                      'Attachment setup rejected.');
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _timeout?.cancel();
    _subscription?.cancel();
    _serial.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (findAttachment(widget.attachmentId) == null) {
      return const _UnknownAttachment();
    }
    final client = context.watch<RobotCommandClient>();
    if (!client.isConnected) {
      return ChoreFrame(
        title: 'Connect Attachment',
        back: '/attachments',
        body: SingleChildScrollView(
          child: SizedBox(
            height: 610,
            child: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1104),
                    border: Border.all(color: choreOrange),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'No connection to robot. Connect via Bluetooth or Wi-Fi first.',
                    style: choreText(12),
                  ),
                ),
                const SizedBox(height: 135),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: choreSurface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.mobile_off,
                    color: Colors.red,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Robot not reachable',
                  style: choreText(18, weight: FontWeight.w700),
                ),
                Text(
                  'Retrying every 5 seconds...',
                  style: choreText(12, color: choreMuted),
                ),
                const SizedBox(height: 30),
                ChorePill(
                  'Next',
                  onPressed: () => context.go(
                    _attachmentId == 'mower'
                        ? '/mower-defaults'
                        : '/setup-ready/$_attachmentId?confirmed=false',
                  ),
                ),
                ChorePill('Retry Now', onPressed: _retry),
              ],
            ),
          ),
        ),
      );
    }
    return ChoreFrame(
      title: 'Connect Attachment',
      back: '/attachments',
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: SizedBox(
            height: math.max(630, constraints.maxHeight),
            child: Stack(
              children: [
                Positioned(
                  top: 6,
                  left: 41,
                  right: 35,
                  child: Column(
                    children: [
                      _step(
                        1,
                        'Physically connect the attachment to the main robot.',
                      ),
                      const SizedBox(height: 10),
                      _step(2, 'Power on the robot.'),
                      const SizedBox(height: 18),
                      _step(3, 'Enter the serial number or scan the QR.'),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _serial,
                          textAlign: TextAlign.center,
                          style: choreText(12, weight: FontWeight.w200),
                          onSubmitted: (_) => _request(),
                          onChanged: (_) {
                            _timeout?.cancel();
                            setState(() {
                              _confirmed = false;
                              _commandId = null;
                              _waiting = false;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'ATT-XXXX-XXXX',
                            hintStyle: choreText(12, weight: FontWeight.w200),
                            filled: true,
                            fillColor: choreSurface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: choreBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: choreOrange),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: TextButton(
                          onPressed: () => context.go('/attachments'),
                          style: TextButton.styleFrom(
                            backgroundColor: choreSurface,
                            side: const BorderSide(color: choreBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Manual Select',
                            style: choreText(14, weight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 323,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: _confirmed
                            ? const Icon(
                                Icons.check_circle_outline,
                                color: Color(0xFF2EDB7D),
                                size: 48,
                              )
                            : _waiting
                            ? const CircularProgressIndicator(
                                color: choreOrange,
                                backgroundColor: choreBorder,
                                strokeWidth: 4,
                                strokeCap: StrokeCap.round,
                              )
                            : const Icon(
                                Icons.error_outline,
                                color: choreOrange,
                                size: 48,
                              ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _confirmed
                            ? '${findAttachment(_attachmentId)!.name} Connected'
                            : _error ?? 'Waiting for robot acknowledgement...',
                        textAlign: TextAlign.center,
                        style: choreText(13, weight: FontWeight.w200),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 510,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      ChorePill(
                        'Next',
                        onPressed: (!client.isConnected || _confirmed)
                            ? () => context.go(
                                _attachmentId == 'mower'
                                    ? '/mower-defaults'
                                    : '/setup-ready/$_attachmentId?confirmed=${client.isConnected && _confirmed}',
                              )
                            : null,
                      ),
                      ChorePill('Retry', onPressed: _request),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _step(int number, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 21,
        height: 21,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SvgPicture.asset(
              '${flowAssets}step-ring.svg',
              width: 21,
              height: 21,
            ),
            Text('$number', style: choreText(12, weight: FontWeight.w500)),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: choreText(12, weight: FontWeight.w200).copyWith(height: 1.25),
        ),
      ),
    ],
  );
}

class AttachmentReadyScreen extends StatelessWidget {
  const AttachmentReadyScreen({
    super.key,
    required this.attachmentId,
    this.confirmed = false,
  });
  final String attachmentId;
  final bool confirmed;
  @override
  Widget build(BuildContext context) {
    final attachment = findAttachment(attachmentId);
    if (attachment == null) return const _UnknownAttachment();
    return ChoreFrame(
      title: 'Setup',
      back: '/attachments',
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: SizedBox(
            height: math.max(630, constraints.maxHeight),
            child: Stack(
              children: [
                Positioned(
                  top: attachment.readyTop - 94,
                  left: 0,
                  right: 0,
                  height: attachment.readyHeight,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: attachment.readyWidth,
                      ),
                      child: attachment.id == 'patrol'
                          // The original patrol image has transparent margins; match the Figma image-fill crop.
                          ? SizedBox(
                              width: 255,
                              height: 257,
                              child: ClipRect(
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: -75,
                                      top: -93,
                                      width: 649,
                                      height: 443,
                                      child: Image.asset(
                                        '${flowAssets}patrol-ready.png',
                                        fit: BoxFit.fill,
                                        filterQuality: FilterQuality.high,
                                        semanticLabel: attachment.name,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Image.asset(
                              '$flowAssets${attachment.id}-ready.png',
                              width: attachment.readyWidth,
                              height: attachment.readyHeight,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              semanticLabel: attachment.name,
                            ),
                    ),
                  ),
                ),
                Positioned(
                  top: 345,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Ready',
                    textAlign: TextAlign.center,
                    style: choreText(18, weight: FontWeight.w700),
                  ),
                ),
                Positioned(
                  top: 372,
                  left: 0,
                  right: 0,
                  child: Text(
                    confirmed ? 'Settings saved to robot' : 'Offline preview',
                    textAlign: TextAlign.center,
                    style: choreText(13, weight: FontWeight.w200),
                  ),
                ),
                Positioned(
                  top: 417,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ChorePill(
                      'Done',
                      onPressed: () => context.go('/home'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnknownAttachment extends StatelessWidget {
  const _UnknownAttachment();
  @override
  Widget build(BuildContext context) => ChoreFrame(
    title: 'Select Attachment',
    body: Center(
      child: ChorePill('Back', onPressed: () => context.go('/attachments')),
    ),
  );
}
