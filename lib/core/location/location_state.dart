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
  });

  const LocationState.initial() : this(status: LocationFlowStatus.initial);

  final LocationFlowStatus status;
  final CurrentLocation? location;
  final String? placeName;
  final String? message;

  bool get showRefreshAction {
    return status == LocationFlowStatus.success ||
        status == LocationFlowStatus.error;
  }

  LocationState copyWith({
    LocationFlowStatus? status,
    CurrentLocation? location,
    String? placeName,
    String? message,
    bool clearLocation = false,
    bool clearPlaceName = false,
    bool clearMessage = false,
  }) {
    return LocationState(
      status: status ?? this.status,
      location: clearLocation ? null : (location ?? this.location),
      placeName: clearPlaceName ? null : (placeName ?? this.placeName),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, location, placeName, message];
}
