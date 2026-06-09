import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/ble/ble_service.dart';
import '../../../core/firebase/auth_service.dart';
import '../../../core/firebase/firebase_initializer.dart';
import '../../../core/firebase/robot_repository.dart';

// ── Events ──
abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();
  @override
  List<Object?> get props => [];
}

class StartBleScan extends OnboardingEvent {}
class StopBleScan extends OnboardingEvent {}
class RobotDiscovered extends OnboardingEvent {
  final DiscoveredRobot robot;
  const RobotDiscovered(this.robot);
  @override
  List<Object?> get props => [robot.id];
}
class RobotSelected extends OnboardingEvent {
  final DiscoveredRobot robot;
  const RobotSelected(this.robot);
  @override
  List<Object?> get props => [robot.id];
}
class PairingCodeEntered extends OnboardingEvent {
  final String code;
  const PairingCodeEntered(this.code);
  @override
  List<Object?> get props => [code];
}
class PairingStateChanged extends OnboardingEvent {
  final int ledState;
  const PairingStateChanged(this.ledState);
  @override
  List<Object?> get props => [ledState];
}
class PairingResultReceived extends OnboardingEvent {
  final PairingResultCode code;
  const PairingResultReceived(this.code);
  @override
  List<Object?> get props => [code];
}
class PairingTokenReceived extends OnboardingEvent {
  final String token;
  const PairingTokenReceived(this.token);
  @override
  List<Object?> get props => [token];
}
class BleError extends OnboardingEvent {
  final String message;
  const BleError(this.message);
  @override
  List<Object?> get props => [message];
}
class WifiNetworkSelected extends OnboardingEvent {
  final String ssid;
  const WifiNetworkSelected(this.ssid);
  @override
  List<Object?> get props => [ssid];
}
class WifiConnectRequested extends OnboardingEvent {
  final String ssid;
  final String password;
  const WifiConnectRequested({required this.ssid, required this.password});
  @override
  List<Object?> get props => [ssid, password];
}
class WifiSkipped extends OnboardingEvent {}

// ── States ──
abstract class OnboardingState extends Equatable {
  const OnboardingState();
  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {}

class BleScanning extends OnboardingState {
  final List<DiscoveredRobot> robots;
  const BleScanning({this.robots = const []});
  @override
  List<Object?> get props => [robots.map((r) => r.id).toList()];
}

class BleScanError extends OnboardingState {
  final String message;
  const BleScanError(this.message);
  @override
  List<Object?> get props => [message];
}

class BleConnecting extends OnboardingState {
  final DiscoveredRobot robot;
  const BleConnecting(this.robot);
  @override
  List<Object?> get props => [robot.id];
}

class BleConnected extends OnboardingState {
  final DiscoveredRobot robot;
  final RobotInfo info;
  final int ledState;
  const BleConnected({required this.robot, required this.info, this.ledState = 0});
  @override
  List<Object?> get props => [robot.id, info.serial, ledState];
}

class PairingInProgress extends OnboardingState {
  final DiscoveredRobot robot;
  final RobotInfo info;
  final int ledState;
  const PairingInProgress({required this.robot, required this.info, required this.ledState});
  @override
  List<Object?> get props => [robot.id, ledState];
}

class PairingFailed extends OnboardingState {
  final String reason;
  const PairingFailed(this.reason);
  @override
  List<Object?> get props => [reason];
}

class PairingSuccess extends OnboardingState {
  final RobotInfo info;
  final String token;
  const PairingSuccess({required this.info, required this.token});
  @override
  List<Object?> get props => [info.serial, token];
}

// ── Bloc ──
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final BleService _ble;
  final AuthService _auth;
  final RobotRepository _robotRepo;
  StreamSubscription<DiscoveredRobot>? _scanSub;
  StreamSubscription<int>? _stateSub;
  StreamSubscription<PairingResultCode>? _resultSub;

  DiscoveredRobot? _currentRobot;
  RobotInfo? _currentInfo;

  OnboardingBloc({
    BleService? ble,
    AuthService? auth,
    RobotRepository? robotRepo,
  })  : _ble = ble ?? BleService(),
        _auth = auth ?? AuthService(),
        _robotRepo = robotRepo ?? RobotRepository(),
        super(OnboardingInitial()) {
    on<StartBleScan>(_onStartScan);
    on<StopBleScan>(_onStopScan);
    on<RobotDiscovered>(_onRobotDiscovered);
    on<RobotSelected>(_onRobotSelected);
    on<PairingCodeEntered>(_onPairingCode);
    on<PairingStateChanged>(_onPairingStateChanged);
    on<PairingResultReceived>(_onPairingResultReceived);
    on<PairingTokenReceived>(_onPairingTokenReceived);
    on<BleError>(_onBleError);
  }

