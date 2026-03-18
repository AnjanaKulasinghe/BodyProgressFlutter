import 'package:flutter/services.dart';

/// Centralized haptic feedback manager — mirrors iOS HapticManager.swift
class HapticManager {
  static final HapticManager shared = HapticManager._();
  HapticManager._();

  void light()    => HapticFeedback.lightImpact();
  void medium()   => HapticFeedback.mediumImpact();
  void heavy()    => HapticFeedback.heavyImpact();
  void selection() => HapticFeedback.selectionClick();

  void success() => HapticFeedback.lightImpact();  // closest equivalent
  void warning() => HapticFeedback.mediumImpact();
  void error()   => HapticFeedback.heavyImpact();
}
