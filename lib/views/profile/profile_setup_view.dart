import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:body_progress/core/design_system.dart';
import 'package:body_progress/core/router.dart';
import 'package:body_progress/core/toast_manager.dart';
import 'package:body_progress/models/user_profile.dart';
import 'package:body_progress/providers/profile_provider.dart';
import 'package:body_progress/services/health_service.dart';
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
  static const _totalSteps = 4; // Updated to include health permission step
  bool _healthPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    // Always load profile to ensure auth data (name/email) is pre-filled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).loadProfile();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Dismiss keyboard before navigation
    FocusScope.of(context).unfocus();
    
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    // Dismiss keyboard before navigation
    FocusScope.of(context).unfocus();
    
    if (_currentStep > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    }
  }

  Future<void> _submit() async {
    try {
      // Save health permission preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('healthPermissionGranted', _healthPermissionGranted);
      print('💾 Saved health permission: $_healthPermissionGranted');
      
      final ok = await ref.read(profileProvider.notifier).saveProfile();
      if (ok && mounted) {
        ToastManager.shared.show('Profile created!', type: ToastType.success);
        // Small delay to ensure Firestore write completes before navigation
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) context.go(AppRoutes.splash); // Go to loading screen to sync data
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
                _HealthPermissionStep(
                  onPermissionChanged: (granted) {
                    setState(() => _healthPermissionGranted = granted);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: _currentStep == 3
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_healthPermissionGranted)
                        LoadingButton(
                          label: 'Grant Permission',
                          isLoading: false,
                          onPressed: () async {
                            print('🔘 Grant Permission button clicked');
                            final healthService = HealthService();
                            final granted = await healthService.requestAuthorization();
                            print('🏥 Permission result: $granted');
                            setState(() => _healthPermissionGranted = granted);
                            if (granted && mounted) {
                              ToastManager.shared.show(
                                'Health access granted!', 
                                type: ToastType.success,
                              );
                            } else if (mounted) {
                              ToastManager.shared.show(
                                'Health access was not granted', 
                                type: ToastType.error,
                              );
                            }
                          },
                        ),
                      if (!_healthPermissionGranted)
                        const SizedBox(height: 12),
                      LoadingButton(
                        label: _healthPermissionGranted ? 'Complete Setup' : 'Skip for Now',
                        isLoading: profileState.isLoading,
                        onPressed: () async => _nextStep(),
                      ),
                    ],
                  )
                : LoadingButton(
                    label: 'Continue',
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

class _HealthPermissionStep extends StatefulWidget {
  final void Function(bool granted) onPermissionChanged;
  
  const _HealthPermissionStep({required this.onPermissionChanged});

  @override
  State<_HealthPermissionStep> createState() => _HealthPermissionStepState();
}

class _HealthPermissionStepState extends State<_HealthPermissionStep> {
  final HealthService _healthService = HealthService();
  bool _isChecking = false;
  bool? _hasPermission;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    setState(() => _isChecking = true);
    final hasPermission = await _healthService.hasPermissions();
    if (mounted) {
      setState(() {
        _hasPermission = hasPermission;
        _isChecking = false;
      });
      widget.onPermissionChanged(hasPermission);
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _isChecking = true);
    final granted = await _healthService.requestAuthorization();
    if (mounted) {
      setState(() {
        _hasPermission = granted;
        _isChecking = false;
      });
      widget.onPermissionChanged(granted);
      print('🏥 Health permission requested: $granted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Health Data Sync', style: AppTextStyles.title2),
          const SizedBox(height: 8),
          const Text(
            'Connect to Apple Health or Google Health Connect to automatically sync your measurements',
            style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Nunito'),
          ),
          const SizedBox(height: 32),
          
          // Health icon
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.primaryGlow,
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 50),
            ),
          ),
          const SizedBox(height: 32),
          
          // Benefits
          const Text(
            'Benefits:',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 16),
          _BenefitItem(icon: Icons.sync, text: 'Automatic weight tracking'),
          _BenefitItem(icon: Icons.timeline, text: 'Body fat percentage history'),
          _BenefitItem(icon: Icons.show_chart, text: 'Comprehensive progress charts'),
          _BenefitItem(icon: Icons.lock, text: 'Your data stays private and secure'),
          const SizedBox(height: 32),
          
          if (_hasPermission == null || !_hasPermission!)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.brandPrimary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _hasPermission == null
                          ? 'Checking permission status...'
                          : 'You can enable this later in Settings',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
          if (_hasPermission == true)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.successGreen, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Health data access granted! We\'ll sync your data automatically.',
                      style: TextStyle(
                        color: AppColors.successGreen,
                        fontSize: 13,
                        fontFamily: 'Nunito',
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

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;
  
  const _BenefitItem({required this.icon, required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.brandPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatefulWidget {
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
  State<_FormField> createState() => _FormFieldState();
}

class _FormFieldState extends State<_FormField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_FormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller if initialValue changes and field is empty
    if (widget.initialValue != oldWidget.initialValue && _controller.text.isEmpty) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      style: TextStyle(
        color: widget.enabled ? AppColors.textPrimary : AppColors.textSecondary, 
        fontFamily: 'Nunito'
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
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
