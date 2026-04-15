import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../../domain/entities/workshop.dart';
import 'workshop_card.dart';

class WorkshopsCarousel extends StatelessWidget {
  final List<Workshop> workshops;
  final String emptyMessage;

  const WorkshopsCarousel({
    super.key,
    required this.workshops,
    this.emptyMessage = 'No hay talleres disponibles',
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
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {},
          child: WorkshopCard(workshop: workshop),
        );
      }).toList(),
    );
  }
}
