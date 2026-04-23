import 'package:flutter/material.dart';

import '../../../core/location/location_state.dart';
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
    final isLoading = state.status == LocationFlowStatus.loading;
    final isRequestingPermission =
        state.status == LocationFlowStatus.requestingPermission;
    final isBusy = isLoading || isRequestingPermission;
    final headerCopy = LocationUiPresenter.header(state, l10n);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isBusy ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                const SizedBox(width: 20, height: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        headerCopy.eyebrow,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF3FA572),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              headerCopy.title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF181411),
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 1),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF181411),
                            size: 16,
                          ),
                        ],
                      ),
                      if (headerCopy.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          headerCopy.subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6B5F57),
                            fontSize: 10,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: isBusy
                      ? const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
