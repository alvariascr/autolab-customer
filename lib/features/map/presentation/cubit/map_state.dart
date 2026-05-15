import 'package:equatable/equatable.dart';

import '../../../../core/location/current_location.dart';
import '../../../products/domain/services/workshop_product_search_grouper.dart';
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
    this.query = '',
    this.productResults = const [],
    this.isLoadingProductResults = false,
  });

  final List<Workshop> workshops;
  final CurrentLocation? currentLocation;
  final bool isUsingFallbackLocation;
  final String query;
  final List<WorkshopProductSearchResult> productResults;
  final bool isLoadingProductResults;

  @override
  List<Object?> get props => [
    workshops,
    currentLocation,
    isUsingFallbackLocation,
    query,
    productResults,
    isLoadingProductResults,
  ];
}

final class MapError extends MapState {
  const MapError({required this.code, this.uiKey, this.message});

  final String code;
  final String? uiKey;
  final String? message;

  @override
  List<Object?> get props => [code, uiKey, message];
}
