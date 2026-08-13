import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/autolab_customer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/cart_cubit.dart';

class CartFloatingCheckoutButton extends StatelessWidget {
  const CartFloatingCheckoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      buildWhen: (previous, current) =>
          previous.totalQuantity != current.totalQuantity,
      builder: (context, cart) {
        final count = cart.totalQuantity;
        final l10n = AppLocalizations.of(context)!;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: count <= 0
              ? const SizedBox.shrink(key: ValueKey('empty-cart-button'))
              : Material(
                  key: const ValueKey('cart-button'),
                  color: AutolabCustomer.secondary,
                  borderRadius: BorderRadius.circular(999),
                  elevation: 10,
                  shadowColor: AutolabCustomer.shadowBlackStrong,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => context.push('/cart'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AutolabCustomer.spacingLg,
                        vertical: AutolabCustomer.spacingSmd,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shopping_cart_outlined,
                            color: AutolabCustomer.white,
                            size: 22,
                          ),
                          const SizedBox(width: AutolabCustomer.spacingSm),
                          Text(
                            '${l10n.productDetailViewCartAction} · $count',
                            style: AutolabCustomer.body.copyWith(
                              color: AutolabCustomer.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
