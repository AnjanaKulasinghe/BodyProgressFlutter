import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:body_progress/core/design_system.dart';
import 'package:body_progress/core/router.dart';
import 'package:body_progress/core/toast_manager.dart';
import 'package:body_progress/providers/auth_provider.dart';
import 'package:body_progress/providers/profile_provider.dart';
import 'package:body_progress/providers/progress_provider.dart';
import 'package:body_progress/services/notification_service.dart';
import 'package:body_progress/services/connectivity_checker.dart';
import 'package:body_progress/views/settings/app_guide_view.dart';
import 'package:body_progress/views/profile/edit_profile_view.dart';
import 'package:body_progress/views/achievements/achievements_view.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Profile card
          _ProfileHeader(
            name: profile?.name ?? authState.user?.displayName ?? 'User',
            email: profile?.email ?? authState.user?.email ?? '',
            onEditTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const EditProfileView()),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Notifications
          _SettingsSection(title: 'Notifications', children: [
            _SettingsToggleFuture(
              icon: Icons.notifications_outlined,
              label: 'Daily Stats Reminder',
              sublabel: 'Remind me to log stats at 8:00 PM',
              getValue: () => NotificationService().isDailyStatsReminderEnabled(),
              onChanged: (val) async {
                try {
                  if (val) {
                    await NotificationService().scheduleDailyStatsReminder();
                    ToastManager.shared.show('Daily reminder enabled!', type: ToastType.success);
                  } else {
                    await NotificationService().cancelDailyStatsReminder();
                    ToastManager.shared.show('Daily reminder disabled', type: ToastType.info);
                  }
                } catch (e) {
                  ToastManager.shared.show('Failed to schedule reminder: ${e.toString().replaceAll('Exception: ', '')}', type: ToastType.error);
                  rethrow;
                }
              },
            ),
            _SettingsToggleFuture(
              icon: Icons.camera_alt_outlined,
              label: 'Weekly Photo Reminder',
              sublabel: 'Remind me to take a photo on Sundays',
              getValue: () => NotificationService().isWeeklyPhotoReminderEnabled(),
              onChanged: (val) async {
                try {
                  if (val) {
                    await NotificationService().scheduleWeeklyPhotoReminder();
                    ToastManager.shared.show('Weekly reminder enabled!', type: ToastType.success);
                  } else {
                    await NotificationService().cancelWeeklyPhotoReminder();
                    ToastManager.shared.show('Weekly reminder disabled', type: ToastType.info);
                  }
                } catch (e) {
                  ToastManager.shared.show('Failed to schedule reminder: ${e.toString().replaceAll('Exception: ', '')}', type: ToastType.error);
                  rethrow;
                }
              },
            ),
          ]),
          const SizedBox(height: AppSpacing.md),

          // Progress Section
          _SettingsSection(title: 'Progress', children: [
            _SettingsTile(
              icon: Icons.emoji_events_outlined,
              label: 'Achievements',
              sublabel: 'View your earned milestones',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AchievementsView()),
                );
              },
            ),
          ]),
          const SizedBox(height: AppSpacing.md),

          // Health Data
          _SettingsSection(title: 'Health Data', children: [
            _SettingsTile(
              icon: Icons.health_and_safety_outlined,
              label: 'Sync Health Data',
              sublabel: 'Import from HealthKit / Google Health Connect',
              onTap: () async {
                try {
                  final healthService = ref.read(progressProvider.notifier).healthService;
                  
                  // Check permissions
                  final hasPermission = await healthService.hasPermissions();
                  
                  if (!hasPermission) {
                    ToastManager.shared.show(
                      'Requesting health data access...',
                      type: ToastType.info,
                    );
                    
                    final granted = await healthService.requestAuthorization();
                    
                    if (!granted) {
                      final settingsPath = Platform.isIOS
                          ? 'Settings → Privacy & Security → Health → Body Progress'
                          : 'Settings → Apps → Body Progress → Permissions → Health Connect';
                      ToastManager.shared.show(
                        'Health access denied. Open $settingsPath to enable access.',
                        type: ToastType.error,
                      );
                      return;
                    }
                    
                    ToastManager.shared.show(
                      'Health access granted! Starting sync...',
                      type: ToastType.success,
                    );
                  }
                  
                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    useRootNavigator: true,
                    builder: (dialogContext) => PopScope(
                      canPop: false,
                      child: AlertDialog(
                        backgroundColor: AppColors.cardBackground,
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: AppColors.brandPrimary),
                            const SizedBox(height: 16),
                            const Text(
                              'Syncing health data...',
                              style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                  
                  try {
                    // Perform sync
                    final result = await ref.read(progressProvider.notifier).syncWithHealth();
                    
                    // Safely dismiss loading dialog using root navigator
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                    
                    // Show result
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) {
                        ToastManager.shared.show(
                          result.errorMessage ?? 'Synced ${result.uploadedCount} entries',
                          type: result.errorMessage != null ? ToastType.error : ToastType.success,
                        );
                      }
                    });
                  } catch (e) {
                    print('Error syncing health data: $e');
                    // Ensure dialog is dismissed on error using root navigator
                    if (context.mounted) {
                      try {
                        Navigator.of(context, rootNavigator: true).pop();
                      } catch (_) {
                        // Dialog might already be gone
                      }
                    }
                    
                    // Show error toast
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) {
                        ToastManager.shared.show(
                          'Sync failed: ${e.toString()}',
                          type: ToastType.error,
                        );
                      }
                    });
                  }
                } catch (e) {
                  print('Error in health sync setup: $e');
                  ToastManager.shared.show('Sync failed: $e', type: ToastType.error);
                }
              },
            ),
          ]),
          const SizedBox(height: AppSpacing.md),

          // Diagnostics
          _SettingsSection(title: 'Diagnostics', children: [
            _SettingsTile(
              icon: Icons.wifi_outlined,
              label: 'Check Firebase Connection',
              sublabel: 'Test if app can reach database',
              onTap: () async {
                // Show loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: AppColors.cardBackground,
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.brandPrimary),
                        const SizedBox(height: 16),
                        const Text(
                          'Testing connection...',
                          style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito'),
                        ),
                      ],
                    ),
                  ),
                );
                
                try {
                  final checker = ConnectivityChecker();
                  final result = await checker.diagnoseConnectivity();
                  
                  // Dismiss loading dialog
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                  
                  // Show result dialog
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: AppColors.cardBackground,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Row(
                          children: [
                            Icon(
                              result.isConnected ? Icons.check_circle_outlined : Icons.error_outline,
                              color: result.isConnected ? Colors.green : AppColors.errorRed,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              result.isConnected ? 'Connected' : 'Connection Issue',
                              style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito'),
                            ),
                          ],
                        ),
                        content: result.isConnected
                            ? const Text(
                                'Firebase connection is working correctly!',
                                style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Nunito'),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Issue: ${result.issue}',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    result.suggestion ?? '',
                                    style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Nunito'),
                                  ),
                                ],
                              ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('OK', style: TextStyle(color: AppColors.brandPrimary)),
                          ),
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  // Dismiss loading dialog
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                  
                  ToastManager.shared.show(
                    'Connectivity test failed: $e',
                    type: ToastType.error,
                  );
                }
              },
            ),
          ]),
          const SizedBox(height: AppSpacing.md),

          // About
          _SettingsSection(title: 'About', children: [
            _SettingsTile(
              icon: Icons.menu_book_outlined,
              label: 'App Guide',
              sublabel: 'Learn how to use BodyProgress',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AppGuideView()),
                );
              },
            ),
            _SettingsTile(
              icon: Icons.info_outline,
              label: 'Version',
              sublabel: '1.0.0',
              onTap: null,
              showChevron: false,
            ),
          ]),
          const SizedBox(height: AppSpacing.md),

          // Sign Out / Delete
          _SettingsSection(title: 'Account Actions', children: [
            _SettingsTile(
              icon: Icons.logout,
              label: 'Sign Out',
              color: AppColors.errorRed,
              onTap: () => _showSignOutDialog(context, ref),
            ),
            _SettingsTile(
              icon: Icons.delete_forever,
              label: 'Delete Account',
              color: AppColors.errorRed,
              onTap: () => _showDeleteAccountDialog(context, ref),
            ),
          ]),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito')),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Nunito')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // Router will automatically redirect to /auth when the auth stream fires
              await ref.read(authProvider.notifier).signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account', style: TextStyle(color: AppColors.errorRed, fontFamily: 'Nunito')),
        content: const Text(
            'This will permanently delete all your data including photos, measurements, and profile. This cannot be undone.',
            style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Nunito')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // Router will automatically redirect to /auth when the auth stream fires
              await ref.read(authProvider.notifier).deleteAccount();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final VoidCallback onEditTap;
  const _ProfileHeader({required this.name, required this.email, required this.onEditTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.glass,
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(gradient: AppGradients.brand, shape: BoxShape.circle),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'Nunito'),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.bodyBold),
                const SizedBox(height: 2),
                Text(email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontFamily: 'Nunito')),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.brandPrimary, size: 22),
            onPressed: onEditTap,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title.toUpperCase(),
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 11,
                  fontWeight: FontWeight.w600, fontFamily: 'Nunito', letterSpacing: 1)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              final isLast = e.key == children.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast) Divider(color: Colors.white.withOpacity(0.05), height: 1, indent: 54),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final Color? color;
  final VoidCallback? onTap;
  final bool showChevron;
  const _SettingsTile({
    required this.icon, required this.label, this.sublabel,
    this.color, this.onTap, this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textSecondary, size: 22),
      title: Text(label,
          style: TextStyle(
              color: color ?? AppColors.textPrimary, fontFamily: 'Nunito', fontSize: 15)),
      subtitle: sublabel != null
          ? Text(sublabel!,
              style: const TextStyle(color: AppColors.textTertiary, fontFamily: 'Nunito', fontSize: 12))
          : null,
      trailing: showChevron
          ? const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20)
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _SettingsToggle extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final Future<void> Function(bool) onChanged;
  const _SettingsToggle({required this.icon, required this.label, this.sublabel, required this.onChanged});

  @override
  State<_SettingsToggle> createState() => _SettingsToggleState();
}

