import 'package:equatable/equatable.dart';

import '../../../../core/location/current_location.dart';
import '../../../workshops/domain/entities/workshop.dart';

sealed class MapState extends Equatable {
  const MapState();

  @override
  List<Object?> get props => const [];
}

final class MapInitial extends MapState {
  const MapInitial();
}

final class MapLoading extends MapState {
  const MapLoading();
}

final class MapLoaded extends MapState {
  const MapLoaded(
    this.workshops, {
    this.currentLocation,
    this.isUsingFallbackLocation = false,
  });

  final List<Workshop> workshops;
  final CurrentLocation? currentLocation;
  final bool isUsingFallbackLocation;

  @override
  List<Object?> get props => [
    workshops,
    currentLocation,
    isUsingFallbackLocation,
  ];
}

final class MapError extends MapState {
  const MapError(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}
