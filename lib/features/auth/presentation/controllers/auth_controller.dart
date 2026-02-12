import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'package:ai_chat_bot/core/logging/app_logger.dart';
import 'package:get/get.dart';
import 'package:ai_chat_bot/core/storage/token_storage.dart';
import 'package:ai_chat_bot/features/auth/data/auth_data.dart';
import 'package:ai_chat_bot/features/auth/data/auth_repository.dart';
import 'package:ai_chat_bot/features/auth/data/login_request_data.dart';
import 'package:ai_chat_bot/features/auth/data/register_request_data.dart';
import 'package:equatable/equatable.dart';

part 'auth_state.dart';

class AuthController extends GetxController {
  final TokenStorage tokenStorage;
  final AuthRepository authRepository;
  Future<void> _eventQueue = Future<void>.value();
  final Rx<AuthState> rxState;

  AuthState get state => rxState.value;

  void _setState(AuthState newState) {
    rxState.value = newState;
  }

  AuthController({required this.tokenStorage, required this.authRepository})
    : rxState = AuthFormInitial().obs;

  Future<void> _enqueue(Future<void> Function() task) async {
    _eventQueue = _eventQueue.then((_) => task());
    return _eventQueue;
  }

  Future<void> appStarted() async {
    return _enqueue(_onAppStarted);
  }

  Future<void> login(LoginRequestData loginRequestData) async {
    return _enqueue(() => _onLogin(loginRequestData));
  }

  Future<void> register(RegisterRequestData registerRequestData) async {
    return _enqueue(() => _onRegister(registerRequestData));
  }

  Future<void> logout() async {
    return _enqueue(_onLogout);
  }

  Future<void> _onAppStarted() async {
    final token = await tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      try {
        // Fetch current user data to restore authentication state
        final response = await authRepository.me();

        if (response.success && response.data != null) {
          _setState(Authenticated(response.data!));
        } else {
          // Token exists but is invalid, clear and logout
          await tokenStorage.clear();
          _setState(Unauthenticated());
        }
      } catch (e) {
        // Failed to fetch user data, token might be expired
        await tokenStorage.clear();
        _setState(Unauthenticated());
      }
    } else {
      _setState(Unauthenticated());
    }
  }

  Future<void> _onLogin(LoginRequestData loginRequestData) async {
    _setState(AuthFormLoading());
    try {
      final response = await authRepository.login(loginRequestData);

      if (response.success && response.data != null) {
        await tokenStorage.writeTokens(
          accessToken: response.data!.accessToken,
          refreshToken: response.data!.refreshToken,
        );
        _setState(Authenticated(response.data!));
      } else {
        _setState(AuthError(response.message ?? 'Login failed'));
      }
    } on ApiException catch (e) {
      // Network or connection errors
      _setState(AuthError(e.getDetailedMessage()));
    } catch (e) {
      AppLogger.e(e.toString());
      _setState(AuthError('An unexpected error occurred'));
    }
  }

  Future<void> _onRegister(RegisterRequestData registerRequestData) async {
    _setState(AuthFormLoading());
    try {
      final response = await authRepository.register(registerRequestData);

      if (response.success && response.data != null) {
        await tokenStorage.writeTokens(
          accessToken: response.data!.accessToken,
          refreshToken: response.data!.refreshToken,
        );
        _setState(Authenticated(response.data!));
      } else {
        _setState(AuthError(response.message ?? 'Registration failed'));
      }
    } on ApiException catch (e) {
      AppLogger.e(e.toString());
      // Network or connection errors
      _setState(AuthError(e.getDetailedMessage()));
    } catch (e) {
      AppLogger.e(e.toString());
      _setState(AuthError('An unexpected error occurred'));
    }
  }

  Future<void> _onLogout() async {
    try {
      await authRepository.logout();
    } catch (e) {
      // Ignore errors during logout
      AppLogger.e('Logout error: $e');
    } finally {
      await tokenStorage.clear();
      _setState(Unauthenticated());
    }
  }
}
