import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/workshop.dart';

class WorkshopCard extends StatelessWidget {
  final Workshop workshop;

  const WorkshopCard({
    super.key,
    required this.workshop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
            child: workshop.coverUrl.isNotEmpty
                ? Image.network(
              workshop.coverUrl,
              height: 130,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 130,
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(Icons.image_not_supported),
                ),
              ),
            )
                : Container(
              height: 130,
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(Icons.image),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: workshop.avatarUrl.isNotEmpty
                        ? NetworkImage(workshop.avatarUrl)
                        : null,
                    child: workshop.avatarUrl.isEmpty
                        ? const Icon(Icons.store)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workshop.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.normal,
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            workshop.description.isNotEmpty
                                ? workshop.description
                                : 'Sin descripción disponible',
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.small,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}