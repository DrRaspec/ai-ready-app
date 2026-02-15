import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'package:shadow_log/shadow_log.dart';
import 'package:ai_chat_bot/core/network/models/api_response.dart';
import 'package:ai_chat_bot/core/storage/token_storage.dart';
import 'package:ai_chat_bot/features/auth/data/auth_data.dart';
import 'package:ai_chat_bot/features/auth/data/auth_repository.dart';
import 'package:ai_chat_bot/features/auth/data/login_request_data.dart';
import 'package:ai_chat_bot/features/auth/data/register_request_data.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_sign_in/google_sign_in.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final TokenStorage tokenStorage;
  final AuthRepository authRepository;
  final GoogleSignIn googleSignIn;

  AuthBloc({
    required this.tokenStorage,
    required this.authRepository,
    required this.googleSignIn,
  }) : super(AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<LoginFormSubmitted>(_onLoginFormSubmitted);
    on<RegisterFormSubmitted>(_onRegisterFormSubmitted);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<TokenRefreshRequested>(_onTokenRefreshRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<LogoutAllRequested>(_onLogoutAllRequested);
  }

  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    final token = await tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      try {
        final response = await authRepository.me();

        if (response.success && response.data != null) {
          emit(Authenticated(response.data!));
        } else {
          await tokenStorage.clear();
          emit(Unauthenticated());
        }
      } catch (e) {
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
    emit(AuthLoading());
    try {
      final response = await authRepository.login(event.loginRequestData);
      await _completeAuthenticatedSession(
        response: response,
        emit: emit,
        defaultFailureMessage: 'Login failed',
      );
    } on ApiException catch (e) {
      emit(AuthFailure(e.getDetailedMessage()));
    } catch (e) {
      ShadowLog.e(e.toString());
      emit(AuthFailure('An unexpected error occurred'));
    }
  }

  Future<void> _onRegisterFormSubmitted(
    RegisterFormSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await authRepository.register(event.registerRequestData);
      await _completeAuthenticatedSession(
        response: response,
        emit: emit,
        defaultFailureMessage: 'Registration failed',
      );
    } on ApiException catch (e) {
      ShadowLog.e(e.toString());
      emit(AuthFailure(e.getDetailedMessage()));
    } catch (e) {
      ShadowLog.e(e.toString());
      emit(AuthFailure('An unexpected error occurred'));
    }
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final account = await googleSignIn.signIn();
      if (account == null) {
        emit(Unauthenticated());
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        emit(const AuthFailure('Google did not return an idToken'));
        return;
      }

      final response = await authRepository.loginWithGoogle(idToken: idToken);
      await _completeAuthenticatedSession(
        response: response,
        emit: emit,
        defaultFailureMessage: 'Google sign-in failed',
      );
    } on ApiException catch (e) {
      emit(AuthFailure(e.getDetailedMessage()));
    } catch (e) {
      ShadowLog.e('Google sign-in error: $e');
      emit(const AuthFailure('Google sign-in failed'));
    }
  }

  Future<void> _onTokenRefreshRequested(
    TokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final response = await authRepository.refresh();
      final accessToken = response.data?.accessToken;
      final refreshToken = response.data?.refreshToken;
      if (response.success &&
          response.data != null &&
          accessToken != null &&
          accessToken.isNotEmpty &&
          refreshToken != null &&
          refreshToken.isNotEmpty) {
        final me = await authRepository.me();
        if (me.success && me.data != null) {
          emit(
            Authenticated(
              me.data!.copyWith(
                accessToken: accessToken,
                refreshToken: refreshToken,
              ),
            ),
          );
          return;
        }
      }

      await tokenStorage.clear();
      emit(Unauthenticated());
    } on ApiException {
      await tokenStorage.clear();
      emit(Unauthenticated());
    } catch (_) {
      await tokenStorage.clear();
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await authRepository.logout();
      await googleSignIn.signOut();
    } catch (e) {
      ShadowLog.e('Logout error: $e');
    } finally {
      await tokenStorage.clear();
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogoutAllRequested(
    LogoutAllRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await authRepository.logoutAll();
      await googleSignIn.signOut();
    } catch (e) {
      ShadowLog.e('Logout all error: $e');
    } finally {
      await tokenStorage.clear();
      emit(Unauthenticated());
    }
  }

  Future<void> _completeAuthenticatedSession({
    required ApiResponse<AuthData> response,
    required Emitter<AuthState> emit,
    required String defaultFailureMessage,
  }) async {
    if (!response.success || response.data == null) {
      emit(AuthFailure(response.message ?? defaultFailureMessage));
      return;
    }

    final accessToken = response.data!.accessToken;
    final refreshToken = response.data!.refreshToken;
    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      emit(const AuthFailure('Missing authentication tokens'));
      return;
    }

    await tokenStorage.writeTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    final profileResponse = await authRepository.me();
    if (!profileResponse.success || profileResponse.data == null) {
      await tokenStorage.clear();
      emit(
        AuthFailure(
          profileResponse.message ?? 'Failed to verify authenticated session',
        ),
      );
      return;
    }

    emit(
      Authenticated(
        profileResponse.data!.copyWith(
          accessToken: accessToken,
          refreshToken: refreshToken,
        ),
      ),
    );
  }
}
