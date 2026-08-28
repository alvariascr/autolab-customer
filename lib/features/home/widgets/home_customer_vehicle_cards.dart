part of 'home_customer_content.dart';

class _HomeEmptyVehicleCard extends StatelessWidget {
  const _HomeEmptyVehicleCard({required this.onAddVehicleTap});

  final VoidCallback onAddVehicleTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = _HomeColors.of(context);

    return Material(
      color: AutolabCustomer.customerSurfaceColor(context),
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      child: InkWell(
        onTap: onAddVehicleTap,
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AutolabCustomer.customerSoftSurfaceColor(context),
                  borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
                ),
                child: const Icon(
                  Icons.directions_car_filled_outlined,
                  color: AutolabCustomer.primary,
                  size: AutolabCustomer.iconSm,
                ),
              ),
              const SizedBox(width: AutolabCustomer.spacingSmd),
              Expanded(
                child: Text(
                  l10n.homeActivateVehicleMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AutolabCustomer.body.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: AutolabCustomer.spacingSm),
              Text(
                l10n.vehiclesAddAction,
                style: AutolabCustomer.caption.copyWith(
                  color: AutolabCustomer.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeActiveVehicleCard extends StatelessWidget {
  const _HomeActiveVehicleCard({
    required this.vehicle,
    required this.onViewAllTap,
  });

  final GarageVehicle vehicle;
  final VoidCallback onViewAllTap;

  @override
  Widget build(BuildContext context) {
    final colors = _HomeColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 66,
            height: 42,
            child: _HomeVehicleNetworkImage(imageUrl: vehicle.imageUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  garageVehicleTitle(vehicle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AutolabCustomer.body.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  garageActiveVehicleSubtitle(vehicle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AutolabCustomer.caption.copyWith(color: colors.text),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AutolabCustomer.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      AppLocalizations.of(context)!.garageActiveVehicle,
                      style: AutolabCustomer.caption.copyWith(
                        color: colors.text,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onViewAllTap,
            style: TextButton.styleFrom(
              foregroundColor: AutolabCustomer.primary,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              AppLocalizations.of(context)!.vehiclesViewAllAction,
              style: AutolabCustomer.caption.copyWith(
                color: AutolabCustomer.primary,
                fontWeight: FontWeight.w700,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeVehicleNetworkImage extends StatelessWidget {
  const _HomeVehicleNetworkImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return const Icon(
        Icons.directions_car_filled_rounded,
        color: AutolabCustomer.primary,
        size: 36,
      );
    }

    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(
        Icons.directions_car_filled_rounded,
        color: AutolabCustomer.primary,
        size: 36,
      ),
    );
  }
}
