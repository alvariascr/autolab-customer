import 'package:equatable/equatable.dart';

import 'current_location.dart';

enum LocationFlowStatus {
  initial,
  requestingPermission,
  loading,
  success,
  permissionRequired,
  deniedForever,
  serviceDisabled,
  restricted,
  error,
}

class LocationState extends Equatable {
  const LocationState({
    required this.status,
    this.location,
    this.placeName,
    this.message,
    this.lastSettledStatus,
    this.permissionDeniedCount = 0,
  });

  const LocationState.initial() : this(status: LocationFlowStatus.initial);

  final LocationFlowStatus status;
  final CurrentLocation? location;
  final String? placeName;
  final String? message;
  final LocationFlowStatus? lastSettledStatus;
  final int permissionDeniedCount;

  LocationFlowStatus get effectiveStatus {
    if (status == LocationFlowStatus.loading && lastSettledStatus != null) {
      return lastSettledStatus!;
    }

    return status;
  }

  bool get showRefreshAction {
    return effectiveStatus == LocationFlowStatus.success ||
        effectiveStatus == LocationFlowStatus.error;
  }

  LocationState copyWith({
    LocationFlowStatus? status,
    CurrentLocation? location,
    String? placeName,
    String? message,
    LocationFlowStatus? lastSettledStatus,
    int? permissionDeniedCount,
    bool clearLocation = false,
    bool clearPlaceName = false,
    bool clearMessage = false,
  }) {
    return LocationState(
      status: status ?? this.status,
      location: clearLocation ? null : (location ?? this.location),
      placeName: clearPlaceName ? null : (placeName ?? this.placeName),
      message: clearMessage ? null : (message ?? this.message),
      lastSettledStatus: lastSettledStatus ?? this.lastSettledStatus,
      permissionDeniedCount:
          permissionDeniedCount ?? this.permissionDeniedCount,
    );
  }

  @override
  List<Object?> get props => [
    status,
    location,
    placeName,
    message,
    lastSettledStatus,
    permissionDeniedCount,
  ];
}
