import 'package:flutter/material.dart';

/// Represents a toggleable watermark feature option
class WatermarkOption {
  /// Unique identifier for this option
  final String id;

  /// Display name (localized)
  final String label;

  /// Icon to display
  final IconData icon;

  /// Optional custom widget to use as an icon
  final Widget? customIcon;

  /// Color when enabled
  final Color enabledColor;

  /// Current enabled state
  final bool isEnabled;

  /// Whether this option is available (e.g., requires password setup)
  final bool isAvailable;

  /// Reason why unavailable (e.g., "Requires password")
  final String? unavailableReason;

  /// Callback when tapped to toggle
  final VoidCallback? onToggle;

  /// Callback to open detailed settings
  final VoidCallback? onConfigure;

  /// Additional info to show in tooltip
  final String? subtitle;

  const WatermarkOption({
    required this.id,
    required this.label,
    required this.icon,
    this.customIcon,
    required this.enabledColor,
    required this.isEnabled,
    this.isAvailable = true,
    this.unavailableReason,
    this.onToggle,
    this.onConfigure,
    this.subtitle,
  });

  WatermarkOption copyWith({
    bool? isEnabled,
    bool? isAvailable,
    String? unavailableReason,
    String? subtitle,
    Widget? customIcon,
  }) {
    return WatermarkOption(
      id: id,
      label: label,
      icon: icon,
      customIcon: customIcon ?? this.customIcon,
      enabledColor: enabledColor,
      isEnabled: isEnabled ?? this.isEnabled,
      isAvailable: isAvailable ?? this.isAvailable,
      unavailableReason: unavailableReason ?? this.unavailableReason,
      onToggle: onToggle,
      onConfigure: onConfigure,
      subtitle: subtitle ?? this.subtitle,
    );
  }
}
