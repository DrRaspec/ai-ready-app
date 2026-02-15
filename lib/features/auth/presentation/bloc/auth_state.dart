part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthFormInitial extends AuthInitial {}

class AuthLoading extends AuthState {}

class AuthFormLoading extends AuthLoading {}

class Authenticated extends AuthState {
  final AuthData authData;

  const Authenticated(this.authData);

  @override
  List<Object> get props => [authData];
}

class Unauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object> get props => [message];
}

class AuthError extends AuthFailure {
  const AuthError(super.message);
}
