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
  const WorkshopProfilePage({
    super.key,
    required this.workshopId,
    this.paymentStatus,
  });

  final String workshopId;
  final String? paymentStatus;

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
      backgroundColor: AutolabCustomer.customerBackgroundColor(context),
      body: Column(
        children: [
          if (widget.paymentStatus != null)
            _LaropayPaymentStatusNotice(status: widget.paymentStatus!),
          Expanded(
            child: FutureBuilder<Either<Failure, Workshop?>>(
              future: _workshopFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final result = snapshot.data;

                if (result == null) {
                  return _ProfileMessage(
                    message: l10n.workshopProfileLoadError,
                  );
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
                      return _ProfileMessage(
                        message: l10n.workshopProfileNotFound,
                      );
                    }

                    return _WorkshopProfileContent(workshop: workshop);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LaropayPaymentStatusNotice extends StatelessWidget {
  const _LaropayPaymentStatusNotice({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPending = status == 'pending';
    final message = isPending
        ? l10n.laropayPaymentPending
        : l10n.laropayPaymentStartError;
    final color = isPending
        ? const Color(0xFF9A6700)
        : Theme.of(context).colorScheme.error;

    return Material(
      color: isPending ? const Color(0xFFFFF4D6) : const Color(0xFFFCE8E6),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Icon(
                isPending ? Icons.hourglass_top_outlined : Icons.error_outline,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
