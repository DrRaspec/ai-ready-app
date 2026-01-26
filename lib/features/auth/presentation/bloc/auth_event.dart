part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginFormSubmitted extends AuthEvent {
  final LoginRequestData loginRequestData;

  const LoginFormSubmitted({required this.loginRequestData});

  @override
  List<Object> get props => [loginRequestData];
}

class RegisterFormSubmitted extends AuthEvent {
  final RegisterRequestData registerRequestData;

  const RegisterFormSubmitted({required this.registerRequestData});

  @override
  List<Object> get props => [registerRequestData];
}

class LogoutRequested extends AuthEvent {}
