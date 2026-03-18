import 'package:flutter/material.dart';
import 'package:body_progress/core/design_system.dart';

/// Reusable gradient loading button
class LoadingButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final Future<void> Function()? onPressed;
  final bool secondary;
  final IconData? icon;

  const LoadingButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.secondary = false,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : () => onPressed?.call(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: secondary ? null : AppGradients.brand,
          color: secondary ? AppColors.brandPrimary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: secondary ? null : AppShadows.primaryGlow,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: secondary ? AppColors.brandPrimary : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        icon,
                        color: secondary ? AppColors.brandPrimary : Colors.white,
                        size: 20,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
