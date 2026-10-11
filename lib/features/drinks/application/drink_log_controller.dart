import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../data/drink_catalog.dart';
import '../domain/drink.dart';

class DrinkLogController extends ChangeNotifier {
  DrinkLogController({Iterable<DrinkSelection> initialEntries = const []})
    : _entries = List.of(initialEntries);

  factory DrinkLogController.demo() => DrinkLogController(
    initialEntries: const [
      DrinkSelection(drink: DrinkCatalog.tehMelatiKotak),
      DrinkSelection(
        drink: DrinkCatalog.esTehManis,
        sugarLevel: SugarLevel.less,
      ),
    ],
  );

  final List<DrinkSelection> _entries;

  UnmodifiableListView<DrinkSelection> get entries =>
      UnmodifiableListView(_entries);

  double get totalGrams =>
      _entries.fold(0, (total, selection) => total + selection.grams);

  void log(DrinkSelection selection) {
    _entries.removeWhere((entry) => entry.identityId == selection.identityId);
    _entries.insert(0, selection);
    notifyListeners();
  }

  void remove(String identityId) {
    final previousLength = _entries.length;
    _entries.removeWhere((entry) => entry.identityId == identityId);
    if (_entries.length != previousLength) notifyListeners();
  }

  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    notifyListeners();
  }
}

class DrinkLogScope extends InheritedNotifier<DrinkLogController> {
  const DrinkLogScope({
    super.key,
    required DrinkLogController controller,
    required super.child,
  }) : super(notifier: controller);

  static DrinkLogController watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DrinkLogScope>();
    assert(scope != null, 'No DrinkLogScope found in context.');
    return scope!.notifier!;
  }

  static DrinkLogController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<DrinkLogScope>();
    assert(scope != null, 'No DrinkLogScope found in context.');
    return scope!.notifier!;
  }
}
