import '../../../workshops/domain/entities/workshop.dart';

abstract class MapState {}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class MapLoaded extends MapState {
  final List<Workshop> workshops;

  MapLoaded(this.workshops);
}

class MapError extends MapState {
  final String message;

  MapError(this.message);
}