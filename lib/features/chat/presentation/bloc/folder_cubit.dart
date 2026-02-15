import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_chat_bot/features/chat/data/folder_repository.dart';
import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'folder_state.dart';

class FolderCubit extends Cubit<FolderState> {
  final FolderRepository _repository;

  FolderCubit(this._repository) : super(FolderInitial());

  Future<void> loadFolders() async {
    emit(FolderLoading());
    try {
      final response = await _repository.getFolders();
      if (response.success && response.data != null) {
        emit(FolderLoaded(response.data!));
      } else {
        emit(FolderError(response.message ?? 'Failed to load folders'));
      }
    } on ApiException catch (e) {
      emit(FolderError(e.message));
    }
  }

  Future<void> createFolder(String name, {String? parentId}) async {
    try {
      final response = await _repository.createFolder(name, parentId: parentId);
      if (response.success) {
        // Reload folders
        loadFolders();
      }
    } on ApiException catch (e) {
      emit(FolderError(e.message));
    }
  }

  Future<void> deleteFolder(String id) async {
    try {
      final response = await _repository.deleteFolder(id);
      if (response.success) {
        loadFolders();
      }
    } on ApiException catch (e) {
      emit(FolderError(e.message));
    }
  }

  Future<void> renameFolder(String id, String newName) async {
    try {
      final response = await _repository.updateFolder(id, newName);
      if (response.success) {
        loadFolders();
      }
    } on ApiException catch (e) {
      emit(FolderError(e.message));
    }
  }
}
