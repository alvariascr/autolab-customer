part of 'delivery_addresses_page.dart';

class _AddressesMessage extends StatelessWidget {
  const _AddressesMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AutolabCustomer.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AutolabCustomer.primary, size: 58),
            const SizedBox(height: AutolabCustomer.spacingMd),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AutolabCustomer.h3.copyWith(
                color: AutolabCustomer.customerTextColor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AutolabCustomer.spacingSm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AutolabCustomer.body.copyWith(
                color: AutolabCustomer.customerSecondaryTextColor(context),
                height: 1.35,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AutolabCustomer.spacingLg),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AutolabCustomer.primary,
                  foregroundColor: AutolabCustomer.white,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

OutlineInputBorder _addressInputBorder(
  BuildContext context, {
  Color? color,
  double width = 1,
}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
    borderSide: BorderSide(
      color: color ?? AutolabCustomer.customerBorderColor(context),
      width: width,
    ),
  );
}
