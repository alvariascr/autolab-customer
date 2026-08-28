part of 'home_customer_content.dart';

class _HomeColors {
  const _HomeColors({
    required this.background,
    required this.text,
    required this.secondaryText,
    required this.surface,
    required this.divider,
    required this.inactiveDot,
  });

  final Color background;
  final Color text;
  final Color secondaryText;
  final Color surface;
  final Color divider;
  final Color inactiveDot;

  static _HomeColors of(BuildContext context) {
    return _HomeColors(
      background: AutolabCustomer.customerBackgroundColor(context),
      text: AutolabCustomer.customerTextColor(context),
      secondaryText: AutolabCustomer.customerSecondaryTextColor(context),
      surface: AutolabCustomer.customerSurfaceColor(context),
      divider: AutolabCustomer.customerDividerColor(context),
      inactiveDot: AutolabCustomer.customerElevatedSurfaceColor(context),
    );
  }
}
