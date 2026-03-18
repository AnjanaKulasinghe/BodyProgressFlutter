import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:body_progress/core/design_system.dart';
import 'package:body_progress/core/toast_manager.dart';
import 'package:body_progress/models/user_profile.dart';
import 'package:body_progress/providers/profile_provider.dart';
import 'package:body_progress/widgets/loading_button.dart';

/// Edit profile view - allows users to update their profile information
class EditProfileView extends ConsumerStatefulWidget {
  const EditProfileView({super.key});
  
  @override
  ConsumerState<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends ConsumerState<EditProfileView> {
  @override
  void initState() {
    super.initState();
    // Load current profile data into the provider's edit state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).loadCurrentProfileForEdit();
    });
  }

  Future<void> _save() async {
    final ok = await ref.read(profileProvider.notifier).saveProfile();
    if (ok && mounted) {
      ToastManager.shared.show('Profile updated!', type: ToastType.success);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);

    ref.listen<ProfileState>(profileProvider, (_, next) {
      if (next.showingAlert && next.errorMessage != null) {
        ToastManager.shared.show(next.errorMessage!, type: ToastType.error);
        notifier.clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Info Section
            const Text('Basic Information', style: AppTextStyles.title3),
            const SizedBox(height: 16),
            _FormField(
              label: 'Full Name',
              initialValue: profileState.name,
              onChanged: notifier.setName,
            ),
            const SizedBox(height: 16),
            _FormField(
              label: 'Email',
              initialValue: profileState.email,
              keyboardType: TextInputType.emailAddress,
              onChanged: notifier.setEmail,
            ),
            const SizedBox(height: 16),
            const Text('Date of Birth',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontFamily: 'Nunito')),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: profileState.dateOfBirth,
                  firstDate: DateTime(1920),
                  lastDate: DateTime.now(),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme:
                          const ColorScheme.dark(primary: AppColors.brandPrimary),
                    ),
                    child: child!,
                  ),
                );
                if (date != null) notifier.setDateOfBirth(date);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkCardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.textTertiary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      '${profileState.dateOfBirth.day}/${profileState.dateOfBirth.month}/${profileState.dateOfBirth.year}',
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontFamily: 'Nunito'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Gender',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontFamily: 'Nunito')),
            const SizedBox(height: 8),
            Row(
              children: Gender.values
                  .map((g) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: g == Gender.male ? 8 : 0),
                          child: GestureDetector(
                            onTap: () => notifier.setGender(g),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: profileState.gender == g
                                    ? AppGradients.brand
                                    : null,
                                color: profileState.gender == g
                                    ? null
                                    : AppColors.darkCardBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(g.displayName,
                                    style: TextStyle(
                                      color: profileState.gender == g
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: profileState.gender == g
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      fontFamily: 'Nunito',
                                    )),
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 32),

            // Body Metrics Section
            const Text('Body Metrics', style: AppTextStyles.title3),
            const SizedBox(height: 16),
            _FormField(
              label: 'Height (cm)',
              initialValue: profileState.height,
              keyboardType: TextInputType.number,
              onChanged: notifier.setHeight,
            ),
            const SizedBox(height: 16),
            _FormField(
              label: 'Current Weight (kg)',
              initialValue: profileState.weight,
              keyboardType: TextInputType.number,
              onChanged: notifier.setWeight,
            ),
            const SizedBox(height: 16),
            const Text('Activity Level',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontFamily: 'Nunito')),
            const SizedBox(height: 8),
            ...ActivityLevel.values.map((level) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => notifier.setActivityLevel(level),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: profileState.activityLevel == level
                            ? AppGradients.brand
                            : null,
                        color: profileState.activityLevel == level
                            ? null
                            : AppColors.darkCardBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(level.displayName,
                          style: TextStyle(
                            color: profileState.activityLevel == level
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontFamily: 'Nunito',
                          )),
                    ),
                  ),
                )),
            const SizedBox(height: 32),

            // Goals Section
            const Text('Fitness Goal', style: AppTextStyles.title3),
            const SizedBox(height: 16),
            ...FitnessGoal.values.map((goal) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => notifier.setFitnessGoal(goal),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: profileState.fitnessGoal == goal
                            ? AppGradients.brand
                            : null,
                        color: profileState.fitnessGoal == goal
                            ? null
                            : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: profileState.fitnessGoal == goal
                              ? Colors.transparent
                              : Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (profileState.fitnessGoal == goal)
                            const Icon(Icons.check_circle,
                                color: Colors.white, size: 20)
                          else
                            const Icon(Icons.radio_button_unchecked,
                                color: AppColors.textTertiary, size: 20),
                          const SizedBox(width: 12),
                          Text(goal.displayName,
                              style: TextStyle(
                                color: profileState.fitnessGoal == goal
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: profileState.fitnessGoal == goal
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontFamily: 'Nunito',
                                fontSize: 15,
                              )),
                        ],
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 16),
            _FormField(
              label: 'Target Weight (kg) - optional',
              initialValue: profileState.targetWeight,
              keyboardType: TextInputType.number,
              onChanged: notifier.setTargetWeight,
            ),
            const SizedBox(height: 32),

            // Save Button
            LoadingButton(
              label: 'Save Changes',
              isLoading: profileState.isLoading,
              onPressed: _save,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String initialValue;
  final TextInputType? keyboardType;
  final void Function(String) onChanged;

  const _FormField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
            fontSize: 15,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.darkCardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.brandPrimary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
