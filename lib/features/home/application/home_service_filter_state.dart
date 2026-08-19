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

  bool get hasSelection {
    final key = serviceKey?.trim();
    final label = serviceLabel?.trim();
    return key != null && key.isNotEmpty && label != null && label.isNotEmpty;
  }

  bool get isLoading => status == HomeServiceFilterStatus.loading;
  bool get hasFailed => status == HomeServiceFilterStatus.failure;
  bool get hasNoMatches =>
      status == HomeServiceFilterStatus.success && matchingWorkshopIds.isEmpty;

  HomeServiceFilterState copyWith({
    HomeServiceFilterStatus? status,
    String? serviceKey,
    String? serviceLabel,
    List<String>? matchingWorkshopIds,
    bool clearSelection = false,
    bool clearMatchingWorkshopIds = false,
  }) {
    return HomeServiceFilterState(
      status: status ?? this.status,
      serviceKey: clearSelection ? null : (serviceKey ?? this.serviceKey),
      serviceLabel: clearSelection ? null : (serviceLabel ?? this.serviceLabel),
      matchingWorkshopIds: clearMatchingWorkshopIds
          ? const []
          : (matchingWorkshopIds ?? this.matchingWorkshopIds),
    );
  }

  @override
  List<Object?> get props => [
    status,
    serviceKey,
    serviceLabel,
    matchingWorkshopIds,
  ];
}
