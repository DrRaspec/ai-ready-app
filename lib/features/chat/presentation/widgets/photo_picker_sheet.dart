import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoPickerSheet extends StatefulWidget {
  final Function(List<File>) onSelected;
  final int maxSelection;

  const PhotoPickerSheet({
    super.key,
    required this.onSelected,
    this.maxSelection = 3,
  });

  @override
  State<PhotoPickerSheet> createState() => _PhotoPickerSheetState();
}

class _PhotoPickerSheetState extends State<PhotoPickerSheet>
    with SingleTickerProviderStateMixin {
  List<AssetEntity> _images = [];
  List<AssetPathEntity> _albums = [];
  final Set<AssetEntity> _selectedImages = {};

  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 60;

  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  AssetPathEntity? _currentAlbum;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAlbumsAndImages();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadAlbumsAndImages() async {
    setState(() => _isLoading = true);
    try {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      );

      if (albums.isNotEmpty) {
        _albums = albums;
        // Default to "Recent" or first album
        await _selectAlbum(albums.first);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectAlbum(AssetPathEntity album) async {
    setState(() {
      _currentAlbum = album;
      _currentPage = 0;
      _images.clear();
      _isLoading = true;
    });

    try {
      final images = await album.getAssetListPaged(page: 0, size: _pageSize);

      if (mounted) {
        setState(() {
          _images = images;
          _isLoading = false;
          _hasMore = images.length == _pageSize;
          _currentPage = 1;
          // Switch back to Photos tab when an album is selected
          _tabController.animateTo(0);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_currentAlbum == null) return;
    setState(() => _isLoading = true);

    final images = await _currentAlbum!.getAssetListPaged(
      page: _currentPage,
      size: _pageSize,
    );

    if (mounted) {
      setState(() {
        _images.addAll(images);
        _isLoading = false;
        _hasMore = images.length == _pageSize;
        _currentPage++;
      });
    }
  }

  Future<void> _confirmSelection() async {
    final files = <File>[];
    for (var asset in _selectedImages) {
      final file = await asset.file;
      if (file != null) files.add(file);
    }
    widget.onSelected(files);
  }

  void _toggleSelection(AssetEntity asset) {
    setState(() {
      if (_selectedImages.contains(asset)) {
        _selectedImages.remove(asset);
      } else {
        if (_selectedImages.length < widget.maxSelection) {
          _selectedImages.add(asset);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Container(
                    height: 36,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: isDark ? Colors.grey[600] : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: isDark ? Colors.white : Colors.black,
                      unselectedLabelColor: isDark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                      labelStyle: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      tabs: const [
                        Tab(text: 'Photos'),
                        Tab(text: 'Collections'),
                      ],
                    ),
                  ),
                ),
                IconButton.filled(
                  onPressed: _selectedImages.isNotEmpty
                      ? _confirmSelection
                      : null,
                  icon: const Icon(Icons.check),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    disabledBackgroundColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),

          if (_tabController.index == 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Select up to ${widget.maxSelection} photos.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Grid View
                GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(2),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    if (index >= _images.length) return const SizedBox.shrink();
                    final asset = _images[index];
                    final isSelected = _selectedImages.contains(asset);
                    final selectionIndex =
                        _selectedImages.toList().indexOf(asset) + 1;

                    return GestureDetector(
                      onTap: () => _toggleSelection(asset),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _MediaThumbnail(asset: asset, size: 200),

                          // Selection Overlay (dim when selected)
                          if (isSelected)
                            Container(
                              color: Colors.black.withValues(alpha: 0.3),
                            ),

                          // Selection Checkbox (Top Right)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: isSelected
                                ? Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$selectionIndex',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Albums View
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _albums.length,
                  itemBuilder: (context, index) {
                    final album = _albums[index];
                    return FutureBuilder<int>(
                      future: album.assetCountAsync,
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return ListTile(
                          leading: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            // We could try to show the first image as thumbnail
                            child: const Icon(Icons.folder),
                          ),
                          title: Text(album.name),
                          subtitle: Text('$count'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _selectAlbum(album),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaThumbnail extends StatefulWidget {
  final AssetEntity asset;
  final int size;

  const _MediaThumbnail({required this.asset, required this.size});

  @override
  State<_MediaThumbnail> createState() => _MediaThumbnailState();
}

class _MediaThumbnailState extends State<_MediaThumbnail> {
  late Future<Uint8List?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = widget.asset.thumbnailDataWithSize(
      ThumbnailSize.square(widget.size),
    );
  }

  @override
  void didUpdateWidget(_MediaThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset || oldWidget.size != widget.size) {
      _thumbnailFuture = widget.asset.thumbnailDataWithSize(
        ThumbnailSize.square(widget.size),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _thumbnailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
        }
        return Container(color: Colors.grey[900]);
      },
    );
  }
}
