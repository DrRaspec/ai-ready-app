import 'package:get/get.dart';
import 'package:ai_chat_bot/features/chat/data/folder_repository.dart';
import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'folder_state.dart';

class FolderController extends GetxController {
  final FolderRepository _repository;
  final Rx<FolderState> rxState;

  FolderState get state => rxState.value;

  void _setState(FolderState newState) {
    rxState.value = newState;
  }

  FolderController(this._repository) : rxState = FolderInitial().obs;

  Future<void> loadFolders() async {
    _setState(FolderLoading());
    try {
      final response = await _repository.getFolders();
      if (response.success && response.data != null) {
        _setState(FolderLoaded(response.data!));
      } else {
        _setState(FolderError(response.message ?? 'Failed to load folders'));
      }
    } on ApiException catch (e) {
      _setState(FolderError(e.message));
    }
  }

  Future<void> createFolder(String name, String color) async {
    try {
      final response = await _repository.createFolder(name, color);
      if (response.success) {
        // Reload folders
        loadFolders();
      }
    } on ApiException catch (e) {
      _setState(FolderError(e.message));
    }
  }

  Future<void> deleteFolder(String id) async {
    try {
      final response = await _repository.deleteFolder(id);
      if (response.success) {
        loadFolders();
      }
    } on ApiException catch (e) {
      _setState(FolderError(e.message));
    }
  }

  Future<void> renameFolder(String id, String newName) async {
    try {
      final response = await _repository.updateFolder(id, newName);
      if (response.success) {
        loadFolders();
      }
    } on ApiException catch (e) {
      _setState(FolderError(e.message));
    }
  }
}
