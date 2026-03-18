import 'package:flutter/material.dart';
import 'package:body_progress/core/design_system.dart';
import 'package:body_progress/core/haptic_manager.dart';

enum ToastType { success, error, info }

extension _ToastTypeX on ToastType {
  IconData get icon {
    switch (this) {
      case ToastType.success: return Icons.check_circle;
      case ToastType.error:   return Icons.cancel;
      case ToastType.info:    return Icons.info;
    }
  }

  Color get color {
    switch (this) {
      case ToastType.success: return AppColors.successGreen;
      case ToastType.error:   return AppColors.errorRed;
      case ToastType.info:    return AppColors.brandSecondary;
    }
  }
}

/// Global toast notification manager — mirrors iOS ToastManager.swift
class ToastManager extends ChangeNotifier {
  static final ToastManager shared = ToastManager._();
  ToastManager._();

  bool isShowing = false;
  String message = '';
  ToastType type = ToastType.success;

  void show(String msg, {ToastType type = ToastType.success}) {
    this.message = msg;
    this.type = type;
    isShowing = true;
    notifyListeners();

    switch (type) {
      case ToastType.success: HapticManager.shared.success(); break;
      case ToastType.error:   HapticManager.shared.error();   break;
      case ToastType.info:    HapticManager.shared.light();   break;
    }

    Future.delayed(const Duration(seconds: 3), () {
      isShowing = false;
      notifyListeners();
    });
  }
}

class ToastOverlay extends StatefulWidget {
  final Widget child;
  const ToastOverlay({required this.child, super.key});

  @override
  State<ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<ToastOverlay> {
  @override
  void initState() {
    super.initState();
    ToastManager.shared.addListener(_onToastChanged);
  }

  @override
  void dispose() {
    ToastManager.shared.removeListener(_onToastChanged);
    super.dispose();
  }

  void _onToastChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (ToastManager.shared.isShowing)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: AnimatedOpacity(
              opacity: ToastManager.shared.isShowing ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBackground,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: ToastManager.shared.type.color.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(ToastManager.shared.type.icon,
                          color: ToastManager.shared.type.color, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ToastManager.shared.message,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
