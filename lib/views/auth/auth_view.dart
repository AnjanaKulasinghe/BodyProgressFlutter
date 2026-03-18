import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io' show Platform;
import 'package:body_progress/core/design_system.dart';
import 'package:body_progress/core/router.dart';
import 'package:body_progress/core/toast_manager.dart';
import 'package:body_progress/providers/auth_provider.dart';
import 'package:body_progress/widgets/loading_button.dart';

/// Authentication screen — sign-in, sign-up tabs, Apple/Google social login.
class AuthView extends ConsumerStatefulWidget {
  const AuthView({super.key});

  @override
  ConsumerState<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends ConsumerState<AuthView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSignIn = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _isSignIn = _tabController.index == 0);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    // Listen for errors
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.showingAlert && next.errorMessage != null) {
        ToastManager.shared.show(next.errorMessage!, type: ToastType.error);
        ref.read(authProvider.notifier).clearError();
      }
      if (next.isAuthenticated) {
        if (next.canProceed) {
          context.go(AppRoutes.home);
        } else {
          context.go(AppRoutes.verifyEmail);
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              // Header
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppGradients.brand,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppShadows.primaryGlow,
                  ),
                  child: const Icon(Icons.fitness_center,
                      color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  'Body Progress',
                  style: AppTextStyles.title1.copyWith(
                      color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text('Track your transformation',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontFamily: 'Nunito')),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.darkCardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: AppGradients.brand,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: AppTextStyles.bodyBold,
                  tabs: const [
                    Tab(text: 'Sign In'),
                    Tab(text: 'Sign Up'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Form
              if (_isSignIn) _buildSignInForm(auth) else _buildSignUpForm(auth),

              const SizedBox(height: AppSpacing.lg),

              // Divider
              Row(children: [
                const Expanded(child: Divider(color: Color(0xFF2C2C2E))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('or continue with',
                      style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 13,
                          fontFamily: 'Nunito')),
                ),
                const Expanded(child: Divider(color: Color(0xFF2C2C2E))),
              ]),
              const SizedBox(height: AppSpacing.md),

              // Social login buttons
              if (Platform.isIOS)
                _SocialButton(
                  icon: Icons.apple,
                  label: 'Continue with Apple',
                  onTap: auth.isLoading
                      ? null
                      : () => ref.read(authProvider.notifier).signInWithApple(),
                ),
              if (Platform.isAndroid)
                _SocialButton(
                  icon: Icons.g_mobiledata,
                  label: 'Continue with Google',
                  onTap: auth.isLoading
                      ? null
                      : () => ref.read(authProvider.notifier).signInWithGoogle(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm(AuthState auth) {
    final notifier = ref.read(authProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TextField(
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          onChanged: notifier.setEmail,
        ),
        const SizedBox(height: AppSpacing.md),
        _TextField(
          label: 'Password',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textTertiary),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          onChanged: notifier.setPassword,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _showResetDialog(context),
            child: const Text('Forgot Password?',
                style: TextStyle(color: AppColors.brandPrimary, fontFamily: 'Nunito')),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LoadingButton(
          label: 'Sign In',
          isLoading: auth.isLoading,
          onPressed: () => notifier.signIn(),
        ),
      ],
    );
  }

  Widget _buildSignUpForm(AuthState auth) {
    final notifier = ref.read(authProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TextField(label: 'Full Name', icon: Icons.person_outline, onChanged: notifier.setName),
        const SizedBox(height: AppSpacing.md),
        _TextField(
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          onChanged: notifier.setEmail,
        ),
        const SizedBox(height: AppSpacing.md),
        _TextField(
          label: 'Password',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textTertiary),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          onChanged: notifier.setPassword,
        ),
        const SizedBox(height: AppSpacing.md),
        _TextField(
          label: 'Confirm Password',
          icon: Icons.lock_outline,
          obscureText: _obscureConfirm,
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textTertiary),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          onChanged: notifier.setConfirmPassword,
        ),
        const SizedBox(height: AppSpacing.lg),
        LoadingButton(
          label: 'Create Account',
          isLoading: auth.isLoading,
          onPressed: () => notifier.signUp(),
        ),
      ],
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _PasswordResetDialog(),
    );
  }
}

class _PasswordResetDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(authProvider.notifier);
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Reset Password',
          style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Enter your email and we'll send a reset link.",
              style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Nunito')),
          const SizedBox(height: 16),
          _TextField(
            label: 'Email', icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            onChanged: notifier.setResetEmail,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () async {
            final ok = await notifier.sendPasswordReset();
            if (context.mounted) {
              Navigator.pop(context);
              ToastManager.shared.show(ok ? 'Reset email sent!' : 'Failed to send email',
                type: ok ? ToastType.success : ToastType.error);
            }
          },
          child: const Text('Send', style: TextStyle(color: AppColors.brandPrimary)),
        ),
      ],
    );
  }
}

// ── Private reusable widgets ──────────────────────────────────────────────────

class _TextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final void Function(String) onChanged;

  const _TextField({
    required this.label,
    required this.icon,
    required this.onChanged,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito'),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SocialButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.darkCardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 22),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Nunito',
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