  Future<void> _onStartScan(StartBleScan event, Emitter<OnboardingState> emit) async {
    emit(const BleScanning(robots: []));

    final ok = await _ble.ensurePermissions();
    if (!ok) {
      emit(const BleScanError('Bluetooth permission denied. Enable it in Settings.'));
      return;
    }

    try {
      await _scanSub?.cancel();
      final robots = <String, DiscoveredRobot>{};
      _scanSub = _ble.scanForRobots().listen(
        (robot) => add(RobotDiscovered(robot)),
        onError: (e) => add(BleError('Scan failed: $e')),
      );

      // Seed empty state
      if (state is! BleScanning) emit(BleScanning(robots: robots.values.toList()));
    } catch (e) {
      emit(BleScanError('Scan failed: $e'));
    }
  }

  Future<void> _onStopScan(StopBleScan event, Emitter<OnboardingState> emit) async {
    await _scanSub?.cancel();
    _scanSub = null;
    await _ble.stopScan();
  }

  void _onRobotDiscovered(RobotDiscovered event, Emitter<OnboardingState> emit) {
    final current = state;
    if (current is! BleScanning) return;
    final existing = current.robots.where((r) => r.id != event.robot.id).toList();
    existing.add(event.robot);
    existing.sort((a, b) => b.rssi.compareTo(a.rssi));
    emit(BleScanning(robots: existing));
  }

  Future<void> _onRobotSelected(RobotSelected event, Emitter<OnboardingState> emit) async {
    await _scanSub?.cancel();
    emit(BleConnecting(event.robot));
    try {
      final info = await _ble.connect(event.robot);
      _currentRobot = event.robot;
      _currentInfo = info;

      // Subscribe to pairing state/result/token
      await _stateSub?.cancel();
      _stateSub = _ble.pairingStateStream().listen(
        (led) => add(PairingStateChanged(led)),
        onError: (e) => add(BleError('Pairing state stream: $e')),
      );

      await _resultSub?.cancel();
      _resultSub = _ble.pairingResultStream().listen(
        (code) => add(PairingResultReceived(code)),
        onError: (e) => add(BleError('Pairing result stream: $e')),
      );

      emit(BleConnected(robot: event.robot, info: info));
    } catch (e) {
      emit(BleScanError('Connect failed: $e'));
    }
  }

  Future<void> _onPairingCode(PairingCodeEntered event, Emitter<OnboardingState> emit) async {
    final robot = _currentRobot;
    final info = _currentInfo;
    if (robot == null || info == null) return;
    emit(PairingInProgress(robot: robot, info: info, ledState: 5));
    try {
      await _ble.sendPairingCode(event.code);
    } catch (e) {
      emit(PairingFailed('Failed to send code: $e'));
    }
  }

  void _onPairingStateChanged(PairingStateChanged event, Emitter<OnboardingState> emit) {
    final robot = _currentRobot;
    final info = _currentInfo;
    if (robot == null || info == null) return;
    final current = state;
    if (current is BleConnected) {
      emit(BleConnected(robot: robot, info: info, ledState: event.ledState));
    } else if (current is PairingInProgress) {
      emit(PairingInProgress(robot: robot, info: info, ledState: event.ledState));
    }
  }

  Future<void> _onPairingResultReceived(
      PairingResultReceived event, Emitter<OnboardingState> emit) async {
    if (event.code == PairingResultCode.failed) {
      emit(const PairingFailed('Incorrect code. Try again.'));
      return;
    }
    if (event.code == PairingResultCode.timeout) {
      emit(const PairingFailed('Pairing timed out.'));
      return;
    }
    if (event.code == PairingResultCode.success) {
      final info = _currentInfo;
      if (info == null) return;
      final token = await _ble.readPairingToken();
      final finalToken = token.isNotEmpty ? token : 'paired-${info.serial}';

      // Persist the paired robot to Firestore if the user is authenticated.
      await _persistPairedRobot(info, finalToken);

      emit(PairingSuccess(info: info, token: finalToken));
    }
  }

  Future<void> _persistPairedRobot(RobotInfo info, String token) async {
    if (!FirebaseInitializer.isInitialized) return;
    final user = _auth.currentUser;
    if (user == null) return; // Guest mode — skip persistence.
    try {
      final now = DateTime.now();
      await _robotRepo.upsertRobot(
        user.uid,
        PairedRobot(
          robotId: info.serial,
          name: info.name,
          model: info.model,
          firmware: info.firmware,
          attachment: info.attachment,
          pairingToken: token,
          pairedAt: now,
          lastSeenAt: now,
          isOnline: true,
        ),
      );
    } catch (_) {
      // Don't block UI on a Firestore write failure; the pairing itself
      // succeeded at the BLE layer.
    }
  }

  void _onPairingTokenReceived(PairingTokenReceived event, Emitter<OnboardingState> emit) {
    final info = _currentInfo;
    if (info == null) return;
    emit(PairingSuccess(info: info, token: event.token));
  }

  void _onBleError(BleError event, Emitter<OnboardingState> emit) {
    emit(BleScanError(event.message));
  }

  @override
  Future<void> close() async {
    await _scanSub?.cancel();
    await _stateSub?.cancel();
    await _resultSub?.cancel();
    await _ble.disconnect();
    return super.close();
  }
}
