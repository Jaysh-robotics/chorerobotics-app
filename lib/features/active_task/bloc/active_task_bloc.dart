import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// ── Events ──
abstract class ActiveTaskEvent extends Equatable {
  const ActiveTaskEvent();
  @override
  List<Object?> get props => [];
}

class TaskStarted extends ActiveTaskEvent {
  final String taskId;
  final String taskType; // mow, plow, collect
  final String zoneId;
  final String zoneName;
  final double totalAreaSqM;
  const TaskStarted({required this.taskId, required this.taskType, required this.zoneId, required this.zoneName, required this.totalAreaSqM});
  @override
  List<Object?> get props => [taskId, taskType, zoneId, zoneName, totalAreaSqM];
}

class TaskProgressUpdated extends ActiveTaskEvent {
  final double completedAreaSqM;
  final double progressPercent;
  final double batteryUsed;
  final int elapsedSeconds;
  final List<Map<String, double>> coveragePath; // [{lat, lng}]
  const TaskProgressUpdated({
    required this.completedAreaSqM,
    required this.progressPercent,
    required this.batteryUsed,
    required this.elapsedSeconds,
    this.coveragePath = const [],
  });
  @override
  List<Object?> get props => [completedAreaSqM, progressPercent, batteryUsed, elapsedSeconds];
}

class TaskPaused extends ActiveTaskEvent {}
class TaskResumed extends ActiveTaskEvent {}
class TaskCompleted extends ActiveTaskEvent {}
class TaskFailed extends ActiveTaskEvent {
  final String reason; // "stuck", "battery_low", "obstacle", "connection_lost", "estop"
  const TaskFailed(this.reason);
  @override
  List<Object?> get props => [reason];
}
class TaskCancelled extends ActiveTaskEvent {}

// ── States ──
enum TaskStatus { idle, running, paused, stuck, failed, completed, cancelled }

class ActiveTaskState extends Equatable {
  final TaskStatus status;
  final String? taskId;
  final String? taskType;
  final String? zoneId;
  final String? zoneName;
  final double totalAreaSqM;
  final double completedAreaSqM;
  final double progressPercent;
  final double batteryUsedPercent;
  final int elapsedSeconds;
  final String? failReason;
  final List<Map<String, double>> coveragePath;
  final bool canResume;

  const ActiveTaskState({
    this.status = TaskStatus.idle,
    this.taskId,
    this.taskType,
    this.zoneId,
    this.zoneName,
    this.totalAreaSqM = 0,
    this.completedAreaSqM = 0,
    this.progressPercent = 0,
    this.batteryUsedPercent = 0,
    this.elapsedSeconds = 0,
    this.failReason,
    this.coveragePath = const [],
    this.canResume = false,
  });

  ActiveTaskState copyWith({
    TaskStatus? status,
    String? taskId,
    String? taskType,
    String? zoneId,
    String? zoneName,
    double? totalAreaSqM,
    double? completedAreaSqM,
    double? progressPercent,
    double? batteryUsedPercent,
    int? elapsedSeconds,
    String? failReason,
    List<Map<String, double>>? coveragePath,
    bool? canResume,
  }) {
    return ActiveTaskState(
      status: status ?? this.status,
      taskId: taskId ?? this.taskId,
      taskType: taskType ?? this.taskType,
      zoneId: zoneId ?? this.zoneId,
      zoneName: zoneName ?? this.zoneName,
      totalAreaSqM: totalAreaSqM ?? this.totalAreaSqM,
      completedAreaSqM: completedAreaSqM ?? this.completedAreaSqM,
      progressPercent: progressPercent ?? this.progressPercent,
      batteryUsedPercent: batteryUsedPercent ?? this.batteryUsedPercent,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      failReason: failReason ?? this.failReason,
      coveragePath: coveragePath ?? this.coveragePath,
      canResume: canResume ?? this.canResume,
    );
  }

  String get formattedElapsed {
    final m = elapsedSeconds ~/ 60;
    final s = elapsedSeconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  String get formattedRemaining {
    if (progressPercent <= 0) return '--';
    final totalEst = elapsedSeconds / (progressPercent / 100);
    final remaining = (totalEst - elapsedSeconds).round();
    if (remaining <= 0) return '< 1m';
    return '${remaining ~/ 60}m ${(remaining % 60).toString().padLeft(2, '0')}s';
  }

  @override
  List<Object?> get props => [status, taskId, progressPercent, completedAreaSqM, elapsedSeconds, failReason, canResume];
}

// ── Bloc ──
class ActiveTaskBloc extends Bloc<ActiveTaskEvent, ActiveTaskState> {
  ActiveTaskBloc() : super(const ActiveTaskState()) {
    on<TaskStarted>(_onStarted);
    on<TaskProgressUpdated>(_onProgress);
    on<TaskPaused>(_onPaused);
    on<TaskResumed>(_onResumed);
    on<TaskCompleted>(_onCompleted);
    on<TaskFailed>(_onFailed);
    on<TaskCancelled>(_onCancelled);
  }

  void _onStarted(TaskStarted event, Emitter<ActiveTaskState> emit) {
    emit(ActiveTaskState(
      status: TaskStatus.running,
      taskId: event.taskId,
      taskType: event.taskType,
      zoneId: event.zoneId,
      zoneName: event.zoneName,
      totalAreaSqM: event.totalAreaSqM,
    ));
  }

  void _onProgress(TaskProgressUpdated event, Emitter<ActiveTaskState> emit) {
    emit(state.copyWith(
      completedAreaSqM: event.completedAreaSqM,
      progressPercent: event.progressPercent,
      batteryUsedPercent: event.batteryUsed,
      elapsedSeconds: event.elapsedSeconds,
      coveragePath: event.coveragePath,
    ));
  }

  void _onPaused(TaskPaused event, Emitter<ActiveTaskState> emit) {
    emit(state.copyWith(status: TaskStatus.paused, canResume: true));
  }

  void _onResumed(TaskResumed event, Emitter<ActiveTaskState> emit) {
    emit(state.copyWith(status: TaskStatus.running, canResume: false));
  }

  void _onCompleted(TaskCompleted event, Emitter<ActiveTaskState> emit) {
    emit(state.copyWith(status: TaskStatus.completed, progressPercent: 100, canResume: false));
  }

  void _onFailed(TaskFailed event, Emitter<ActiveTaskState> emit) {
    emit(state.copyWith(
      status: event.reason == 'stuck' ? TaskStatus.stuck : TaskStatus.failed,
      failReason: event.reason,
      canResume: true, // Can always attempt resume after failure
    ));
  }

  void _onCancelled(TaskCancelled event, Emitter<ActiveTaskState> emit) {
    emit(const ActiveTaskState()); // Reset to idle
  }
}
