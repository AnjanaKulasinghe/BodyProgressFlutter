import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:body_progress/core/design_system.dart';
import 'package:body_progress/core/router.dart';
import 'package:body_progress/core/toast_manager.dart';
import 'package:body_progress/models/photo_metadata.dart';
import 'package:body_progress/providers/photo_provider.dart';
import 'package:body_progress/services/storage_service.dart';

class PhotosView extends ConsumerStatefulWidget {
  const PhotosView({super.key});
  @override
  ConsumerState<PhotosView> createState() => _PhotosViewState();
}

class _PhotosViewState extends ConsumerState<PhotosView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const _types = [PhotoType.front, PhotoType.side, PhotoType.back, PhotoType.custom];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _types.length, vsync: this);
    // Load photos after the first frame so the provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(photoProvider.notifier).loadPhotos();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photoState = ref.watch(photoProvider);

    ref.listen(photoProvider, (_, next) {
      if (next.showingAlert && next.errorMessage != null) {
        ToastManager.shared.show(next.errorMessage!, type: ToastType.error);
        ref.read(photoProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        title: const Text('Progress Photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare),
            tooltip: 'Compare Photos',
            onPressed: () => context.go(AppRoutes.photoCompare),
          ),
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined),
            onPressed: () => context.go(AppRoutes.photoUpload),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _types.map((t) => Tab(text: t.displayName)).toList(),
          isScrollable: true,
          indicatorColor: AppColors.brandPrimary,
          labelColor: AppColors.brandPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          dividerColor: Colors.transparent,
        ),
      ),
      body: photoState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
          : TabBarView(
              controller: _tabController,
              children: _types.map((type) {
                // Use photoState.photos directly (already watched) so grid rebuilds on load
                final photos = photoState.photos.where((p) => p.photoType == type).toList();
                return photos.isEmpty
                    ? _EmptyPhotoState(type: type)
                    : _PhotoGrid(photos: photos);
              }).toList(),
            ),
    );
  }
}

class _PhotoGrid extends ConsumerWidget {
  final List<PhotoMetadata> photos;
  const _PhotoGrid({required this.photos});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 0.75,
      ),
      itemCount: photos.length,
      itemBuilder: (_, i) => _PhotoTile(photo: photos[i]),
    );
  }
}

class _PhotoTile extends ConsumerWidget {
  final PhotoMetadata photo;
  const _PhotoTile({required this.photo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _openFullScreen(context),
      onLongPress: () => _showDeleteDialog(context, ref),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<String>(
              future: StorageService().getFreshThumbnailUrl(photo),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    color: AppColors.darkCardBackground,
                    child: const Center(child: CircularProgressIndicator(
                      color: AppColors.brandPrimary, strokeWidth: 2)),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Container(
                    color: AppColors.darkCardBackground,
                    child: const Icon(Icons.broken_image, color: AppColors.textTertiary),
                  );
                }
                return CachedNetworkImage(
                  imageUrl: snapshot.data!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.darkCardBackground,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.darkCardBackground,
                    child: const Icon(Icons.broken_image, color: AppColors.textTertiary),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                child: Text(
                  photo.formattedDate,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'Nunito'),
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _PhotoDetailPage(photo: photo),
    ));
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Photo', style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito')),
        content: const Text('Are you sure you want to delete this photo?',
            style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Nunito')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(photoProvider.notifier).deletePhoto(photo);
              ToastManager.shared.show('Photo deleted', type: ToastType.success);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }
}

class _PhotoDetailPage extends StatelessWidget {
  final PhotoMetadata photo;
  const _PhotoDetailPage({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(photo.formattedDate,
            style: const TextStyle(color: Colors.white, fontFamily: 'Nunito')),
        actions: [
          if (photo.weight != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('${photo.weight!.toStringAsFixed(1)} kg',
                    style: const TextStyle(color: Colors.white70, fontFamily: 'Nunito')),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: FutureBuilder<String>(
                  future: StorageService().getFreshDownloadUrl(photo.storagePath),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.brandPrimary));
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(
                        child: Icon(Icons.broken_image, color: Colors.white54, size: 64));
                    }
                    return CachedNetworkImage(
                      imageUrl: snapshot.data!,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(color: AppColors.brandPrimary)),
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.white54, size: 64)),
                    );
                  },
                ),
              ),
            ),
          ),
          if (photo.notes != null && photo.notes!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1A1A1A),
              child: Text(photo.notes!,
                  style: const TextStyle(
                      color: Colors.white70, fontFamily: 'Nunito', fontSize: 14)),
            ),
        ],
      ),
    );
  }
}

class _EmptyPhotoState extends StatelessWidget {
  final PhotoType type;
  const _EmptyPhotoState({required this.type});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_a_photo_outlined, color: AppColors.brandPrimary, size: 36),
          ),
          const SizedBox(height: 16),
          Text('No ${type.displayName} photos yet',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16, fontFamily: 'Nunito')),
          const SizedBox(height: 8),
          const Text('Tap the + button to add your first photo',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 14, fontFamily: 'Nunito')),
        ],
      ),
    );
  }
}
