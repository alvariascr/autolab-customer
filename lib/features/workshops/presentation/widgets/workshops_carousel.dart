import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/location/current_location.dart';
import '../../domain/entities/workshop.dart';
import 'workshop_card.dart';

class WorkshopsCarousel extends StatelessWidget {
  final List<Workshop> workshops;
  final String emptyMessage;
  final CurrentLocation? currentLocation;

  const WorkshopsCarousel({
    super.key,
    required this.workshops,
    required this.emptyMessage,
    this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    if (workshops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(emptyMessage, textAlign: TextAlign.center),
        ),
      );
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 320,
        enlargeCenterPage: true,
        viewportFraction: 0.78,
        enableInfiniteScroll: workshops.length > 1,
        autoPlay: workshops.length > 1,
        autoPlayInterval: const Duration(seconds: 3),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
      ),
      items: workshops.map((workshop) {
        return SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showWorkshopDetails(context, workshop),
            child: WorkshopCard(
              workshop: workshop,
              referenceLocation: currentLocation,
              compact: false,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showWorkshopDetails(BuildContext context, Workshop workshop) {
    context.push('/workshops/${workshop.id}');
  }
}
