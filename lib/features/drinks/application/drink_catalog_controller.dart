import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/drink_catalog.dart';
import '../data/drink_catalog_repository.dart';
import '../domain/drink.dart';

class DrinkCatalogController extends ChangeNotifier {
  DrinkCatalogController({
    required this.repository,
    Iterable<Drink> initialDrinks = DrinkCatalog.all,
  }) : _drinks = List.unmodifiable(initialDrinks);

  factory DrinkCatalogController.forBackend(SupabaseClient? client) {
    if (client == null) {
      return DrinkCatalogController(
        repository: const LocalDrinkCatalogRepository(),
      );
    }
    return DrinkCatalogController(
      repository: FallbackDrinkCatalogRepository(
        remote: SupabaseDrinkCatalogRepository(client),
      ),
    );
  }

  final DrinkCatalogRepository repository;
  List<Drink> _drinks;
  bool _isRefreshing = false;
  String? _errorMessage;

  List<Drink> get drinks => _drinks;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;

  Drink? findById(String id) {
    for (final drink in _drinks) {
      if (drink.id == id) return drink;
    }
    return null;
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final loaded = await repository.fetchAll();
      if (loaded.isNotEmpty) _drinks = List.unmodifiable(loaded);
    } catch (_) {
      _errorMessage =
          'Katalog online belum dapat dimuat. Data lokal tetap tersedia.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }
}

class DrinkCatalogScope extends InheritedNotifier<DrinkCatalogController> {
  const DrinkCatalogScope({
    super.key,
    required DrinkCatalogController controller,
    required super.child,
  }) : super(notifier: controller);

  static DrinkCatalogController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<DrinkCatalogScope>();
    assert(scope != null, 'DrinkCatalogScope is missing above this context.');
    return scope!.notifier!;
  }
}
