import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:ai_chat_bot/core/localization/app_text.dart';
import 'package:ai_chat_bot/features/prompts/data/prompt_repository.dart';
import 'package:ai_chat_bot/features/prompts/presentation/bloc/prompt_cubit.dart';
import 'package:ai_chat_bot/features/prompts/presentation/bloc/prompt_state.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PromptLibraryPage extends StatelessWidget {
  const PromptLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PromptCubit(GetIt.I<PromptRepository>())..loadPrompts(),
      child: const _PromptLibraryView(),
    );
  }
}

class _PromptLibraryView extends StatelessWidget {
  const _PromptLibraryView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(context.t.promptLibrary)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPromptDialog(context),
        label: Text(context.t.newPrompt),
        icon: const Icon(Icons.add),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.1),
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: BlocBuilder<PromptCubit, PromptState>(
          builder: (context, state) {
            if (state is PromptLoading) {
              return Skeletonizer(
                enabled: true,
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) => ListTile(
                    title: Text(context.t.tr('Loading Prompt...', 'កំពុងផ្ទុកពាក្យបញ្ជា...')),
                    subtitle: Text(context.t.tr('Description...', 'ការពិពណ៌នា...')),
                  ),
                ),
              );
            } else if (state is PromptError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          context.read<PromptCubit>().loadPrompts(),
                      child: Text(context.t.tr('Retry', 'សាកម្តងទៀត')),
                    ),
                  ],
                ),
              );
            } else if (state is PromptLoaded) {
              if (state.prompts.isEmpty) {
                return Center(
                  child: Text(
                    context.t.tr('No prompts yet. Create one!', 'មិនទាន់មានពាក្យបញ្ជាទេ។ បង្កើតមួយ!'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.prompts.length,
                itemBuilder: (context, index) {
                  final prompt = state.prompts[index];
                  return Card(
                    elevation: 0,
                    color: colorScheme.surface.withValues(alpha: 0.9),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        (prompt['name'] ??
                                prompt['title'] ??
                                context.t.tr('Untitled', 'គ្មានចំណងជើង'))
                            .toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        prompt['content'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        // TODO: Select logic or edit
                      },
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showAddPromptDialog(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (context) =>
          _AddPromptDialog(promptCubit: parentContext.read<PromptCubit>()),
    );
  }
}

class _AddPromptDialog extends StatefulWidget {
  final PromptCubit promptCubit;

  const _AddPromptDialog({required this.promptCubit});

  @override
  State<_AddPromptDialog> createState() => _AddPromptDialogState();
}

class _AddPromptDialogState extends State<_AddPromptDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isEnhancing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.t.newPrompt),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: context.t.tr('Title', 'ចំណងជើង'),
                hintText: context.t.tr('e.g., Coding Assistant', 'ឧ. ជំនួយការកូដ'),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: context.t.tr('Prompt Content', 'មាតិកាពាក្យបញ្ជា'),
                hintText: context.t.tr('You are a helpful...', 'អ្នកជាជំនួយការដែលមានប្រយោជន៍...'),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),
            if (_isEnhancing)
              const LinearProgressIndicator()
            else
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _enhancePrompt,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(context.t.tr('Enhance with AI', 'ធ្វើឱ្យប្រសើរដោយ AI')),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.t.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty &&
                _contentController.text.isNotEmpty) {
              widget.promptCubit.createPrompt(
                _titleController.text,
                _contentController.text,
              );
              Navigator.pop(context);
            }
          },
          child: Text(context.t.save),
        ),
      ],
    );
  }

  Future<void> _enhancePrompt() async {
    final text = _contentController.text;
    if (text.isEmpty) return;

    setState(() => _isEnhancing = true);

    try {
      final repo = GetIt.I<PromptRepository>();
      final result = await repo.enhancePrompt(text);
      if (mounted && result.data != null) {
        _contentController.text = result.data!;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              context.t.tr('Failed to enhance: $e', 'មិនអាចធ្វើឱ្យប្រសើរបាន: $e'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEnhancing = false);
      }
    }
  }
}
