import 'package:flutter/material.dart';

import 'autolab_customer.dart';

extension AutolabThemeX on BuildContext {
  Color get customerPrimary => Theme.of(this).colorScheme.primary;

  Color get customerInk => AutolabCustomer.customerTextColor(this);

  Color get customerMuted => AutolabCustomer.customerSecondaryTextColor(this);

  Color get customerElevatedSurface =>
      AutolabCustomer.customerElevatedSurfaceColor(this);

  Color get customerSoftSurface =>
      AutolabCustomer.customerSoftSurfaceColor(this);

  Color get customerBorder => AutolabCustomer.customerBorderColor(this);
}
