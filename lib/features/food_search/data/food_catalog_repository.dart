import 'package:flutter/services.dart';

import '../domain/food_item.dart';

/// Source of searchable foods.
abstract interface class FoodCatalogRepository {
  Future<List<FoodItem>> loadAll();
}

/// Reads the catalog bundled with the app.
class AssetFoodCatalogRepository implements FoodCatalogRepository {
  AssetFoodCatalogRepository(this._bundle, {this.path = defaultPath});

  static const String defaultPath = 'assets/foods/common_foods.json';

  final AssetBundle _bundle;
  final String path;

  @override
  Future<List<FoodItem>> loadAll() async =>
      parseFoodCatalog(await _bundle.loadString(path));
}

/// Fixed list of foods. Used in tests.
class InMemoryFoodCatalogRepository implements FoodCatalogRepository {
  InMemoryFoodCatalogRepository(List<FoodItem> foods)
    : _foods = List.unmodifiable(foods);

  final List<FoodItem> _foods;

  @override
  Future<List<FoodItem>> loadAll() async => _foods;
}
