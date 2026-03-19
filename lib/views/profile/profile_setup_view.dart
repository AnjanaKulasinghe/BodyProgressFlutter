import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:body_progress/core/design_system.dart';
import 'package:body_progress/core/router.dart';
import 'package:body_progress/core/toast_manager.dart';
import 'package:body_progress/models/user_profile.dart';
import 'package:body_progress/providers/profile_provider.dart';
import 'package:body_progress/widgets/loading_button.dart';

/// Multi-step profile setup wizard for new users, matching iOS ProfileSetupView.
class ProfileSetupView extends ConsumerStatefulWidget {
  const ProfileSetupView({super.key});
  @override
  ConsumerState<ProfileSetupView> createState() => _ProfileSetupViewState();
}

class _ProfileSetupViewState extends ConsumerState<ProfileSetupView> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const _totalSteps = 3;

  @override
  void initState() {
    super.initState();
    // Ensure profile state is initialized with user's auth data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileState = ref.read(profileProvider);
      if (profileState.name.isEmpty || profileState.email.isEmpty) {
        ref.read(profileProvider.notifier).loadProfile();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    }
  }

  Future<void> _submit() async {
    try {
      final ok = await ref.read(profileProvider.notifier).saveProfile();
      if (ok && mounted) {
        ToastManager.shared.show('Profile created!', type: ToastType.success);
        // Small delay to ensure Firestore write completes before navigation
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ToastManager.shared.show('Error creating profile: $e', type: ToastType.error);
      }
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
        backgroundColor: AppColors.appBackground,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
                onPressed: _prevStep)
            : null,
        title: Text(
          'Step ${_currentStep + 1} of $_totalSteps',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, fontFamily: 'Nunito'),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: AppColors.darkCardBackground,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
                minHeight: 4,
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _BasicInfoStep(notifier: notifier, state: profileState),
                _BodyMetricsStep(notifier: notifier, state: profileState),
                _GoalsStep(notifier: notifier, state: profileState),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: LoadingButton(
              label: _currentStep < _totalSteps - 1 ? 'Continue' : 'Complete Setup',
              isLoading: profileState.isLoading,
              onPressed: () async => _nextStep(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BasicInfoStep extends StatelessWidget {
  final ProfileNotifier notifier;
  final ProfileState state;
  const _BasicInfoStep({required this.notifier, required this.state});

  @override
  Widget build(BuildContext context) {
    // Check if name and email are pre-filled (from Sign in with Apple or Google)
    final hasPrefilledName = state.name.isNotEmpty && state.isNewProfile;
    final hasPrefilledEmail = state.email.isNotEmpty && state.isNewProfile;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tell us about yourself', style: AppTextStyles.title2),
          const SizedBox(height: 8),
          const Text('This helps us personalise your experience',
              style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Nunito')),
          const SizedBox(height: 32),
          _FormField(
            label: 'Full Name', 
            initialValue: state.name, 
            onChanged: notifier.setName,
            enabled: !hasPrefilledName,
            helperText: hasPrefilledName ? 'Provided by Sign in with Apple' : null,
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'Email', 
            initialValue: state.email,
            keyboardType: TextInputType.emailAddress, 
            onChanged: notifier.setEmail,
            enabled: !hasPrefilledEmail,
            helperText: hasPrefilledEmail ? 'Provided by your account' : null,
          ),
          const SizedBox(height: 16),
          const Text('Date of Birth', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontFamily: 'Nunito')),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: state.dateOfBirth,
                firstDate: DateTime(1920),
                lastDate: DateTime.now(),
                builder: (ctx, child) => Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(primary: AppColors.brandPrimary),
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
                  const Icon(Icons.calendar_today_outlined, color: AppColors.textTertiary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '${state.dateOfBirth.day}/${state.dateOfBirth.month}/${state.dateOfBirth.year}',
                    style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Gender', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontFamily: 'Nunito')),
          const SizedBox(height: 8),
          Row(
            children: Gender.values.map((g) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: g == Gender.male ? 8 : 0),
                child: GestureDetector(
                  onTap: () => notifier.setGender(g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: state.gender == g ? AppGradients.brand : null,
                      color: state.gender == g ? null : AppColors.darkCardBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(g.displayName,
                          style: TextStyle(
                            color: state.gender == g ? Colors.white : AppColors.textSecondary,
                            fontWeight: state.gender == g ? FontWeight.w700 : FontWeight.w400,
                            fontFamily: 'Nunito',
                          )),
                    ),
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _BodyMetricsStep extends StatelessWidget {
  final ProfileNotifier notifier;
  final ProfileState state;
  const _BodyMetricsStep({required this.notifier, required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your body metrics', style: AppTextStyles.title2),
          const SizedBox(height: 8),
          const Text('Used for BMI and calorie calculations',
              style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Nunito')),
          const SizedBox(height: 32),
          _FormField(label: 'Height (cm)', initialValue: state.height,
              keyboardType: TextInputType.number, onChanged: notifier.setHeight),
          const SizedBox(height: 16),
          _FormField(label: 'Current Weight (kg)', initialValue: state.weight,
              keyboardType: TextInputType.number, onChanged: notifier.setWeight),
          const SizedBox(height: 24),
          const Text('Activity Level', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontFamily: 'Nunito')),
          const SizedBox(height: 8),
          ...ActivityLevel.values.map((level) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => notifier.setActivityLevel(level),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: state.activityLevel == level ? AppGradients.brand : null,
                  color: state.activityLevel == level ? null : AppColors.darkCardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(level.displayName,
                    style: TextStyle(
                      color: state.activityLevel == level ? Colors.white : AppColors.textPrimary,
                      fontFamily: 'Nunito',
                    )),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _GoalsStep extends StatelessWidget {
  final ProfileNotifier notifier;
  final ProfileState state;
  const _GoalsStep({required this.notifier, required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your fitness goal', style: AppTextStyles.title2),
          const SizedBox(height: 8),
          const Text('What are you working towards?',
              style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Nunito')),
          const SizedBox(height: 32),
          ...FitnessGoal.values.map((goal) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => notifier.setFitnessGoal(goal),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: state.fitnessGoal == goal ? AppGradients.brand : null,
                  color: state.fitnessGoal == goal ? null : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.fitnessGoal == goal
                        ? Colors.transparent
                        : Colors.white.withOpacity(0.05),
                  ),
                ),
                child: Row(
                  children: [
                    if (state.fitnessGoal == goal)
                      const Icon(Icons.check_circle, color: Colors.white, size: 20)
                    else
                      const Icon(Icons.radio_button_unchecked,
                          color: AppColors.textTertiary, size: 20),
                    const SizedBox(width: 12),
                    Text(goal.displayName,
                        style: TextStyle(
                          color: state.fitnessGoal == goal ? Colors.white : AppColors.textPrimary,
                          fontWeight: state.fitnessGoal == goal ? FontWeight.w600 : FontWeight.w400,
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
            label: 'Target Weight (kg) *',
            initialValue: state.targetWeight,
            keyboardType: TextInputType.number,
            onChanged: notifier.setTargetWeight,
          ),
          const SizedBox(height: 8),
          Text(
            'Required for milestone and achievement tracking',
            style: TextStyle(color: AppColors.textTertiary.withOpacity(0.7), fontSize: 12, fontFamily: 'Nunito'),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String initialValue;
  final TextInputType? keyboardType;
  final void Function(String) onChanged;
  final bool enabled;
  final String? helperText;

  const _FormField({
    required this.label, 
    required this.initialValue,
    required this.onChanged, 
    this.keyboardType,
    this.enabled = true,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      onChanged: onChanged,
      enabled: enabled,
      style: TextStyle(
        color: enabled ? AppColors.textPrimary : AppColors.textSecondary, 
        fontFamily: 'Nunito'
      ),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperStyle: const TextStyle(
          color: AppColors.textTertiary, 
          fontSize: 12, 
          fontFamily: 'Nunito'
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
    );
  }
}
