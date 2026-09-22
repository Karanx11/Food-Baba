import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/widgets/loaders/burger_loader.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/top_bar.dart';
import '../../log/application/log_providers.dart';
import '../../log/domain/food_entry.dart';
import '../../log/presentation/food_entry_form_page.dart';
import '../application/catalog_providers.dart';
import '../domain/food_item.dart';
import '../domain/food_search.dart';
import 'portion_page.dart';

/// Find a food to log: recent foods, the catalog by category, or search.
/// Pops `true` once something was logged.
class FoodSearchPage extends ConsumerStatefulWidget {
  const FoodSearchPage({super.key, required this.dayKey, required this.meal});

  final String dayKey;
  final MealType meal;

  static Route<bool> route({required String dayKey, required MealType meal}) =>
      MaterialPageRoute<bool>(
        builder: (_) => FoodSearchPage(dayKey: dayKey, meal: meal),
      );

  @override
  ConsumerState<FoodSearchPage> createState() => _FoodSearchPageState();
}

class _FoodSearchPageState extends ConsumerState<FoodSearchPage> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// Opens a follow-up page; closes this one too if it logged something.
  Future<void> _open(Route<bool> route) async {
    final logged = await Navigator.of(context).push(route);
    if (logged == true && mounted) Navigator.of(context).pop(true);
  }

  void _openFood(FoodItem food) => _open(
    PortionPage.route(food: food, dayKey: widget.dayKey, meal: widget.meal),
  );

  void _openForm({FoodEntry? template, String? name}) => _open(
    FoodEntryFormPage.route(
      dayKey: widget.dayKey,
      meal: widget.meal,
      template: template,
      initialName: name,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(foodCatalogProvider);
    final recent = ref.watch(recentFoodsProvider).value ?? const <FoodEntry>[];
    final query = _query.text.trim();

    return Scaffold(
      appBar: appTopBar(
        context,
        title: 'Add to ${widget.meal.label}',
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _query,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search foods, e.g. dal, roti, banana',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(_query.clear),
                      ),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: catalog.when(
        loading: () => const Center(child: BurgerLoader(size: 72)),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load foods.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (foods) => query.isEmpty
            ? _Browse(
                foods: foods,
                recent: recent,
                onFood: _openFood,
                onRecent: (e) => _openForm(template: e),
                onCustom: () => _openForm(),
              )
            : _Results(
                query: query,
                matches: searchFoods(foods, query),
                onFood: _openFood,
                onCustom: () => _openForm(name: query),
              ),
      ),
    );
  }
}

class _Browse extends StatelessWidget {
  const _Browse({
    required this.foods,
    required this.recent,
    required this.onFood,
    required this.onRecent,
    required this.onCustom,
  });

  final List<FoodItem> foods;
  final List<FoodEntry> recent;
  final ValueChanged<FoodItem> onFood;
  final ValueChanged<FoodEntry> onRecent;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    // Categories in the order they first appear in the catalog.
    final byCategory = <String, List<FoodItem>>{};
    for (final food in foods) {
      byCategory.putIfAbsent(food.category, () => []).add(food);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      children: [
        AppCard(child: _CustomFoodTile(onTap: onCustom)),
        if (recent.isNotEmpty) ...[
          const _SectionHeader('Recent'),
          AppCard(
            child: Column(
              children: [
                for (final entry in recent)
                  ListTile(
                    key: ValueKey('recent-${entry.id}'),
                    leading: const Icon(Icons.history_rounded),
                    title: Text(entry.name),
                    subtitle: Text(
                      '${entry.total.calories.round()} kcal · '
                      '${compactNumber(entry.servings, decimals: 2)} × '
                      '${entry.servingLabel}',
                    ),
                    onTap: () => onRecent(entry),
                  ),
              ],
            ),
          ),
        ],
        for (final MapEntry(key: category, value: items)
            in byCategory.entries) ...[
          _SectionHeader(category),
          AppCard(
            child: Column(
              children: [
                for (final food in items) _FoodTile(food: food, onTap: onFood),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.query,
    required this.matches,
    required this.onFood,
    required this.onCustom,
  });

  final String query;
  final List<FoodItem> matches;
  final ValueChanged<FoodItem> onFood;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (matches.isEmpty) {
      return Center(
        child: AppCard(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: scheme.outline),
              const SizedBox(height: 12),
              Text('No matches for "$query"', style: text.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Add it yourself with its nutrition values.',
                style: text.bodyMedium?.copyWith(color: scheme.outline),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onCustom,
                child: Text('Create "$query" manually'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      children: [
        AppCard(
          child: Column(
            children: [
              for (final food in matches) _FoodTile(food: food, onTap: onFood),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AppCard(
          child: _CustomFoodTile(
            onTap: onCustom,
            title: "Can't find it? Create it",
          ),
        ),
      ],
    );
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({required this.food, required this.onTap});

  final FoodItem food;
  final ValueChanged<FoodItem> onTap;

  @override
  Widget build(BuildContext context) {
    final serving = food.servings.first;
    final kcal = food.nutritionFor(serving.grams).calories.round();
    return ListTile(
      key: ValueKey('food-${food.id}'),
      title: Text(food.name),
      subtitle: Text('$kcal kcal per ${serving.description}'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => onTap(food),
    );
  }
}

class _CustomFoodTile extends StatelessWidget {
  const _CustomFoodTile({
    required this.onTap,
    this.title = 'Create custom food',
  });

  final VoidCallback onTap;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      key: const Key('create-custom-food'),
      leading: Icon(Icons.edit_note_rounded, color: scheme.primary),
      title: Text(title),
      subtitle: const Text('Enter the name and nutrition yourself'),
      onTap: onTap,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
      child: Text(
        title,
        style: text.titleSmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
