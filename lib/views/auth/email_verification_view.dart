import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:body_progress/core/design_system.dart';
import 'package:body_progress/core/router.dart';
import 'package:body_progress/core/toast_manager.dart';
import 'package:body_progress/providers/auth_provider.dart';
import 'package:body_progress/widgets/loading_button.dart';

class EmailVerificationView extends ConsumerStatefulWidget {
  const EmailVerificationView({super.key});
  @override
  ConsumerState<EmailVerificationView> createState() => _EmailVerificationViewState();
}

class _EmailVerificationViewState extends ConsumerState<EmailVerificationView> {
  bool _isSending = false;
  bool _isChecking = false;

  Future<void> _resend() async {
    setState(() => _isSending = true);
    await ref.read(authProvider.notifier).resendVerificationEmail();
    setState(() => _isSending = false);
    ToastManager.shared.show('Verification email sent!', type: ToastType.success);
  }

  Future<void> _check() async {
    setState(() => _isChecking = true);
    await ref.read(authProvider.notifier).reloadUser();
    final auth = ref.read(authProvider);
    setState(() => _isChecking = false);
    if (auth.canProceed) {
      if (mounted) context.go(AppRoutes.home);
    } else {
      ToastManager.shared.show('Email not verified yet. Please check your inbox.',
          type: ToastType.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_unread_outlined,
                    color: AppColors.brandPrimary, size: 40),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('Verify your email', style: AppTextStyles.title1),
              const SizedBox(height: 12),
              Text(
                'We sent a verification link to\n${auth.user?.email ?? ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 16, fontFamily: 'Nunito'),
              ),
              const SizedBox(height: AppSpacing.xl),
              LoadingButton(
                label: "I've Verified My Email",
                isLoading: _isChecking,
                onPressed: _check,
              ),
              const SizedBox(height: AppSpacing.md),
              LoadingButton(
                label: 'Resend Verification Email',
                isLoading: _isSending,
                onPressed: _resend,
                secondary: true,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () {
                  ref.read(authProvider.notifier).signOut();
                  context.go(AppRoutes.auth);
                },
                child: const Text('Sign Out',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
