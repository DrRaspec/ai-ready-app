import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_chat_bot/features/prompts/data/prompt_repository.dart';
import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'prompt_state.dart';

class PromptCubit extends Cubit<PromptState> {
  final PromptRepository _repository;

  PromptCubit(this._repository) : super(PromptInitial());

  Future<void> loadPrompts() async {
    emit(PromptLoading());
    try {
      final response = await _repository.getPrompts();
      if (response.success && response.data != null) {
        emit(PromptLoaded(response.data!));
      } else {
        emit(PromptError(response.message ?? 'Failed to load prompts'));
      }
    } on ApiException catch (e) {
      emit(PromptError(e.message));
    }
  }

  Future<void> createPrompt(String title, String content) async {
    emit(PromptLoading());
    try {
      await _repository.createPrompt(title, content);
      await loadPrompts(); // Reload
    } on ApiException catch (e) {
      emit(PromptError(e.message));
    }
  }

  Future<void> enhance(String prompt) async {
    // Keep current list if possible?
    // For now simple state switch
    try {
      final response = await _repository.enhancePrompt(prompt);
      if (response.success && response.data != null) {
        emit(PromptEnhanced(response.data!));
      } else {
        emit(PromptError(response.message ?? 'Failed to enhance'));
      }
    } on ApiException catch (e) {
      emit(PromptError(e.message));
    }
  }
}
