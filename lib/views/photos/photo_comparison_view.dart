import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:body_progress/core/design_system.dart';
import 'package:body_progress/models/photo_metadata.dart';
import 'package:body_progress/providers/photo_provider.dart';

class PhotoComparisonView extends ConsumerStatefulWidget {
  const PhotoComparisonView({super.key});

  @override
  ConsumerState<PhotoComparisonView> createState() => _PhotoComparisonViewState();
}

class _PhotoComparisonViewState extends ConsumerState<PhotoComparisonView> 
    with SingleTickerProviderStateMixin {
  int _beforeIndex = 0;
  int _afterIndex = 0;
  bool _showSlider = false;
  double _sliderValue = 0.5;
  late TabController _tabController;
  static const _types = [PhotoType.front, PhotoType.side, PhotoType.back, PhotoType.custom];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _types.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(photoProvider.notifier).loadComparisonPhotos(_types[_tabController.index]);
        // Reset indices when switching types - will be properly initialized in build
        setState(() {
          _beforeIndex = 0;
          _afterIndex = 0;
          _isInitialized = false;
        });
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(photoProvider.notifier).loadComparisonPhotos(PhotoType.front);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeIndices(List<PhotoMetadata> photos) {
    if (photos.length >= 2 && !_isInitialized) {
      // Set to different photos immediately
      _afterIndex = 0; // Most recent (first in list after sorting)
      _beforeIndex = photos.length - 1; // Oldest (last in list)
      _isInitialized = true;
      
      // Debug: Verify indices are different
      print('Photo Comparison Initialized: beforeIndex=$_beforeIndex (${photos[_beforeIndex].formattedDate}), afterIndex=$_afterIndex (${photos[_afterIndex].formattedDate})');
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoState = ref.watch(photoProvider);
    final photos = photoState.comparisonPhotos;

    // Initialize indices to show different photos
    _initializeIndices(photos);
    
    if (photos.isNotEmpty) {
      _beforeIndex = _beforeIndex.clamp(0, photos.length - 1);
      _afterIndex = _afterIndex.clamp(0, photos.length - 1);
    }

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        title: const Text('Compare Photos'),
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
      body: photos.isEmpty || photos.length < 2
          ? _EmptyComparison(type: _types[_tabController.index])
          : Column(
              children: [
                // Mode toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Text(
                        'Side by Side', 
                        style: TextStyle(
                          color: AppColors.textSecondary, 
                          fontFamily: 'Nunito',
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _showSlider,
                        onChanged: (v) => setState(() => _showSlider = v),
                        activeColor: AppColors.brandPrimary,
                      ),
                      const Text(
                        'Slider', 
                        style: TextStyle(
                          color: AppColors.textSecondary, 
                          fontFamily: 'Nunito',
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Comparison area with arrow navigation
                Expanded(
                  child: _showSlider
                      ? _SliderComparisonWithNav(
                          photos: photos,
                          beforeIndex: _beforeIndex,
                          afterIndex: _afterIndex,
                          sliderValue: _sliderValue,
                          onSliderChanged: (v) => setState(() => _sliderValue = v),
                          onBeforeChanged: (delta) {
                            final newIndex = (_beforeIndex + delta).clamp(0, photos.length - 1);
                            if (newIndex != _beforeIndex) {
                              setState(() => _beforeIndex = newIndex);
                            }
                          },
                          onAfterChanged: (delta) {
                            final newIndex = (_afterIndex + delta).clamp(0, photos.length - 1);
                            if (newIndex != _afterIndex) {
                              setState(() => _afterIndex = newIndex);
                            }
                          },
                        )
                      : _SideBySideWithNav(
                          photos: photos,
                          beforeIndex: _beforeIndex,
                          afterIndex: _afterIndex,
                          onBeforeChanged: (delta) {
                            final newIndex = (_beforeIndex + delta).clamp(0, photos.length - 1);
                            if (newIndex != _beforeIndex) {
                              setState(() => _beforeIndex = newIndex);
                            }
                          },
                          onAfterChanged: (delta) {
                            final newIndex = (_afterIndex + delta).clamp(0, photos.length - 1);
                            if (newIndex != _afterIndex) {
                              setState(() => _afterIndex = newIndex);
                            }
                          },
                        ),
                ),
                
                // Date info at bottom
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'BEFORE',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Nunito',
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              photos[_beforeIndex].formattedDate,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'AFTER',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Nunito',
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              photos[_afterIndex].formattedDate,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// Side-by-side comparison with arrow navigation
class _SideBySideWithNav extends StatelessWidget {
  final List<PhotoMetadata> photos;
  final int beforeIndex;
  final int afterIndex;
  final ValueChanged<int> onBeforeChanged;
  final ValueChanged<int> onAfterChanged;

  const _SideBySideWithNav({
    required this.photos,
    required this.beforeIndex,
    required this.afterIndex,
    required this.onBeforeChanged,
    required this.onAfterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PhotoPaneWithNav(
            photo: photos[beforeIndex],
            label: 'Before',
            canGoPrev: beforeIndex < photos.length - 1,
            canGoNext: beforeIndex > 0,
            onPrev: () => onBeforeChanged(1),
            onNext: () => onBeforeChanged(-1),
          ),
        ),
        Container(width: 3, decoration: BoxDecoration(
          color: AppColors.brandPrimary,
          boxShadow: [
            BoxShadow(
              color: AppColors.brandPrimary.withOpacity(0.5),
              blurRadius: 8,
            ),
          ],
        )),
        Expanded(
          child: _PhotoPaneWithNav(
            photo: photos[afterIndex],
            label: 'After',
            canGoPrev: afterIndex < photos.length - 1,
            canGoNext: afterIndex > 0,
            onPrev: () => onAfterChanged(1),
            onNext: () => onAfterChanged(-1),
          ),
        ),
      ],
    );
  }
}

// Slider comparison with arrow navigation
class _SliderComparisonWithNav extends StatelessWidget {
  final List<PhotoMetadata> photos;
  final int beforeIndex;
  final int afterIndex;
  final double sliderValue;
  final ValueChanged<double> onSliderChanged;
  final ValueChanged<int> onBeforeChanged;
  final ValueChanged<int> onAfterChanged;

  const _SliderComparisonWithNav({
    required this.photos,
    required this.beforeIndex,
    required this.afterIndex,
    required this.sliderValue,
    required this.onSliderChanged,
    required this.onBeforeChanged,
    required this.onAfterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (d) {
        final width = MediaQuery.of(context).size.width;
        final newValue = (sliderValue + d.delta.dx / width).clamp(0.0, 1.0);
        onSliderChanged(newValue);
      },
      child: LayoutBuilder(
        builder: (_, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Background: Before image (always fully visible)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: photos[beforeIndex].storageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 1200,
                  placeholder: (context, url) => Container(
                    color: AppColors.cardBackground,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.brandPrimary),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.cardBackground,
                    child: const Icon(Icons.error, color: AppColors.errorRed, size: 48),
                  ),
                ),
              ),
              
              // Foreground: After image (clipped to reveal Before image below)
              Positioned.fill(
                child: ClipRect(
                  clipper: _SliderClipper(sliderValue),
                  child: CachedNetworkImage(
                    imageUrl: photos[afterIndex].storageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 1200,
                    placeholder: (context, url) => Container(
                      color: AppColors.cardBackground.withOpacity(0.5),
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.brandPrimary),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.cardBackground.withOpacity(0.5),
                      child: const Icon(Icons.error, color: AppColors.errorRed, size: 48),
                    ),
                  ),
                ),
              ),
              
              // Slider handle with divider line
              Positioned(
                left: constraints.maxWidth * sliderValue - 20,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  width: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Vertical line
                      Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: AppShadows.medium,
                        ),
                      ),
                      // Circular handle
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.medium,
                        ),
                        child: const Icon(
                          Icons.compare_arrows,
                          color: AppColors.brandPrimary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Navigation arrows for Before (right side)
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (beforeIndex > 0)
                        _NavButton(
                          icon: Icons.arrow_upward,
                          onTap: () => onBeforeChanged(-1),
                        ),
                      const SizedBox(height: 12),
                      if (beforeIndex < photos.length - 1)
                        _NavButton(
                          icon: Icons.arrow_downward,
                          onTap: () => onBeforeChanged(1),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Navigation arrows for After (left side)
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (afterIndex > 0)
                        _NavButton(
                          icon: Icons.arrow_upward,
                          onTap: () => onAfterChanged(-1),
                        ),
                      const SizedBox(height: 12),
                      if (afterIndex < photos.length - 1)
                        _NavButton(
                          icon: Icons.arrow_downward,
                          onTap: () => onAfterChanged(1),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Labels with dates
              Positioned(
                bottom: 16,
                left: 16,
                child: _PhotoLabelWithDate(
                  text: 'After',
                  date: photos[afterIndex].formattedDate,
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: _PhotoLabelWithDate(
                  text: 'Before',
                  date: photos[beforeIndex].formattedDate,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Photo pane with navigation arrows
class _PhotoPaneWithNav extends StatelessWidget {
  final PhotoMetadata photo;
  final String label;
  final bool canGoPrev;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _PhotoPaneWithNav({
    required this.photo,
    required this.label,
    required this.canGoPrev,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: photo.storageUrl,
          fit: BoxFit.cover,
          memCacheWidth: 1200,
          placeholder: (context, url) => Container(
            color: AppColors.cardBackground,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.brandPrimary),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: AppColors.cardBackground,
            child: const Icon(Icons.error, color: AppColors.errorRed, size: 48),
          ),
        ),
        
        // Label at top
        Positioned(
          top: 12,
          left: 12,
          child: _PhotoLabel(text: label),
        ),
        
        // Navigation arrows
        Positioned.fill(
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (canGoNext)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: _NavButton(
                      icon: Icons.arrow_back_ios_new,
                      onTap: onNext,
                    ),
                  )
                else
                  const SizedBox(width: 60),
                if (canGoPrev)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _NavButton(
                      icon: Icons.arrow_forward_ios,
                      onTap: onPrev,
                    ),
                  )
                else
                  const SizedBox(width: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Navigation button widget
class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.brandPrimary.withOpacity(0.8),
            width: 2,
          ),
          boxShadow: AppShadows.medium,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

// Photo label widget
class _PhotoLabel extends StatelessWidget {
  final String text;

  const _PhotoLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.brandPrimary.withOpacity(0.6),
          width: 1.5,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          fontFamily: 'Nunito',
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// Photo label with date for slider comparison
class _PhotoLabelWithDate extends StatelessWidget {
  final String text;
  final String date;

  const _PhotoLabelWithDate({required this.text, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.brandPrimary.withOpacity(0.8),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFamily: 'Nunito',
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            date,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }
}

class _SideBySide extends StatelessWidget {
  final PhotoMetadata before;
  final PhotoMetadata after;
  const _SideBySide({required this.before, required this.after});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _PhotoPane(photo: before, label: 'Before')),
        Container(width: 2, color: AppColors.brandPrimary),
        Expanded(child: _PhotoPane(photo: after, label: 'After')),
      ],
    );
  }
}

class _SliderComparison extends StatelessWidget {
  final PhotoMetadata before;
  final PhotoMetadata after;
  final double sliderValue;
  final ValueChanged<double> onSliderChanged;
  const _SliderComparison({required this.before, required this.after,
      required this.sliderValue, required this.onSliderChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (d) {
        final width = MediaQuery.of(context).size.width;
        final newValue = (sliderValue + d.delta.dx / width).clamp(0.0, 1.0);
        onSliderChanged(newValue);
      },
      child: LayoutBuilder(
        builder: (_, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Background: Before image (always visible on right side)
              CachedNetworkImage(
                imageUrl: before.storageUrl, 
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.cardBackground,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.brandPrimary),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.cardBackground,
                  child: const Icon(Icons.error, color: AppColors.errorRed),
                ),
              ),
              // Foreground: After image (revealed from left as slider moves right)
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: sliderValue,
                  child: CachedNetworkImage(
                    imageUrl: after.storageUrl,
                    fit: BoxFit.cover,
                    width: constraints.maxWidth,
                    placeholder: (context, url) => Container(
                      color: AppColors.cardBackground,
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.brandPrimary),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.cardBackground,
                      child: const Icon(Icons.error, color: AppColors.errorRed),
                    ),
                  ),
                ),
              ),
              // Slider handle with divider line
              Positioned(
                left: constraints.maxWidth * sliderValue - 20,
                top: 0, 
                bottom: 0,
                child: SizedBox(
                  width: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Vertical line
                      Container(
                        width: 3, 
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: AppShadows.medium,
                        ),
                      ),
                      // Circular handle
                      Container(
                        width: 40, 
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.medium,
                        ),
                        child: const Icon(
                          Icons.compare_arrows, 
                          color: AppColors.brandPrimary, 
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Labels for Before/After
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'After',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Before',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PhotoPane extends StatelessWidget {
  final PhotoMetadata photo;
  final String label;
  const _PhotoPane({required this.photo, required this.label});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(imageUrl: photo.storageUrl, fit: BoxFit.cover),
        Positioned(
          top: 8, left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Nunito')),
          ),
        ),
        Positioned(
          bottom: 8, right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
            child: Text(photo.formattedDate,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Nunito')),
          ),
        ),
      ],
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final String label;
  final List<PhotoMetadata> photos;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  const _PhotoPicker({required this.label, required this.photos,
      required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: selectedIndex,
      dropdownColor: AppColors.cardBackground,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: photos.asMap().entries.map((e) => DropdownMenuItem(
        value: e.key,
        child: Text(e.value.formattedDate,
            style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito', fontSize: 13)),
      )).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}

class _EmptyComparison extends StatelessWidget {
  final PhotoType type;
  const _EmptyComparison({required this.type});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.compare, color: AppColors.textTertiary, size: 64),
          const SizedBox(height: 16),
          Text('Not enough ${type.displayName} photos',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 17, fontFamily: 'Nunito')),
          const SizedBox(height: 8),
          const Text('Add at least 2 photos to compare',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 14, fontFamily: 'Nunito')),
        ],
      ),
    );
  }
}

// Custom clipper for slider comparison
class _SliderClipper extends CustomClipper<Rect> {
  final double sliderPosition;

  _SliderClipper(this.sliderPosition);

  @override
  Rect getClip(Size size) {
    // Clip from left to the slider position
    // This reveals the image underneath from right to left as slider moves left
    return Rect.fromLTRB(0, 0, size.width * sliderPosition, size.height);
  }

  @override
  bool shouldReclip(_SliderClipper oldClipper) {
    return oldClipper.sliderPosition != sliderPosition;
  }
}
