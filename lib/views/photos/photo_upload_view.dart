import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:body_progress/core/design_system.dart';
import 'package:body_progress/core/toast_manager.dart';
import 'package:body_progress/models/photo_metadata.dart';
import 'package:body_progress/providers/photo_provider.dart';
import 'package:body_progress/widgets/loading_button.dart';
import 'package:intl/intl.dart';

class PhotoUploadView extends ConsumerWidget {
  const PhotoUploadView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoState = ref.watch(photoProvider);
    final notifier = ref.read(photoProvider.notifier);

    ref.listen(photoProvider, (_, next) {
      if (next.showingAlert && next.errorMessage != null) {
        ToastManager.shared.show(next.errorMessage!, type: ToastType.error);
        notifier.clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(title: const Text('Add Photo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview / Picker
            GestureDetector(
              onTap: () => _showImageSourceDialog(context, notifier),
              child: Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  border: Border.all(
                    color: photoState.selectedImage != null
                        ? AppColors.brandPrimary
                        : Colors.white.withOpacity(0.1),
                    width: 2,
                  ),
                ),
                child: photoState.selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.large - 2),
                        child: Image.file(
                          File(photoState.selectedImage!.path),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              color: AppColors.brandPrimary, size: 48),
                          const SizedBox(height: 12),
                          const Text('Tap to add photo',
                              style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Nunito', fontSize: 16)),
                          const SizedBox(height: 6),
                          const Text('Camera or Gallery',
                              style: TextStyle(color: AppColors.textTertiary, fontFamily: 'Nunito', fontSize: 13)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Photo Type
            const Text('Photo Type',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontFamily: 'Nunito')),
            const SizedBox(height: 8),
            Row(
              children: PhotoType.values.map((t) {
                final isSelected = photoState.selectedPhotoType == t;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: t != PhotoType.values.last ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => notifier.setPhotoType(t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppGradients.brand : null,
                          color: isSelected ? null : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(t.displayName,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontFamily: 'Nunito', fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              )),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),

            // Date
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: photoState.photoDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(primary: AppColors.brandPrimary),
                    ),
                    child: child!,
                  ),
                );
                if (d != null) notifier.setPhotoDate(d);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: AppColors.textTertiary, size: 20),
                    const SizedBox(width: 12),
                    Text(DateFormat.yMMMMd().format(photoState.photoDate),
                        style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Weight & Notes
            TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: notifier.setPhotoWeight,
              style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito'),
              decoration: const InputDecoration(labelText: 'Weight at time (kg) — optional'),
            ),
            const SizedBox(height: 12),
            TextField(
              maxLines: 3,
              onChanged: notifier.setPhotoNotes,
              style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito'),
              decoration: const InputDecoration(labelText: 'Notes — optional'),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Upload progress
            if (photoState.isUploading)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: photoState.uploadProgress,
                        backgroundColor: AppColors.darkCardBackground,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Uploading… ${(photoState.uploadProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Nunito')),
                  ],
                ),
              ),

            LoadingButton(
              label: 'Upload Photo',
              isLoading: photoState.isUploading,
              onPressed: photoState.selectedImage == null
                  ? null
                  : () async {
                      final ok = await notifier.uploadPhoto();
                      if (ok && context.mounted) {
                        ToastManager.shared.show('Photo uploaded!', type: ToastType.success);
                        context.pop();
                      }
                    },
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context, PhotoNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.textPrimary),
              title: const Text('Camera', style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito')),
              onTap: () { Navigator.pop(context); notifier.pickImageFromCamera(); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.textPrimary),
              title: const Text('Gallery', style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito')),
              onTap: () { Navigator.pop(context); notifier.pickImageFromGallery(); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
