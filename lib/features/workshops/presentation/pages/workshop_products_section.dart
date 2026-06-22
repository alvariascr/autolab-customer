part of 'workshop_profile_page.dart';

class _ProductsSection extends StatefulWidget {
  const _ProductsSection({required this.workshopId});

  final String workshopId;

  @override
  State<_ProductsSection> createState() => _ProductsSectionState();
}

class _ProductsSectionState extends State<_ProductsSection> {
  late Future<Either<Failure, List<Product>>> _productsFuture;
  String _selectedSection = 'Todos';

  @override
  void initState() {
    super.initState();
    _productsFuture = sl<ProductRepository>().getActiveProductsByWorkshop(
      widget.workshopId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<Failure, List<Product>>>(
      future: _productsFuture,
      builder: (context, snapshot) {
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
          return const _ProductsMessage(
            icon: Icons.error_outline_rounded,
            message: 'No fue posible cargar los productos de este taller.',
          );
        }

        if (products.isEmpty) {
          return const _ProductsMessage(
            icon: Icons.inventory_2_outlined,
            message: 'Este taller aun no tiene productos publicados.',
          );
        }

        final sections = _buildSections(products);
        final selectedProducts = _selectedSection == 'Todos'
            ? const <Product>[]
            : sections[_selectedSection] ?? const <Product>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Explora el catalogo',
              style: TextStyle(
                color: Color(0xFF181411),
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            _SectionTabs(
              sections: sections.keys.toList(),
              selectedSection: _selectedSection,
              onSelected: (section) {
                if (section == 'Populares') {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Proximamente')));
                  return;
                }

                setState(() => _selectedSection = section);
              },
            ),
            const SizedBox(height: 18),
            if (_selectedSection == 'Todos') ...[
              const _ComingSoonPopularGroup(),
              ...sections.entries
                  .where((entry) => entry.key != 'Todos')
                  .map(
                    (entry) => _ProductMenuGroup(
                      title: entry.key,
                      products: entry.value,
                    ),
                  ),
            ] else if (_selectedSection == 'Populares')
              const _ComingSoonPopularGroup()
            else
              _ProductMenuGroup(
                title: _selectedSection,
                products: selectedProducts,
              ),
          ],
        );
      },
    );
  }

  Map<String, List<Product>> _buildSections(List<Product> products) {
    final sections = <String, List<Product>>{};

    sections['Todos'] = products;
    sections['Populares'] = const <Product>[];

    final services = products.where(_isService).toList();
    if (services.isNotEmpty) {
      sections['Servicios'] = services;
    }

    final tangibleProducts = products.where((product) => !_isService(product));
    final productsByType = tangibleProducts.toList();
    if (productsByType.isNotEmpty) {
      sections['Productos'] = productsByType;
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
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sections.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final section = sections[index];
          final isSelected = section == selectedSection;

          return ChoiceChip(
            showCheckmark: false,
            avatar: Icon(
              _iconForSection(section),
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF181411),
            ),
            label: Text(section),
            selected: isSelected,
            onSelected: (_) => onSelected(section),
            backgroundColor: const Color(0xFFF1F1F1),
            selectedColor: const Color(0xFF181411),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF181411),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          );
        },
      ),
    );
  }

  IconData _iconForSection(String section) {
    final normalized = section.trim().toLowerCase();

    if (normalized == 'todos') {
      return Icons.menu_rounded;
    }

    if (normalized == 'populares') {
      return Icons.star_rounded;
    }

    if (normalized == 'servicios') {
      return Icons.build_circle_outlined;
    }

    if (normalized == 'productos') {
      return Icons.inventory_2_outlined;
    }

    return Icons.sell_outlined;
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
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 34),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF181411),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - 16) / 2;

              return Wrap(
                spacing: 16,
                runSpacing: 24,
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
}

class _ComingSoonPopularGroup extends StatelessWidget {
  const _ComingSoonPopularGroup();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Populares',
            style: TextStyle(
              color: Color(0xFF181411),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          _ProductsMessage(
            icon: Icons.star_border_rounded,
            message:
                'Proximamente mostraremos los productos mas populares de este taller.',
          ),
        ],
      ),
    );
  }
}

class _MenuProductTile extends StatelessWidget {
  const _MenuProductTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ProductImage(
                imageUrl: product.primaryImageUrl,
                height: 150,
                borderRadius: BorderRadius.circular(14),
                placeholderIconSize: 42,
              ),
              Positioned(
                right: 8,
                bottom: -14,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF181411),
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF181411),
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          ProductPriceText(
            price: product.sellingPrice,
            style: const TextStyle(
              color: Color(0xFF181411),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            product.effectiveDescription,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6B5F57),
              fontSize: 14,
              height: 1.2,
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7DED5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9B3D24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AutolabCustomer.caption.copyWith(
                color: const Color(0xFF6B5F57),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
