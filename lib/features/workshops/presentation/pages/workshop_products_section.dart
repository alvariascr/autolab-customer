part of 'workshop_profile_page.dart';

class _ProductsSection extends StatefulWidget {
  const _ProductsSection({required this.workshopId, this.initialSection});

  final String workshopId;
  final String? initialSection;

  @override
  State<_ProductsSection> createState() => _ProductsSectionState();
}

class _ProductsSectionState extends State<_ProductsSection> {
  late Future<Either<Failure, List<Product>>> _productsFuture;
  late final StreamSubscription<void> _inventoryRefreshSubscription;
  String _selectedSection = _SectionKey.all;

  @override
  void initState() {
    super.initState();
    _selectedSection = _normalizeInitialSection(widget.initialSection);
    _productsFuture = _loadProducts();
    _inventoryRefreshSubscription = sl<ProductInventoryRefreshNotifier>().stream
        .listen((_) => _refreshProducts());
  }

  @override
  void didUpdateWidget(covariant _ProductsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection != widget.initialSection) {
      _selectedSection = _normalizeInitialSection(widget.initialSection);
    }
  }

  @override
  void dispose() {
    _inventoryRefreshSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<Failure, List<Product>>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context)!;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final result = snapshot.data;
        final products =
            result?.fold((_) => const <Product>[], (items) => items) ??
            const <Product>[];

        if (result == null || result.isLeft()) {
          return _ProductsMessage(
            icon: Icons.error_outline_rounded,
            message: l10n.workshopProfileProductsLoadError,
          );
        }

        final sections = _buildSections(products);
        final selectedSection = sections.containsKey(_selectedSection)
            ? _selectedSection
            : _SectionKey.all;
        final selectedProducts = selectedSection == _SectionKey.all
            ? const <Product>[]
            : sections[selectedSection] ?? const <Product>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.workshopProfileCatalogTitle,
              style: AutolabCustomer.h1.copyWith(
                color: AutolabCustomer.customerTextColor(context),
                fontSize: AutolabCustomer.responsiveDouble(
                  context,
                  compact: 23,
                  regular: 27,
                  tablet: 32,
                ),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AutolabCustomer.spacingMd),
            _SectionTabs(
              sections: sections.keys.toList(),
              selectedSection: selectedSection,
              onSelected: (section) {
                setState(() => _selectedSection = section);
              },
            ),
            const SizedBox(height: AutolabCustomer.spacingMd),
            if (selectedSection == _SectionKey.all) ...[
              const _ComingSoonPopularGroup(),
              ...sections.entries
                  .where(
                    (entry) =>
                        entry.key != _SectionKey.all &&
                        entry.key != _SectionKey.popular,
                  )
                  .map(
                    (entry) => _ProductMenuGroup(
                      title: entry.key,
                      products: entry.value,
                    ),
                  ),
            ] else if (selectedSection == _SectionKey.popular)
              const _ComingSoonPopularGroup()
            else
              _ProductMenuGroup(
                title: selectedSection,
                products: selectedProducts,
              ),
          ],
        );
      },
    );
  }

  Future<Either<Failure, List<Product>>> _loadProducts() {
    return sl<ProductRepository>().getActiveProductsByWorkshop(
      widget.workshopId,
    );
  }

  void _refreshProducts() {
    if (!mounted) {
      return;
    }

    setState(() {
      _productsFuture = _loadProducts();
    });
  }

  Map<String, List<Product>> _buildSections(List<Product> products) {
    final sections = <String, List<Product>>{};

    sections[_SectionKey.all] = products;
    sections[_SectionKey.popular] = const <Product>[];

    final services = products.where(_isService).toList();
    if (services.isNotEmpty) {
      sections[_SectionKey.services] = services;
    }

    final tangibleProducts = products.where((product) => !_isService(product));
    final productsByType = tangibleProducts.toList();
    if (productsByType.isNotEmpty) {
      sections[_SectionKey.products] = productsByType;
    }

    final byCategory = <String, List<Product>>{};
    for (final product in products) {
      final category = product.categoryName.trim();
      if (category.isEmpty) {
        continue;
      }

      byCategory.putIfAbsent(category, () => <Product>[]).add(product);
    }

    final sortedCategories = byCategory.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));

    for (final entry in sortedCategories.take(6)) {
      if (!sections.containsKey(entry.key)) {
        sections[entry.key] = entry.value;
      }
    }

    return sections;
  }

  bool _isService(Product product) {
    return product.itemType.trim().toLowerCase() == 'service';
  }

  String _normalizeInitialSection(String? section) {
    return switch (section?.trim().toLowerCase()) {
      _SectionKey.popular => _SectionKey.popular,
      _SectionKey.services => _SectionKey.services,
      _SectionKey.products => _SectionKey.products,
      _ => _SectionKey.all,
    };
  }
}

class _SectionKey {
  const _SectionKey._();

  static const all = 'all';
  static const popular = 'popular';
  static const services = 'services';
  static const products = 'products';
}

class _SectionTabs extends StatelessWidget {
  const _SectionTabs({
    required this.sections,
    required this.selectedSection,
    required this.onSelected,
  });

