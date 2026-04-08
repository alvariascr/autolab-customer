import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../../domain/entities/workshop.dart';
import 'workshop_card.dart';

class WorkshopsCarousel extends StatelessWidget {
  final List<Workshop> workshops;

  const WorkshopsCarousel({
    super.key,
    required this.workshops,
  });

  @override
  Widget build(BuildContext context) {
    if (workshops.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text('No hay talleres disponibles'),
        ),
      );
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 320,
        enlargeCenterPage: true,
        viewportFraction: 0.78,
        enableInfiniteScroll: true,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 3),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
      ),
      items: workshops.map((workshop) {
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            print('Tocaste: ${workshop.name}');
          },
          child: WorkshopCard(workshop: workshop),
        );
      }).toList(),
    );
  }
}