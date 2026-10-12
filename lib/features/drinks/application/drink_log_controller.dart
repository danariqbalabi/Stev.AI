import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../data/drink_catalog.dart';
import '../data/drink_log_preferences.dart';
import '../domain/drink.dart';

class DrinkLogController extends ChangeNotifier {
  DrinkLogController({
    Iterable<DrinkSelection> initialEntries = const [],
    this._onEntriesChanged,
  }) : _entries = List.of(initialEntries);

  static const demoEntries = <DrinkSelection>[
    DrinkSelection(drink: DrinkCatalog.tehMelatiKotak),
    DrinkSelection(drink: DrinkCatalog.esTehManis, sugarLevel: SugarLevel.less),
  ];

  factory DrinkLogController.demo() =>
      DrinkLogController(initialEntries: demoEntries);

  static Future<DrinkLogController> persistent({
    DrinkLogPreferences? preferences,
    DateTime? now,
  }) async {
    final storage = preferences ?? DrinkLogPreferences();
    final today = now ?? DateTime.now();
    final storedEntries = await storage.read(today);
    final lastActiveDate = await storage.readLastActiveDate();
    final isFirstPersistentLaunch = lastActiveDate == null;
    final initialEntries =
        storedEntries ??
        (isFirstPersistentLaunch ? demoEntries : const <DrinkSelection>[]);

    if (storedEntries == null) {
      await storage.write(today, initialEntries);
    }

    return DrinkLogController(
      initialEntries: initialEntries,
      onEntriesChanged: (entries) => storage.write(today, entries),
    );
  }

  final List<DrinkSelection> _entries;
  final Future<void> Function(List<DrinkSelection> entries)? _onEntriesChanged;
  Future<void> _pendingWrite = Future.value();

  UnmodifiableListView<DrinkSelection> get entries =>
      UnmodifiableListView(_entries);

  double get totalGrams =>
      _entries.fold(0, (total, selection) => total + selection.grams);

  void log(DrinkSelection selection) {
    _entries.removeWhere((entry) => entry.identityId == selection.identityId);
    _entries.insert(0, selection);
    notifyListeners();
    _persist();
  }

  void remove(String identityId) {
    final previousLength = _entries.length;
    _entries.removeWhere((entry) => entry.identityId == identityId);
    if (_entries.length != previousLength) {
      notifyListeners();
      _persist();
    }
  }

  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    notifyListeners();
    _persist();
  }

  Future<void> flush() => _pendingWrite;

  void _persist() {
    final callback = _onEntriesChanged;
    if (callback == null) return;
    final snapshot = List<DrinkSelection>.unmodifiable(_entries);
    _pendingWrite = _pendingWrite
        .then((_) => callback(snapshot))
        .onError((_, _) {});
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
