import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'package:ai_chat_bot/core/logging/app_logger.dart';
import 'package:ai_chat_bot/core/storage/token_storage.dart';
import 'package:ai_chat_bot/features/auth/data/auth_data.dart';
import 'package:ai_chat_bot/features/auth/data/auth_repository.dart';
import 'package:ai_chat_bot/features/auth/data/login_request_data.dart';
import 'package:ai_chat_bot/features/auth/data/register_request_data.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final TokenStorage tokenStorage;
  final AuthRepository authRepository;

  AuthBloc({required this.tokenStorage, required this.authRepository})
    : super(AuthFormInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginFormSubmitted>(_onLoginFormSubmitted);
    on<RegisterFormSubmitted>(_onRegisterFormSubmitted);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final token = await tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      try {
        // Fetch current user data to restore authentication state
        final response = await authRepository.me();

        if (response.success && response.data != null) {
          emit(Authenticated(response.data!));
        } else {
          // Token exists but is invalid, clear and logout
          await tokenStorage.clear();
          emit(Unauthenticated());
        }
      } catch (e) {
        // Failed to fetch user data, token might be expired
        await tokenStorage.clear();
        emit(Unauthenticated());
      }
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginFormSubmitted(
    LoginFormSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthFormLoading());
    try {
      final response = await authRepository.login(event.loginRequestData);

      if (response.success && response.data != null) {
        await tokenStorage.writeTokens(
          accessToken: response.data!.accessToken,
          refreshToken: response.data!.refreshToken,
        );
        emit(Authenticated(response.data!));
      } else {
        emit(const AuthError('Login failed'));
      }
    } on ApiException catch (e) {
      // Network or connection errors
      emit(AuthError(e.getDetailedMessage()));
    } catch (e) {
      AppLogger.e(e.toString());
      emit(AuthError('An unexpected error occurred'));
    }
  }

  Future<void> _onRegisterFormSubmitted(
    RegisterFormSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthFormLoading());
    try {
      final response = await authRepository.register(event.registerRequestData);

      if (response.success && response.data != null) {
        await tokenStorage.writeTokens(
          accessToken: response.data!.accessToken,
          refreshToken: response.data!.refreshToken,
        );
        emit(Authenticated(response.data!));
      } else {
        emit(const AuthError('Registration failed'));
      }
    } on ApiException catch (e) {
      AppLogger.e(e.toString());
      // Network or connection errors
      emit(AuthError(e.getDetailedMessage()));
    } catch (e) {
      AppLogger.e(e.toString());
      emit(AuthError('An unexpected error occurred'));
    }
  }
}
