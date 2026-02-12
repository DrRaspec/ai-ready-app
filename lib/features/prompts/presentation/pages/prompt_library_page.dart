import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:ai_chat_bot/features/prompts/data/prompt_repository.dart';
import 'package:ai_chat_bot/features/prompts/presentation/controllers/prompt_controller.dart';
import 'package:ai_chat_bot/features/prompts/presentation/controllers/prompt_state.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PromptLibraryPage extends StatefulWidget {
  const PromptLibraryPage({super.key});

  @override
  State<PromptLibraryPage> createState() => _PromptLibraryPageState();
}

class _PromptLibraryPageState extends State<PromptLibraryPage> {
  late final PromptController _promptController;

  @override
  void initState() {
    super.initState();
    _promptController = Get.find<PromptController>();
    _promptController.loadPrompts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Prompt Library')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPromptDialog(context),
        label: const Text('New Prompt'),
        icon: const Icon(Icons.add),
      ),
      body: Obx(() {
        final PromptState state = _promptController.state;
        if (state is PromptLoading) {
          return Skeletonizer(
            enabled: true,
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => ListTile(
                title: const Text('Loading Prompt...'),
                subtitle: const Text('Description...'),
              ),
            ),
          );
        } else if (state is PromptError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(state.message),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _promptController.loadPrompts,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (state is PromptLoaded) {
          if (state.prompts.isEmpty) {
            return Center(
              child: Text(
                'No prompts yet. Create one!',
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
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: ListTile(
                  title: Text(
                    prompt['title'] ?? 'Untitled',
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
      }),
    );
  }

  void _showAddPromptDialog(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (context) => _AddPromptDialog(promptController: _promptController),
    );
  }
}

class _AddPromptDialog extends StatefulWidget {
  final PromptController promptController;

  const _AddPromptDialog({required this.promptController});

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
      title: const Text('New Prompt'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Coding Assistant',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Prompt Content',
                hintText: 'You are a helpful...',
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
                  label: const Text('Enhance with AI'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty &&
                _contentController.text.isNotEmpty) {
              widget.promptController.createPrompt(
                _titleController.text,
                _contentController.text,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
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
        ).showSnackBar(SnackBar(content: Text('Failed to enhance: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isEnhancing = false);
      }
    }
  }
}
