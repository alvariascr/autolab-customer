import 'package:equatable/equatable.dart';

enum HomeServiceFilterStatus { initial, loading, success, failure }

class HomeServiceFilterState extends Equatable {
  HomeServiceFilterState({
    this.status = HomeServiceFilterStatus.initial,
    this.serviceKey,
    this.serviceLabel,
    List<String> matchingWorkshopIds = const [],
  }) : matchingWorkshopIds = List.unmodifiable(matchingWorkshopIds);

  final HomeServiceFilterStatus status;
  final String? serviceKey;
  final String? serviceLabel;
  final List<String> matchingWorkshopIds;

  bool get hasSelection => serviceKey != null && serviceLabel != null;
  bool get isLoading => status == HomeServiceFilterStatus.loading;
  bool get hasFailed => status == HomeServiceFilterStatus.failure;
  bool get hasNoMatches =>
      status == HomeServiceFilterStatus.success && matchingWorkshopIds.isEmpty;

  @override
  List<Object?> get props => [
    status,
    serviceKey,
    serviceLabel,
    matchingWorkshopIds,
  ];
}
