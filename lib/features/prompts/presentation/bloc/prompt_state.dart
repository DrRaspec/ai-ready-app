import 'package:equatable/equatable.dart';

abstract class PromptState extends Equatable {
  const PromptState();
  @override
  List<Object?> get props => [];
}

class PromptInitial extends PromptState {}

class PromptLoading extends PromptState {}

class PromptLoaded extends PromptState {
  final List<Map<String, dynamic>> prompts;
  const PromptLoaded(this.prompts);
  @override
  List<Object?> get props => [prompts];
}

class PromptError extends PromptState {
  final String message;
  const PromptError(this.message);
  @override
  List<Object?> get props => [message];
}

class PromptEnhanced extends PromptState {
  final String enhancedText;
  const PromptEnhanced(this.enhancedText);
  @override
  List<Object?> get props => [enhancedText];
}
