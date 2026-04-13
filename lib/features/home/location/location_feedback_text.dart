import 'package:flutter/material.dart';

class LocationFeedbackText {
  const LocationFeedbackText({
    required this.title,
    required this.subtitle,
    required this.primaryActionLabel,
    required this.leadingIcon,
    required this.showRefreshAction,
  });

  final String title;
  final String subtitle;
  final String primaryActionLabel;
  final IconData leadingIcon;
  final bool showRefreshAction;
}
