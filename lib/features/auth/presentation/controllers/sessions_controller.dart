import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'package:get/get.dart';
import 'package:ai_chat_bot/features/auth/data/auth_repository.dart';
import 'package:ai_chat_bot/features/auth/data/models/session.dart';
import 'package:equatable/equatable.dart';

// State
abstract class SessionsState extends Equatable {
  const SessionsState();

  @override
  List<Object?> get props => [];
}

class SessionsInitial extends SessionsState {}

class SessionsLoading extends SessionsState {}

class SessionsLoaded extends SessionsState {
  final List<Session> sessions;
  const SessionsLoaded(this.sessions);

  @override
  List<Object?> get props => [sessions];
}

class SessionsError extends SessionsState {
  final String message;
  const SessionsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Controller
class SessionsController extends GetxController {
  final AuthRepository _repository;
  final Rx<SessionsState> rxState;

  SessionsState get state => rxState.value;

  void _setState(SessionsState newState) {
    rxState.value = newState;
  }

  SessionsController(this._repository) : rxState = SessionsInitial().obs;

  Future<void> loadSessions() async {
    _setState(SessionsLoading());
    try {
      final response = await _repository.getSessions();
      if (response.success && response.data != null) {
        _setState(SessionsLoaded(response.data!));
      } else {
        _setState(SessionsError(response.message ?? 'Failed to load sessions'));
      }
    } on ApiException catch (e) {
      _setState(SessionsError(e.message));
    } catch (e) {
      _setState(SessionsError(e.toString()));
    }
  }

  Future<void> terminateSession(String sessionId) async {
    // Optimistic update or reload? Reload is safer.
    // Or we can emit loading?
    // Let's keep current state but maybe show a snackbar or something?
    // Usually we reload list.
    try {
      await _repository.terminateSession(sessionId);
      // Reload
      loadSessions();
    } on ApiException catch (e) {
      _setState(SessionsError(e.message));
    } catch (e) {
      _setState(SessionsError(e.toString()));
    }
  }

  Future<void> terminateAllOtherSessions() async {
    try {
      await _repository.terminateAllOtherSessions();
      // Reload
      loadSessions();
    } on ApiException catch (e) {
      _setState(SessionsError(e.message));
    } catch (e) {
      _setState(SessionsError(e.toString()));
    }
  }
}
