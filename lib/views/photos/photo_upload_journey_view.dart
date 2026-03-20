import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:body_progress/core/design_system.dart';
import 'package:body_progress/core/toast_manager.dart';
import 'package:body_progress/models/photo_metadata.dart';
import 'package:body_progress/providers/photo_provider.dart';
import 'package:body_progress/widgets/loading_button.dart';
import 'package:intl/intl.dart';

class PhotoUploadJourneyView extends ConsumerStatefulWidget {
  const PhotoUploadJourneyView({super.key});

  @override
  ConsumerState<PhotoUploadJourneyView> createState() => _PhotoUploadJourneyViewState();
}

class _PhotoUploadJourneyViewState extends ConsumerState<PhotoUploadJourneyView> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Upload data
  DateTime _selectedDate = DateTime.now();
  final Map<PhotoType, XFile?> _photos = {
    PhotoType.front: null,
    PhotoType.side: null,
    PhotoType.back: null,
    PhotoType.custom: null,
  };

  final List<_PhotoStep> _steps = [
    _PhotoStep(
      type: null,
      title: 'Select Date',
      description: 'Choose the date for your progress photos',
      sampleImage: null,
      instruction: 'Select when these photos were taken',
    ),
    _PhotoStep(
      type: PhotoType.front,
      title: 'Front View (Optional)',
      description: 'Stand straight, facing forward',
      sampleImage: 'assets/images/samples/sample-front.png',
      instruction: 'Position yourself directly facing the camera with arms at your sides',
    ),
    _PhotoStep(
      type: PhotoType.side,
      title: 'Side View (Optional)',
      description: 'Turn 90° to show your profile',
      sampleImage: 'assets/images/samples/sample-side.png',
      instruction: 'Stand sideways to the camera with good posture',
    ),
    _PhotoStep(
      type: PhotoType.back,
      title: 'Back View (Optional)',
      description: 'Turn around to show your back',
      sampleImage: 'assets/images/samples/sample-back.png',
      instruction: 'Face away from the camera with arms at your sides',
    ),
    _PhotoStep(
      type: PhotoType.custom,
      title: 'Custom View (Optional)',
      description: 'Add any additional angle',
      sampleImage: 'assets/images/samples/sample-custom.png',
      instruction: 'Capture any specific area you want to track',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      await _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      await _uploadPhotos();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceedFromStep(int step) {
    // All steps allow proceeding (all photo angles are optional)
    return true;
  }

  String _getButtonLabel(int step) {
    if (step == _steps.length - 1) {
      // Final step - check if we have at least one photo
      final hasPhotos = _photos.values.any((photo) => photo != null);
      return hasPhotos ? 'Upload Photos' : 'Need at least 1 photo';
    }
    
    // Photo steps - show Skip or Continue based on whether photo is captured
    if (step > 0) {
      final photoType = _steps[step].type;
      final hasPhoto = _photos[photoType] != null;
      return hasPhoto ? 'Continue' : 'Skip';
    }
    
    return 'Continue';
  }

  Future<void> _uploadPhotos() async {
    final notifier = ref.read(photoProvider.notifier);
    
    // Filter out null photos
    final photosToUpload = _photos.entries
        .where((entry) => entry.value != null)
        .toList();

    if (photosToUpload.isEmpty) {
      ToastManager.shared.show('Please add at least one photo', type: ToastType.error);
      return;
    }

    // Capture navigator before async gap
    if (!mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.brandPrimary),
        ),
      ),
    );

    try {
      bool allSuccess = true;
      for (final entry in photosToUpload) {
        // Upload photo using the new method that accepts file directly
        final file = File(entry.value!.path);
        final success = await notifier.uploadPhotoFromFile(
          file,
          entry.key,
          _selectedDate,
          '',
          '',
        );
        
        if (!success) {
          allSuccess = false;
          break;
        }
      }

      // Wait a frame to ensure dialog is fully rendered
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        // Close loading dialog
        navigator.pop();
        
        // Wait for dialog to fully dismiss
        await Future.delayed(const Duration(milliseconds: 200));
        
        if (mounted) {
          if (allSuccess) {
            ToastManager.shared.show(
              'Photos uploaded successfully!',
              type: ToastType.success,
            );
            context.pop(); // Return to photos view
          } else {
            ToastManager.shared.show(
              'Failed to upload some photos',
              type: ToastType.error,
            );
          }
        }
      }
    } catch (e) {
      print('Error uploading photos: $e');
      
      // Wait before dismissing on error
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        try {
          navigator.pop();
          
          // Wait for dialog to dismiss
          await Future.delayed(const Duration(milliseconds: 200));
          
          if (mounted) {
            ToastManager.shared.show(
              'Upload failed: ${e.toString()}',
              type: ToastType.error,
            );
          }
        } catch (_) {
          // Dialog might already be gone
        }
      }
    }
  }

  Future<void> _capturePhoto(PhotoType type) async {
    final ImagePicker picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.brandPrimary),
              title: const Text('Camera', style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito')),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.brandPrimary),
              title: const Text('Gallery', style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito')),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? photo = await picker.pickImage(
        source: source,
        imageQuality: 95,
      );
      
      if (photo != null) {
        setState(() {
          _photos[type] = photo;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        title: Text('Add Photos (${_currentStep + 1}/${_steps.length})'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: List.generate(_steps.length, (index) {
                final isCompleted = index < _currentStep;
                final isCurrent = index == _currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: index < _steps.length - 1 ? 8 : 0),
                    decoration: BoxDecoration(
                      gradient: isCompleted || isCurrent
                          ? AppGradients.brand
                          : null,
                      color: isCompleted || isCurrent
                          ? null
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Pages
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _steps.length,
              onPageChanged: (index) => setState(() => _currentStep = index),
              itemBuilder: (context, index) {
                final step = _steps[index];
                
                if (index == 0) {
                  return _DateSelectionStep(
                    selectedDate: _selectedDate,
                    onDateChanged: (date) => setState(() => _selectedDate = date),
                  );
                } else {
                  return _PhotoCaptureStep(
                    step: step,
                    photo: _photos[step.type!],
                    onCapture: () => _capturePhoto(step.type!),
                    onRetake: () => setState(() => _photos[step.type!] = null),
                  );
                }
              },
            ),
          ),

          // Bottom buttons
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
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.brandPrimary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back', style: TextStyle(fontFamily: 'Nunito', fontSize: 16)),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: _currentStep == 0 ? 1 : 2,
                    child: LoadingButton(
                      onPressed: _canProceedFromStep(_currentStep) && 
                               (_currentStep != _steps.length - 1 || _photos.values.any((photo) => photo != null))
                          ? _nextStep
                          : null,
                      label: _getButtonLabel(_currentStep),
                      isLoading: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoStep {
  final PhotoType? type;
  final String title;
  final String description;
  final String? sampleImage;
  final String instruction;

  const _PhotoStep({
    required this.type,
    required this.title,
    required this.description,
    required this.sampleImage,
    required this.instruction,
  });
}

class _DateSelectionStep extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const _DateSelectionStep({
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.calendar_today,
            size: 64,
            color: AppColors.brandPrimary,
          ),
          const SizedBox(height: 24),
          const Text(
            'When were these photos taken?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Select the date for your progress photos.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontFamily: 'Nunito',
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Date picker
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.brandPrimary,
                        onPrimary: Colors.white,
                        surface: AppColors.cardBackground,
                        onSurface: AppColors.textPrimary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                onDateChanged(date);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppShadows.medium,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected Date',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoCaptureStep extends StatelessWidget {
  final _PhotoStep step;
  final XFile? photo;
  final VoidCallback onCapture;
  final VoidCallback onRetake;

  const _PhotoCaptureStep({
    required this.step,
    required this.photo,
    required this.onCapture,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            step.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 24),

          // Instruction text above photo area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.brandPrimary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.brandPrimary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.instruction,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontFamily: 'Nunito',
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          // Combined photo area with sample as background and overlay
          if (step.sampleImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Background image (sample or captured photo)
                  photo == null
                      ? Image.asset(
                          step.sampleImage!,
                          height: 500,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(photo!.path),
                          height: 500,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                  
                  // Semi-transparent overlay (only show when no photo captured)
                  if (photo == null)
                    Container(
                      height: 500,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  
                  // Camera button (only show when no photo captured)
                  if (photo == null)
                    Positioned.fill(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: onCapture,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: AppGradients.brand,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.brandPrimary.withOpacity(0.5),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Tap to Capture Photo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Nunito',
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Choose camera or gallery',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontFamily: 'Nunito',
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Optional badge (top-left) - shown for all photo steps when no photo captured
                  if (photo == null)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Optional',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ),
                  
                  // Photo captured controls (show when photo is captured)
                  if (photo != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            // Success indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.successGreen.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.successGreen,
                                  width: 1.5,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, color: AppColors.successGreen, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Photo Captured',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: onRetake,
                                    icon: const Icon(Icons.refresh, size: 20),
                                    label: const Text('Retake'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Colors.white, width: 2),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: onCapture,
                                    icon: const Icon(Icons.photo_library, size: 20),
                                    label: const Text('Gallery'),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: AppColors.brandPrimary,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
