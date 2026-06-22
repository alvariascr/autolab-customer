import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/location/current_location.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../domain/entities/workshop.dart';
import 'workshop_card.dart';

class WorkshopsCarousel extends StatelessWidget {
  final List<Workshop> workshops;
  final String emptyMessage;
  final CurrentLocation? currentLocation;
  final double height;

  const WorkshopsCarousel({
    super.key,
    required this.workshops,
    required this.emptyMessage,
    required this.height,
    this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    if (workshops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: AutolabCustomer.body.copyWith(
              color: AutolabCustomer.customerSecondaryTextColor(context),
            ),
          ),
        ),
      );
    }

    final viewportFraction = AutolabCustomer.responsiveDouble(
      context,
      compact: 0.86,
      regular: 0.78,
      tablet: 0.48,
    );

    return CarouselSlider(
      options: CarouselOptions(
        height: height,
        enlargeCenterPage: true,
        viewportFraction: viewportFraction,
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
