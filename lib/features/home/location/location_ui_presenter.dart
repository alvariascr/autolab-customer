import '../../../core/errors/customer_error_catalog.dart';
import '../../../core/location/location_state.dart';
import '../../../l10n/app_localizations.dart';
import 'location_ui_model.dart';

class LocationUiPresenter {
  const LocationUiPresenter._();

  static LocationHeaderUiModel header(
    LocationState state,
    AppLocalizations l10n,
  ) {
    final status = state.effectiveStatus;
    final showLoadingCopy =
        state.status == LocationFlowStatus.loading &&
        state.lastSettledStatus == null;

    if (showLoadingCopy) {
      return LocationHeaderUiModel(
        eyebrow: l10n.locationHeaderEyebrowLoading,
        title: l10n.locationHeaderTitleLoading,
        subtitle: l10n.locationHeaderSubtitleLoading,
      );
    }

    switch (status) {
      case LocationFlowStatus.success:
        final placeName = state.placeName?.trim();
        return LocationHeaderUiModel(
          eyebrow: l10n.locationHeaderEyebrowDeliverNow,
          title: _compactPlaceName(placeName, l10n),
          subtitle: '',
        );
      case LocationFlowStatus.permissionRequired:
        return LocationHeaderUiModel(
          eyebrow: l10n.locationHeaderEyebrowDeliverNow,
          title: l10n.locationHeaderTitleChooseAddress,
          subtitle: l10n.locationHeaderSubtitleChooseAddress,
        );
      case LocationFlowStatus.deniedForever:
        return LocationHeaderUiModel(
          eyebrow: l10n.locationHeaderEyebrowPermission,
          title: l10n.locationHeaderTitleOpenSettings,
          subtitle: l10n.locationHeaderSubtitleOpenSettings,
        );
      case LocationFlowStatus.serviceDisabled:
        return LocationHeaderUiModel(
          eyebrow: l10n.locationHeaderEyebrowGpsOff,
          title: l10n.locationHeaderTitleEnableGps,
          subtitle: l10n.locationHeaderSubtitleEnableGps,
        );
      case LocationFlowStatus.restricted:
        return LocationHeaderUiModel(
          eyebrow: l10n.locationHeaderEyebrowRestricted,
          title: l10n.locationHeaderTitleUnavailable,
          subtitle:
              resolveErrorMessage(state, l10n) ??
              l10n.locationHeaderSubtitleRestrictedFallback,
        );
      case LocationFlowStatus.requestingPermission:
        return LocationHeaderUiModel(
          eyebrow: l10n.locationHeaderEyebrowConfirmingAccess,
          title: l10n.locationHeaderTitleConfirmAccess,
          subtitle: l10n.locationHeaderSubtitleConfirmAccess,
        );
      case LocationFlowStatus.error:
        return LocationHeaderUiModel(
          eyebrow: l10n.locationHeaderEyebrowError,
          title: l10n.locationHeaderTitleError,
          subtitle:
              resolveErrorMessage(state, l10n) ??
              l10n.locationHeaderSubtitleErrorFallback,
        );
      case LocationFlowStatus.initial:
      case LocationFlowStatus.loading:
        return LocationHeaderUiModel(
          eyebrow: l10n.locationHeaderEyebrowLoading,
          title: l10n.locationHeaderTitleLoading,
          subtitle: l10n.locationHeaderSubtitleLoading,
        );
    }
  }

  static String? resolveErrorMessage(
    LocationState state,
    AppLocalizations l10n,
  ) {
    final uiKey = state.failureUiKey;
    if (uiKey != null && uiKey.isNotEmpty) {
      return switch (uiKey) {
        final value
            when value ==
                CustomerErrorCatalog.locationPermissionRequired.uiKey =>
          l10n.locationErrorPermissionRequired,
        final value
            when value == CustomerErrorCatalog.locationServiceDisabled.uiKey =>
          l10n.locationErrorServiceDisabled,
        final value
            when value ==
                CustomerErrorCatalog.locationPermissionRestricted.uiKey =>
          l10n.locationErrorPermissionRestricted,
        final value
            when value == CustomerErrorCatalog.locationActionFailed.uiKey =>
          l10n.locationErrorActionFailed,
        final value
            when value == CustomerErrorCatalog.locationRequestTimeout.uiKey =>
          l10n.locationErrorRequestTimeout,
        final value
            when value == CustomerErrorCatalog.invalidCurrentLocation.uiKey =>
          l10n.locationErrorInvalidCurrentLocation,
        final value
            when value ==
                CustomerErrorCatalog.locationConfigurationIncomplete.uiKey =>
          l10n.locationErrorConfigurationIncomplete,
        _ => null,
      };
    }

    final code = state.failureCode;
    if (code == null || code.isEmpty) {
      return state.message == state.failureCode ? null : state.message;
    }

    return switch (code) {
      final value
          when value ==
              CustomerErrorCatalog.locationPermissionRestricted.code =>
        l10n.locationErrorPermissionRestricted,
      final value
          when value == CustomerErrorCatalog.locationActionFailed.code =>
        l10n.locationErrorActionFailed,
      final value
          when value == CustomerErrorCatalog.locationRequestTimeout.code =>
        l10n.locationErrorRequestTimeout,
      final value
          when value == CustomerErrorCatalog.invalidCurrentLocation.code =>
        l10n.locationErrorInvalidCurrentLocation,
      final value
          when value ==
              CustomerErrorCatalog.locationConfigurationIncomplete.code =>
        l10n.locationErrorConfigurationIncomplete,
      _ => state.message == state.failureCode ? null : state.message,
    };
  }

  static LocationSheetUiModel sheet(
    LocationState state,
    AppLocalizations l10n,
  ) {
    final status = state.effectiveStatus;

    final (currentLocationTitle, currentLocationSubtitle) = switch (status) {
      LocationFlowStatus.success => (
        l10n.locationSheetCurrentLocationSuccessTitle,
        l10n.locationSheetCurrentLocationSuccessSubtitle,
      ),
      LocationFlowStatus.deniedForever => (
        l10n.locationSheetCurrentLocationOpenSettingsTitle,
        l10n.locationSheetCurrentLocationOpenSettingsSubtitle,
      ),
      LocationFlowStatus.serviceDisabled => (
        l10n.locationSheetCurrentLocationEnableGpsTitle,
        l10n.locationSheetCurrentLocationEnableGpsSubtitle,
      ),
      LocationFlowStatus.requestingPermission => (
        l10n.locationSheetCurrentLocationWaitingTitle,
        l10n.locationSheetCurrentLocationWaitingSubtitle,
      ),
      _ => (
        l10n.locationSheetCurrentLocationDefaultTitle,
        l10n.locationSheetCurrentLocationDefaultSubtitle,
      ),
    };

    return LocationSheetUiModel(
      title: l10n.locationSheetTitle,
      subtitle: l10n.locationSheetSubtitle,
      currentLocationTitle: currentLocationTitle,
      currentLocationSubtitle: currentLocationSubtitle,
      writeAddressTitle: l10n.locationSheetWriteAddressTitle,
      writeAddressSubtitle: l10n.locationSheetWriteAddressSubtitle,
    );
  }

  static String _compactPlaceName(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.locationHeaderTitleSuccessFallback;
    }

    final parts = value
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts[0]}, ${parts[1]}';
    }

    return value;
  }
}