class _SettingsToggleState extends State<_SettingsToggle> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(widget.icon, color: AppColors.textSecondary, size: 22),
      title: Text(widget.label,
          style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito', fontSize: 15)),
      subtitle: widget.sublabel != null
          ? Text(widget.sublabel!,
              style: const TextStyle(color: AppColors.textTertiary, fontFamily: 'Nunito', fontSize: 12))
          : null,
      value: _value,
      onChanged: (v) async {
        setState(() => _value = v);
        await widget.onChanged(v);
      },
      activeColor: AppColors.brandPrimary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _SettingsToggleFuture extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final Future<bool> Function() getValue;
  final Future<void> Function(bool) onChanged;
  const _SettingsToggleFuture({
    required this.icon,
    required this.label,
    this.sublabel,
    required this.getValue,
    required this.onChanged,
  });

  @override
  State<_SettingsToggleFuture> createState() => _SettingsToggleFutureState();
}

class _SettingsToggleFutureState extends State<_SettingsToggleFuture> {
  bool _value = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialValue();
  }

  Future<void> _loadInitialValue() async {
    final value = await widget.getValue();
    if (mounted) {
      setState(() {
        _value = value;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return ListTile(
        leading: Icon(widget.icon, color: AppColors.textSecondary, size: 22),
        title: Text(widget.label,
            style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito', fontSize: 15)),
        subtitle: widget.sublabel != null
            ? Text(widget.sublabel!,
                style: const TextStyle(color: AppColors.textTertiary, fontFamily: 'Nunito', fontSize: 12))
            : null,
        trailing: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textTertiary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      );
    }

    return SwitchListTile(
      secondary: Icon(widget.icon, color: AppColors.textSecondary, size: 22),
      title: Text(widget.label,
          style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito', fontSize: 15)),
      subtitle: widget.sublabel != null
          ? Text(widget.sublabel!,
              style: const TextStyle(color: AppColors.textTertiary, fontFamily: 'Nunito', fontSize: 12))
          : null,
      value: _value,
      onChanged: (v) async {
        setState(() => _value = v);
        await widget.onChanged(v);
        // Verify the state was saved correctly
        await Future.delayed(const Duration(milliseconds: 100));
        final savedValue = await widget.getValue();
        if (mounted && savedValue != _value) {
          // State wasn't saved correctly, revert
          setState(() => _value = savedValue);
        }
      },
      activeColor: AppColors.brandPrimary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
