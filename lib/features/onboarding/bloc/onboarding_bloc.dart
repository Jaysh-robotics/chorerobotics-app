import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// ── Events ──
abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();
  @override
  List<Object?> get props => [];
}

class StartBleScan extends OnboardingEvent {}
class StopBleScan extends OnboardingEvent {}
class RobotSelected extends OnboardingEvent {
  final String robotId;
  final String robotName;
  const RobotSelected({required this.robotId, required this.robotName});
  @override
  List<Object?> get props => [robotId, robotName];
}
class PairingCodeEntered extends OnboardingEvent {
  final String code;
  const PairingCodeEntered(this.code);
  @override
  List<Object?> get props => [code];
}
class WifiNetworkSelected extends OnboardingEvent {
  final String ssid;
  const WifiNetworkSelected(this.ssid);
  @override
  List<Object?> get props => [ssid];
}
class WifiPasswordEntered extends OnboardingEvent {
  final String password;
  const WifiPasswordEntered(this.password);
  @override
  List<Object?> get props => [password];
}
class WifiConnectRequested extends OnboardingEvent {}
class WifiSkipped extends OnboardingEvent {}

// ── States ──
abstract class OnboardingState extends Equatable {
  const OnboardingState();
  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {}

class BleScanning extends OnboardingState {}
class BleRobotFound extends OnboardingState {
  final String robotId;
  final String robotName;
  final int signalStrength; // 0-4
  const BleRobotFound({required this.robotId, required this.robotName, required this.signalStrength});
  @override
  List<Object?> get props => [robotId, robotName, signalStrength];
}

class PairingInProgress extends OnboardingState {}
class PairingSuccess extends OnboardingState {
  final String robotName;
  final String attachmentType;
  const PairingSuccess({required this.robotName, this.attachmentType = 'Mower Blade'});
  @override
  List<Object?> get props => [robotName, attachmentType];
}

class WifiScanComplete extends OnboardingState {
  final List<String> networks;
  final String? selectedNetwork;
  const WifiScanComplete({required this.networks, this.selectedNetwork});
  @override
  List<Object?> get props => [networks, selectedNetwork];
}

class WifiConnecting extends OnboardingState {}
class SetupComplete extends OnboardingState {
  final String robotName;
  final String network;
  final String attachment;
  const SetupComplete({required this.robotName, required this.network, required this.attachment});
  @override
  List<Object?> get props => [robotName, network, attachment];
}

// ── Bloc ──
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(OnboardingInitial()) {
    on<StartBleScan>(_onStartScan);
    on<RobotSelected>(_onRobotSelected);
    on<PairingCodeEntered>(_onPairingCode);
    on<WifiNetworkSelected>(_onWifiSelected);
    on<WifiConnectRequested>(_onWifiConnect);
    on<WifiSkipped>(_onWifiSkipped);
  }

  Future<void> _onStartScan(StartBleScan event, Emitter<OnboardingState> emit) async {
    emit(BleScanning());
    // TODO: Replace with real BLE scan
    await Future.delayed(const Duration(seconds: 2));
    emit(const BleRobotFound(robotId: 'CHORE-A1B2-C3D4', robotName: 'ChoreBot Alpha', signalStrength: 4));
  }

  Future<void> _onRobotSelected(RobotSelected event, Emitter<OnboardingState> emit) async {
    emit(PairingInProgress());
    await Future.delayed(const Duration(milliseconds: 500));
    // Waiting for pairing code
  }

  Future<void> _onPairingCode(PairingCodeEntered event, Emitter<OnboardingState> emit) async {
    emit(PairingInProgress());
    await Future.delayed(const Duration(seconds: 1));
    emit(const PairingSuccess(robotName: 'ChoreBot Alpha', attachmentType: 'Mower Blade Assembly'));
  }

  Future<void> _onWifiSelected(WifiNetworkSelected event, Emitter<OnboardingState> emit) async {
    emit(WifiScanComplete(
      networks: const ['HomeWiFi-5G', 'HomeWiFi-2.4G', 'Neighbor_Net'],
      selectedNetwork: event.ssid,
    ));
  }

  Future<void> _onWifiConnect(WifiConnectRequested event, Emitter<OnboardingState> emit) async {
    emit(WifiConnecting());
    await Future.delayed(const Duration(seconds: 2));
    emit(const SetupComplete(robotName: 'ChoreBot Alpha', network: 'HomeWiFi-5G', attachment: 'Mower Blade'));
  }

  Future<void> _onWifiSkipped(WifiSkipped event, Emitter<OnboardingState> emit) async {
    emit(const SetupComplete(robotName: 'ChoreBot Alpha', network: 'Direct BLE', attachment: 'Mower Blade'));
  }
}
