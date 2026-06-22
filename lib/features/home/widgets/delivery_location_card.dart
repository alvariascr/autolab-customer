import 'package:flutter/material.dart';

import '../../../core/location/location_state.dart';
import '../../../core/theme/autolab_customer.dart';
import '../../../l10n/app_localizations.dart';
import '../location/location_ui_presenter.dart';

class DeliveryLocationCard extends StatelessWidget {
  const DeliveryLocationCard({
    super.key,
    required this.state,
    required this.onTap,
  });

  final LocationState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textColor = AutolabCustomer.customerTextColor(context);
    final secondaryTextColor = AutolabCustomer.customerSecondaryTextColor(
      context,
    );
    final isLoading = state.status == LocationFlowStatus.loading;
    final isRequestingPermission =
        state.status == LocationFlowStatus.requestingPermission;
    final isBusy = isLoading || isRequestingPermission;
    final headerCopy = LocationUiPresenter.header(state, l10n);
    final eyebrowSize = AutolabCustomer.responsiveDouble(
      context,
      compact: 13,
      regular: 15,
      tablet: 16,
    );
    final titleSize = AutolabCustomer.responsiveDouble(
      context,
      compact: 15,
      regular: 17,
      tablet: 19,
    );
    final subtitleSize = AutolabCustomer.responsiveDouble(
      context,
      compact: 9,
      regular: 10,
      tablet: 11,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isBusy ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                Text(
                  headerCopy.eyebrow,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.primary,
                    fontSize: eyebrowSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        headerCopy.title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AutolabCustomer.bodyLarge.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: titleSize,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: textColor,
                      size: 18,
                    ),
                    if (isBusy) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AutolabCustomer.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (headerCopy.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    headerCopy.subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AutolabCustomer.label.copyWith(
                      color: secondaryTextColor,
                      fontSize: subtitleSize,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
