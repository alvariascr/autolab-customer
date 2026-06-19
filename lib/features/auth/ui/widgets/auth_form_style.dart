import 'package:flutter/material.dart';

import '../../../../core/theme/autolab_customer.dart';

InputDecoration buildAuthInputDecoration({
  required BuildContext context,
  required String label,
  required String hint,
  required IconData icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: null,
    hintText: hint,
    hintStyle: AutolabCustomer.bodyLarge.copyWith(
      color: AutolabCustomer.authHintColor(context),
      fontWeight: FontWeight.w500,
    ),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AutolabCustomer.authInputFillColor(context),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(16),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AutolabCustomer.primary, width: 1.5),
      borderRadius: BorderRadius.circular(16),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AutolabCustomer.error, width: 1.5),
      borderRadius: BorderRadius.circular(16),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AutolabCustomer.error, width: 2),
      borderRadius: BorderRadius.circular(16),
    ),
  );
}
