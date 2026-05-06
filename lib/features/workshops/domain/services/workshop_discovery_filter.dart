import '../../../../core/location/current_location.dart';
import '../entities/workshop.dart';
import 'workshop_proximity_filter.dart';
import 'workshop_text_search_filter.dart';

class WorkshopDiscoveryFilter {
  const WorkshopDiscoveryFilter({
    this.proximityFilter = const WorkshopProximityFilter(),
    this.textSearchFilter = const WorkshopTextSearchFilter(),
  });

  final WorkshopProximityFilter proximityFilter;
  final WorkshopTextSearchFilter textSearchFilter;

  List<Workshop> apply({
    required List<Workshop> workshops,
    required CurrentLocation? currentLocation,
    required String query,
  }) {
    final nearbyWorkshops = proximityFilter.filterNearby(
      workshops: workshops,
      currentLocation: currentLocation,
    );

    if (query.trim().isEmpty) {
      return nearbyWorkshops;
    }

    return textSearchFilter.filter(workshops: nearbyWorkshops, query: query);
  }
}
