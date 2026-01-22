part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthFormInitial extends AuthState {}

class AuthFormLoading extends AuthState {}

class Authenticated extends AuthState {
  final AuthData authData;

  const Authenticated(this.authData);

  @override
  List<Object> get props => [authData];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}
