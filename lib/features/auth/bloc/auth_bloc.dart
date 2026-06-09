import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/firebase/auth_service.dart';
import '../../../core/firebase/firebase_initializer.dart';
import '../../../core/firebase/robot_repository.dart';
import '../../../core/firebase/user_repository.dart';

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
  const AuthLoginRequested({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });
  @override
  List<Object?> get props => [email, password, rememberMe];
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignUpRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthGoogleRequested extends AuthEvent {}
class AuthGuestRequested extends AuthEvent {}
class AuthPasswordResetRequested extends AuthEvent {
  final String email;
  const AuthPasswordResetRequested(this.email);
  @override
  List<Object?> get props => [email];
}
class AuthSignOutRequested extends AuthEvent {}

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
  final String uid;
  final String email;
  const AuthSuccess({
    required this.uid,
    required this.email,
    this.hasRobotPaired = false,
  });
  @override
  List<Object?> get props => [uid, email, hasRobotPaired];
}

class AuthPasswordResetSent extends AuthState {
  final String email;
  const AuthPasswordResetSent(this.email);
  @override
  List<Object?> get props => [email];
}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Bloc ──
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _auth;
  final UserRepository _userRepo;
  final RobotRepository _robotRepo;

  AuthBloc({
    AuthService? auth,
    UserRepository? userRepo,
    RobotRepository? robotRepo,
  })  : _auth = auth ?? AuthService(),
        _userRepo = userRepo ?? UserRepository(),
        _robotRepo = robotRepo ?? RobotRepository(),
        super(AuthInitial()) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthGoogleRequested>(_onGoogle);
    on<AuthGuestRequested>(_onGuest);
    on<AuthPasswordResetRequested>(_onPasswordReset);
    on<AuthSignOutRequested>(_onSignOut);
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    if (!_ensureConfigured(emit)) return;
    emit(AuthLoading());
    try {
      final user = await _auth.signInWithEmail(event.email, event.password);
      await _userRepo.ensureUserProfile(UserProfile.fromAuthUser(user));
      final robots = await _robotRepo.getUserRobots(user.uid);
      emit(AuthSuccess(
        uid: user.uid,
        email: user.email ?? event.email,
        hasRobotPaired: robots.isNotEmpty,
      ));
    } on AuthServiceException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure('Sign-in failed: $e'));
    }
  }

  Future<void> _onSignUp(AuthSignUpRequested event, Emitter<AuthState> emit) async {
    if (!_ensureConfigured(emit)) return;
    emit(AuthLoading());
    try {
      final user = await _auth.signUpWithEmail(event.email, event.password);
      await _userRepo.ensureUserProfile(UserProfile.fromAuthUser(user));
      emit(AuthSuccess(
        uid: user.uid,
        email: user.email ?? event.email,
        hasRobotPaired: false,
      ));
    } on AuthServiceException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure('Sign-up failed: $e'));
    }
  }

  Future<void> _onGoogle(AuthGoogleRequested event, Emitter<AuthState> emit) async {
    if (!_ensureConfigured(emit)) return;
    emit(AuthLoading());
    try {
      final user = await _auth.signInWithGoogle();
      await _userRepo.ensureUserProfile(UserProfile.fromAuthUser(user));
      final robots = await _robotRepo.getUserRobots(user.uid);
      emit(AuthSuccess(
        uid: user.uid,
        email: user.email ?? '',
        hasRobotPaired: robots.isNotEmpty,
      ));
    } on AuthServiceException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure('Google sign-in failed: $e'));
    }
  }

  Future<void> _onGuest(AuthGuestRequested event, Emitter<AuthState> emit) async {
    // Guest mode bypasses Firebase — used for local BLE testing without a
    // Firebase project.
    emit(const AuthSuccess(uid: 'guest', email: '', hasRobotPaired: false));
  }

  Future<void> _onPasswordReset(
      AuthPasswordResetRequested event, Emitter<AuthState> emit) async {
    if (!_ensureConfigured(emit)) return;
    try {
      await _auth.sendPasswordReset(event.email);
      emit(AuthPasswordResetSent(event.email));
    } on AuthServiceException catch (e) {
      emit(AuthFailure(e.message));
    }
  }

  Future<void> _onSignOut(AuthSignOutRequested event, Emitter<AuthState> emit) async {
    await _auth.signOut();
    emit(AuthInitial());
  }

  bool _ensureConfigured(Emitter<AuthState> emit) {
    if (!FirebaseInitializer.isInitialized) {
      emit(const AuthFailure(
        'Firebase is not configured. Run `flutterfire configure` or use '
        '"Continue as Guest" for local BLE testing.',
      ));
      return false;
    }
    return true;
  }
}
