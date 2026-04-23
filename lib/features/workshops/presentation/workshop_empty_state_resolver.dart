import 'package:autolab_core/autolab_core.dart';

import '../../../core/errors/customer_error_catalog.dart';
import '../../../core/location/location_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/location/location_ui_presenter.dart';

class WorkshopEmptyStateResolver {
  const WorkshopEmptyStateResolver();

  String resolve(
    LocationState locationState, {
    required AppLocalizations l10n,
    bool isUsingFallbackLocation = false,
  }) {
    return switch (locationState.status) {
      LocationFlowStatus.initial ||
      LocationFlowStatus.loading ||
      LocationFlowStatus.requestingPermission =>
        l10n.workshopEmptySearchingNearby,
      LocationFlowStatus.permissionRequired ||
      LocationFlowStatus.deniedForever ||
      LocationFlowStatus.serviceDisabled ||
      LocationFlowStatus.restricted => l10n.workshopEmptyEnableLocation,
      LocationFlowStatus.error =>
        LocationUiPresenter.resolveErrorMessage(locationState, l10n) ??
            l10n.workshopEmptyLocationErrorFallback,
      LocationFlowStatus.success => l10n.workshopEmptyNoNearby,
    };
  }

  String resolveLoadError(Failure failure, AppLocalizations l10n) {
    if (failure.uiKey != null && failure.uiKey!.isNotEmpty) {
      return switch (failure.uiKey!) {
        final value
            when value == CustomerErrorCatalog.workshopNetworkError.uiKey =>
          l10n.workshopErrorNetwork,
        final value
            when value == CustomerErrorCatalog.workshopLoadFailed.uiKey =>
          l10n.workshopErrorLoadFailed,
        _ => l10n.workshopErrorLoadFailed,
      };
    }

    return switch (failure.code) {
      final value
          when value == CustomerErrorCatalog.workshopNetworkError.code =>
        l10n.workshopErrorNetwork,
      final value when value == CustomerErrorCatalog.workshopLoadFailed.code =>
        l10n.workshopErrorLoadFailed,
      _ => l10n.workshopErrorLoadFailed,
    };
  }
}
