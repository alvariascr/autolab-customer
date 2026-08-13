import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/autolab_customer.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/customer_page_header.dart';

class LoyaltyProgramsPage extends StatelessWidget {
  const LoyaltyProgramsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AutolabCustomer.customerBackgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            CustomerPageHeader(
              title: l10n.garageOrders,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }

                context.go('/home-customer?tab=profile');
              },
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AutolabCustomer.spacingXl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: AutolabCustomer.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.card_giftcard_rounded,
                          color: AutolabCustomer.primary,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: AutolabCustomer.spacingLg),
                      Text(
                        l10n.loyaltyProgramsComingSoonTitle,
                        textAlign: TextAlign.center,
                        style: AutolabCustomer.h2.copyWith(
                          color: AutolabCustomer.customerTextColor(context),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AutolabCustomer.spacingSm),
                      Text(
                        l10n.loyaltyProgramsComingSoonMessage,
                        textAlign: TextAlign.center,
                        style: AutolabCustomer.body.copyWith(
                          color: AutolabCustomer.customerSecondaryTextColor(
                            context,
                          ),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: AutolabCustomer.spacingXl),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                              return;
                            }

                            context.go('/home-customer?tab=profile');
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AutolabCustomer.primary,
                            foregroundColor: AutolabCustomer.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AutolabCustomer.spacingMd,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AutolabCustomer.radiusLg,
                              ),
                            ),
                          ),
                          child: Text(
                            l10n.loyaltyProgramsBackToGarage,
                            style: AutolabCustomer.body.copyWith(
                              color: AutolabCustomer.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
