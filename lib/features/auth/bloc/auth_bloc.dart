import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// ── Events ──
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final bool rememberMe;
  const AuthLoginRequested({required this.email, required this.password, this.rememberMe = false});
  @override
  List<Object?> get props => [email, password, rememberMe];
}

class AuthSignUpRequested extends AuthEvent {}
class AuthGuestRequested extends AuthEvent {}

// ── States ──
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {
  final bool hasRobotPaired;
  const AuthSuccess({this.hasRobotPaired = false});
  @override
  List<Object?> get props => [hasRobotPaired];
}
class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Bloc ──
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthGuestRequested>(_onGuest);
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    // TODO: Replace with real auth API call
    await Future.delayed(const Duration(seconds: 1));
    emit(const AuthSuccess(hasRobotPaired: false));
  }

  Future<void> _onSignUp(AuthSignUpRequested event, Emitter<AuthState> emit) async {
    // TODO: Navigate to sign up flow
  }

  Future<void> _onGuest(AuthGuestRequested event, Emitter<AuthState> emit) async {
    emit(const AuthSuccess(hasRobotPaired: false));
  }
}
