part of 'workshop_profile_page.dart';

class _ProductsSection extends StatefulWidget {
  const _ProductsSection({required this.products});

  final List<WorkshopProduct> products;

  @override
  State<_ProductsSection> createState() => _ProductsSectionState();
}

class _ProductsSectionState extends State<_ProductsSection> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _Section(
      title: l10n.workshopProfileProductsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductSearchField(
            controller: _controller,
            enabled: widget.products.isNotEmpty,
            hintText: l10n.workshopProfileProductSearchHint,
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, child) {
              final query = value.text.trim().toLowerCase();
              final products = query.isEmpty
                  ? widget.products
                  : widget.products.where((product) {
                      return product.name.toLowerCase().contains(query) ||
                          product.description.toLowerCase().contains(query);
                    }).toList();

              if (widget.products.isEmpty) {
                return Text(
                  l10n.workshopProfileProductsEmpty,
                  style: AppTextStyles.normal.copyWith(
                    color: const Color(0xFF6B5F57),
                  ),
                );
              }

              if (products.isEmpty) {
                return Text(
                  l10n.workshopProfileProductsNoResults,
                  style: AppTextStyles.normal.copyWith(
                    color: const Color(0xFF6B5F57),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.76,
                ),
                itemBuilder: (context, index) {
                  return _ProductTile(product: products[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final WorkshopProduct product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: product.imageUrl.isEmpty
              ? AspectRatio(
                  aspectRatio: 1.15,
                  child: Container(
                    color: const Color(0xFFF8F4EF),
                    child: const Icon(Icons.inventory_2_outlined, size: 34),
                  ),
                )
              : Image.network(
                  product.imageUrl,
                  width: double.infinity,
                  height: 130,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stackTrace) {
                    return AspectRatio(
                      aspectRatio: 1.15,
                      child: Container(
                        color: const Color(0xFFF8F4EF),
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.normal.copyWith(
            color: const Color(0xFF181411),
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        if (product.description.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            product.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.small.copyWith(
              color: const Color(0xFF6B5F57),
              fontSize: 12,
            ),
          ),
        ],
        if (product.sellingPrice != null) ...[
          const SizedBox(height: 5),
          Text(
            '₡${product.sellingPrice!.toStringAsFixed(0)}',
            style: AppTextStyles.small.copyWith(
              color: const Color(0xFF181411),
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
        const Spacer(),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF181411),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _ProductSearchField extends StatelessWidget {
  const _ProductSearchField({
    required this.controller,
    required this.enabled,
    required this.hintText,
  });

  final TextEditingController controller;
  final bool enabled;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: const Color(0xFFF6F6F6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.subtitle.copyWith(
                color: const Color(0xFF181411),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
