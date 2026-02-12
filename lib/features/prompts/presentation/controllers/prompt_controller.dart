import 'package:get/get.dart';
import 'package:ai_chat_bot/features/prompts/data/prompt_repository.dart';
import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'prompt_state.dart';

class PromptController extends GetxController {
  final PromptRepository _repository;
  final Rx<PromptState> rxState;

  PromptState get state => rxState.value;

  void _setState(PromptState newState) {
    rxState.value = newState;
  }

  PromptController(this._repository) : rxState = PromptInitial().obs;

  Future<void> loadPrompts() async {
    _setState(PromptLoading());
    try {
      final response = await _repository.getPrompts();
      if (response.success && response.data != null) {
        _setState(PromptLoaded(response.data!));
      } else {
        _setState(PromptError(response.message ?? 'Failed to load prompts'));
      }
    } on ApiException catch (e) {
      _setState(PromptError(e.message));
    }
  }

  Future<void> createPrompt(String title, String content) async {
    _setState(PromptLoading());
    try {
      await _repository.createPrompt(title, content);
      await loadPrompts(); // Reload
    } on ApiException catch (e) {
      _setState(PromptError(e.message));
    }
  }

  Future<void> enhance(String prompt) async {
    // Keep current list if possible?
    // For now simple state switch
    try {
      final response = await _repository.enhancePrompt(prompt);
      if (response.success && response.data != null) {
        _setState(PromptEnhanced(response.data!));
      } else {
        _setState(PromptError(response.message ?? 'Failed to enhance'));
      }
    } on ApiException catch (e) {
      _setState(PromptError(e.message));
    }
  }
}
