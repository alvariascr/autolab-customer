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
}
