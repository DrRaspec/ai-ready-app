import 'dart:io';
import 'package:ai_chat_bot/features/chat/data/models/chat_mode.dart';
import 'package:ai_chat_bot/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:ai_chat_bot/features/chat/presentation/bloc/chat_event.dart';
import 'package:ai_chat_bot/features/chat/presentation/bloc/chat_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'photo_picker_sheet.dart';

class MediaSheet extends StatefulWidget {
  final ScrollController scrollController;

  const MediaSheet({super.key, required this.scrollController});

  @override
  State<MediaSheet> createState() => _MediaSheetState();
}

class _MediaSheetState extends State<MediaSheet> {
  List<AssetEntity> _images = [];
  bool _isLoadingImages = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoadImages();
  }

  Future<void> _checkPermissionAndLoadImages() async {
    // Check current status first
    PermissionState ps = await PhotoManager.requestPermissionExtend();

    // If not authorized, try requesting again
    if (!ps.isAuth) {
      ps = await PhotoManager.requestPermissionExtend();
    }

    if (ps.isAuth || ps == PermissionState.limited) {
      if (mounted) {
        setState(() => _hasPermission = true);
        _loadImages();
      }
    } else {
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _isLoadingImages = false;
        });
      }
    }
  }

  Future<void> _loadImages() async {
    try {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );

      if (albums.isNotEmpty) {
        final recentAlbum = albums.first;
        final recentImages = await recentAlbum.getAssetListRange(
          start: 0,
          end: 50,
        );

        if (mounted) {
          setState(() {
            _images = recentImages;
            _isLoadingImages = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingImages = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingImages = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Photo Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Photos',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => DraggableScrollableSheet(
                      initialChildSize: 0.9,
                      minChildSize: 0.5,
                      maxChildSize: 0.95,
                      builder: (context, scrollController) => PhotoPickerSheet(
                        onSelected: (files) {
                          // Handle selection
                          for (final file in files) {
                            context.read<ChatBloc>().add(
                              AttachImage(file.path),
                            );
                          }
                          Navigator.pop(context); // Close picker
                          Navigator.pop(context); // Close media sheet
                        },
                      ),
                    ),
                  );
                },
                child: const Text('All Photos'),
              ),
            ],
          ),

          // Photo Strip (Horizontal Scrolling inside Vertical List)
          SizedBox(
            height: 120,
            child: _isLoadingImages
                ? Skeletonizer(
                    enabled: true,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : !_hasPermission
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Permission required'),
                        TextButton(
                          onPressed: () {
                            PhotoManager.openSetting(); // Open app settings
                            _checkPermissionAndLoadImages(); // Retry after return
                          },
                          child: const Text('Open Settings'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(), // Prevent conflict
                    itemCount: _images.length + 1, // +1 for Camera
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildCameraItem(context),
                        );
                      }
                      final asset = _images[index - 1];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildImageItem(context, asset),
                      );
                    },
                  ),
          ),

          const Divider(height: 32),

          // Chat Modes Header
          Text(
            'Chat Modes',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Chat Mode Items (Direct children of main ListView)
          ...ChatMode.values.map((mode) => _buildModeItem(context, mode)),
        ],
      ),
    );
  }

  Widget _buildCameraItem(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(12),
          child: Icon(
            Icons.camera_alt_outlined,
            color: Theme.of(context).colorScheme.onSurface,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildImageItem(BuildContext context, AssetEntity asset) {
    return AspectRatio(
      aspectRatio: 1,
      child: FutureBuilder<File?>(
        future: asset.file,
        builder: (context, snapshot) {
          final file = snapshot.data;

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[300],
                  image: file != null
                      ? DecorationImage(
                          image: FileImage(file),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      if (file != null) {
                        context.read<ChatBloc>().add(AttachImage(file.path));
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModeItem(BuildContext context, ChatMode mode) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final isSelected =
            state.chatMode == mode ||
            (state.chatMode == null && mode == ChatMode.general);
        final theme = Theme.of(context);

        return InkWell(
          onTap: () {
            context.read<ChatBloc>().add(SetChatMode(mode));
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: theme.colorScheme.primary)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  _getIconData(mode.iconName),
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        mode.systemPrompt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'code':
        return Icons.code;
      case 'edit_note':
        return Icons.edit_note;
      case 'short_text':
        return Icons.short_text;
      case 'image':
        return Icons.image;
      case 'brush':
        return Icons.brush;
      default:
        return Icons.chat_bubble_outline;
    }
  }
}