  final List<String> sections;
  final String selectedSection;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AutolabCustomer.responsiveDouble(
        context,
        compact: 38,
        regular: 44,
        tablet: 50,
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sections.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AutolabCustomer.spacingSmd),
        itemBuilder: (context, index) {
          final section = sections[index];
          final isSelected = section == selectedSection;

          return ChoiceChip(
            showCheckmark: false,
            label: Text(_labelForSection(context, section)),
            selected: isSelected,
            onSelected: (_) => onSelected(section),
            backgroundColor: AutolabCustomer.customerSurfaceColor(context),
            selectedColor: AutolabCustomer.customerSurfaceColor(context),
            side: BorderSide(
              color: isSelected
                  ? AutolabCustomer.primary
                  : AutolabCustomer.customerSurfaceColor(context),
              width: 1.4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            labelPadding: const EdgeInsets.symmetric(
              horizontal: AutolabCustomer.spacingMd,
            ),
            labelStyle: AutolabCustomer.bodyLarge.copyWith(
              color: AutolabCustomer.customerTextColor(context),
              fontSize: AutolabCustomer.responsiveDouble(
                context,
                compact: 13,
                regular: 15,
                tablet: 16,
              ),
              fontWeight: FontWeight.w800,
            ),
          );
        },
      ),
    );
  }

  String _labelForSection(BuildContext context, String section) {
    final l10n = AppLocalizations.of(context)!;

    return switch (section) {
      _SectionKey.all => l10n.workshopProfileCatalogAllTab,
      _SectionKey.popular => l10n.workshopProfileCatalogPopularTab,
      _SectionKey.services => l10n.workshopProfileCatalogServicesTab,
      _SectionKey.products => l10n.workshopProfileCatalogProductsTab,
      _ => section,
    };
  }
}

class _ProductMenuGroup extends StatelessWidget {
  const _ProductMenuGroup({required this.title, required this.products});

  final String title;
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AutolabCustomer.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            height: AutolabCustomer.spacingLg,
            color: AutolabCustomer.customerDividerColor(context),
          ),
          _SectionHeader(title: _sectionTitle(context, title)),
          const SizedBox(height: AutolabCustomer.spacingMd),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 680 ? 3 : 2;
              final spacing = AutolabCustomer.responsiveDouble(
                context,
                compact: AutolabCustomer.spacingMd,
                regular: AutolabCustomer.spacingMd,
                tablet: AutolabCustomer.spacingLg,
              );
              final tileWidth =
                  (constraints.maxWidth - (spacing * (columns - 1))) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: AutolabCustomer.spacingMd,
                children: products.map((product) {
                  return SizedBox(
                    width: tileWidth,
                    child: _MenuProductTile(product: product),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _sectionTitle(BuildContext context, String title) {
    final l10n = AppLocalizations.of(context)!;

    return switch (title) {
      _SectionKey.popular => l10n.workshopProfileCatalogPopularTab,
      _SectionKey.services => l10n.workshopProfileCatalogServicesTab,
      _SectionKey.products => l10n.workshopProfileCatalogProductsTab,
      _ => title,
    };
  }
}

class _ComingSoonPopularGroup extends StatelessWidget {
  const _ComingSoonPopularGroup();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AutolabCustomer.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: l10n.workshopProfileCatalogPopularTab),
          const SizedBox(height: AutolabCustomer.spacingMd),
          const _ComingSoonCard(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AutolabCustomer.h1.copyWith(
              color: AutolabCustomer.customerTextColor(context),
              fontSize: AutolabCustomer.responsiveDouble(
                context,
                compact: 23,
                regular: 28,
                tablet: 32,
              ),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: AutolabCustomer.responsiveDouble(
        context,
        compact: 116,
        regular: 140,
        tablet: 180,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
      ),
      child: Text(
        AppLocalizations.of(context)!.workshopProfileCatalogComingSoon,
        style: AutolabCustomer.bodyLarge.copyWith(
          color: AutolabCustomer.customerSecondaryTextColor(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MenuProductTile extends StatelessWidget {
  const _MenuProductTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AutolabCustomer.customerSurfaceColor(context),
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push(
            '/workshops/${product.workshopId}/products/${product.id}',
            extra: product,
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
            border: Border.all(
              color: AutolabCustomer.customerBorderColor(context),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductImage(
                imageUrl: product.primaryImageUrl,
                height: AutolabCustomer.responsiveDouble(
                  context,
                  compact: 92,
                  regular: 112,
                  tablet: 140,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AutolabCustomer.radiusCard),
                ),
                placeholderIconSize: 42,
              ),
              Padding(
                padding: const EdgeInsets.all(AutolabCustomer.spacingSmd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AutolabCustomer.bodyLarge.copyWith(
                        color: AutolabCustomer.customerTextColor(context),
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: AutolabCustomer.spacingSm),
                    ProductPriceText(
                      price: product.sellingPrice,
                      style: AutolabCustomer.body.copyWith(
                        color: AutolabCustomer.customerTextColor(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AutolabCustomer.spacingXs),
                    Text(
                      product.effectiveDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AutolabCustomer.caption.copyWith(
                        color: AutolabCustomer.customerSecondaryTextColor(
                          context,
                        ),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductsMessage extends StatelessWidget {
  const _ProductsMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AutolabCustomer.spacingLg,
        vertical: AutolabCustomer.spacingLg,
      ),
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
        border: Border.all(color: AutolabCustomer.customerBorderColor(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AutolabCustomer.primary),
          const SizedBox(width: AutolabCustomer.spacingSmd),
          Expanded(
            child: Text(
              message,
              style: AutolabCustomer.caption.copyWith(
                color: AutolabCustomer.customerSecondaryTextColor(context),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
