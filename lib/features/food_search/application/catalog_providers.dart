import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/food_catalog_repository.dart';
import '../domain/food_item.dart';

/// Where searchable foods come from. Tests override with an in-memory list.
final foodCatalogRepositoryProvider = Provider<FoodCatalogRepository>(
  (_) => AssetFoodCatalogRepository(rootBundle),
);

/// The loaded catalog, cached for the app's lifetime.
final foodCatalogProvider = FutureProvider<List<FoodItem>>(
  (ref) => ref.watch(foodCatalogRepositoryProvider).loadAll(),
);
