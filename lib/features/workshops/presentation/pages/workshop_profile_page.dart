import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../../products/presentation/pages/product_detail_page.dart';
import '../../../products/presentation/widgets/product_image.dart';
import '../../../products/presentation/widgets/product_price_text.dart';
import '../../domain/entities/workshop.dart';
import '../../domain/repositories/workshop_repository.dart';
import '../../domain/services/workshop_today_business_hours_resolver.dart';
import '../workshop_empty_state_resolver.dart';

part 'workshop_profile_content.dart';
part 'workshop_profile_hero.dart';
part 'workshop_profile_actions.dart';
part 'workshop_business_details_sheet.dart';
part 'workshop_products_section.dart';
part 'workshop_profile_message.dart';

class WorkshopProfilePage extends StatefulWidget {
  const WorkshopProfilePage({super.key, required this.workshopId});

  final String workshopId;

  @override
  State<WorkshopProfilePage> createState() => _WorkshopProfilePageState();
}

class _WorkshopProfilePageState extends State<WorkshopProfilePage> {
  late Future<Either<Failure, Workshop?>> _workshopFuture;

  @override
  void initState() {
    super.initState();
    _workshopFuture = sl<WorkshopRepository>().getWorkshopById(
      widget.workshopId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EF),
      body: FutureBuilder<Either<Failure, Workshop?>>(
        future: _workshopFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final result = snapshot.data;

          if (result == null) {
            return _ProfileMessage(message: l10n.workshopProfileLoadError);
          }

          return result.fold(
            (failure) => _ProfileMessage(
              message: WorkshopEmptyStateResolver().resolveLoadError(
                failure,
                l10n,
              ),
            ),
            (workshop) {
              if (workshop == null) {
                return _ProfileMessage(message: l10n.workshopProfileNotFound);
              }

              return _WorkshopProfileContent(workshop: workshop);
            },
          );
        },
      ),
    );
  }
}
