import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../../drinks/data/drink_catalog.dart';
import '../../drinks/domain/drink.dart';

class ManualSearchScreen extends StatefulWidget {
  const ManualSearchScreen({super.key});

  @override
  State<ManualSearchScreen> createState() => _ManualSearchScreenState();
}

class _ManualSearchScreenState extends State<ManualSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  DrinkCategory? _selectedCategory;

  static const _categories = [
    DrinkCategory.packaged,
    DrinkCategory.coffee,
    DrinkCategory.tea,
    DrinkCategory.boba,
    DrinkCategory.juice,
  ];

  List<Drink> get _results {
    final query = _searchController.text.trim().toLowerCase();
    return DrinkCatalog.all
        .where((drink) {
          final matchesCategory =
              _selectedCategory == null || drink.category == _selectedCategory;
          final matchesQuery =
              query.isEmpty || drink.name.toLowerCase().contains(query);
          return matchesCategory && matchesQuery;
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return Scaffold(
      key: const ValueKey('manualSearchScreen'),
      body: AuraBackground(
        child: SafeArea(
          child: Stack(
            children: [
              ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  StevSpace.s5,
                  78,
                  StevSpace.s5,
                  36,
                ),
                children: [
                  _SearchField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: StevSpace.s4),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: StevSpace.s2),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return _CategoryChip(
                          category: category,
                          selected: _selectedCategory == category,
                          onTap: () {
                            setState(() {
                              _selectedCategory = _selectedCategory == category
                                  ? null
                                  : category;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: StevSpace.s5),
                  if (results.isEmpty)
                    const _EmptyResults()
                  else
                    for (var index = 0; index < results.length; index++) ...[
                      _ManualDrinkRow(drink: results[index]),
                      if (index < results.length - 1)
                        const SizedBox(height: StevSpace.s3),
                    ],
                  const SizedBox(height: StevSpace.s5),
                  StevButton(
                    key: const ValueKey('addCustomDrinkButton'),
                    label: '+ Tambah minuman',
                    variant: StevButtonVariant.card,
                    onPressed: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Tambah minuman segera hadir.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                    },
                  ),
                ],
              ),
              const _ManualHeader(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualHeader extends StatelessWidget {
  const _ManualHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ColoredBox(
        color: StevColors.canvas.withValues(alpha: 0.82),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: StevSpace.s5),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: StevIconButton(
                  icon: const StevIcon(StevIconName.back, size: 20),
                  label: 'Kembali',
                  onPressed: () => context.pop(),
                ),
              ),
              Text('Cari manual', style: StevType.heading),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: StevRadius.button,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 56,
        child: TextField(
          key: const ValueKey('manualSearchField'),
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: StevType.label,
          decoration: InputDecoration(
            hintText: 'Cari minuman',
            prefixIcon: const Padding(
              padding: EdgeInsets.all(StevSpace.s4),
              child: StevIcon(
                StevIconName.search,
                size: 24,
                color: StevColors.ink2,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 56,
              minHeight: 56,
            ),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final DrinkCategory category;
  final bool selected;
  final VoidCallback onTap;

  String get _label => switch (category) {
    DrinkCategory.packaged => 'Kemasan',
    DrinkCategory.coffee => 'Kopi',
    DrinkCategory.tea => 'Teh',
    DrinkCategory.boba => 'Boba',
    DrinkCategory.juice => 'Jus',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? StevColors.ink : StevColors.card,
        borderRadius: BorderRadius.circular(StevRadius.pill),
        border: Border.all(
          color: selected ? StevColors.ink : StevColors.glassEdge,
        ),
        boxShadow: selected ? StevShadows.pressInkChip : StevShadows.pressCard,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('category-${category.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(StevRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StevSpace.s4,
              vertical: StevSpace.s3,
            ),
            child: Text(
              _label,
              style: StevType.caption.copyWith(
                color: selected ? StevColors.onInk : StevColors.ink2,
                fontWeight: StevType.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualDrinkRow extends StatelessWidget {
  const _ManualDrinkRow({required this.drink});

  final Drink drink;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${drink.name}, ${formatSugarGrams(drink.grams, drink.estimated)}',
      child: Container(
        key: ValueKey('manualDrink-${drink.id}'),
        height: StevSize.drinkRow,
        decoration: BoxDecoration(
          color: StevColors.card,
          borderRadius: BorderRadius.circular(StevRadius.row),
          boxShadow: [...StevShadows.pressCard, ...StevShadows.elevCard],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/result', extra: drink),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: StevSize.drinkRow,
                  child: ColoredBox(
                    color: StevColors.canvas,
                    child: Image.asset(
                      drink.photoAsset,
                      fit: drink.photoFit,
                      alignment: drink.photoAlignment,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: StevSpace.s4),
                    child: Text(
                      drink.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: StevType.label,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: StevSpace.s2,
                    right: StevSpace.s4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatSugarGrams(drink.grams, drink.estimated),
                        style: StevType.listGrams,
                      ),
                      const SizedBox(width: StevSpace.s1),
                      const StevIcon(
                        StevIconName.chevronRight,
                        size: 18,
                        color: StevColors.ink2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: StevColors.ink2,
            size: 40,
          ),
          const SizedBox(height: StevSpace.s3),
          Text(
            'Minuman belum ditemukan.',
            style: StevType.body.copyWith(color: StevColors.ink2),
          ),
        ],
      ),
    );
  }
}
