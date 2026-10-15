import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../data/drink_catalog.dart';
import '../data/drink_log_preferences.dart';
import '../domain/drink.dart';
import '../../weekly/domain/weekly_sugar_summary.dart';

class LoggedDrinkEvent {
  const LoggedDrinkEvent({
    required this.selection,
    required this.previousTotalGrams,
  });

  final DrinkSelection selection;
  final double previousTotalGrams;
}

class UnderLimitStreak {
  const UnderLimitStreak({required this.days, required this.todayActive});

  final int days;
  final bool todayActive;
}

class DrinkLogController extends ChangeNotifier {
  DrinkLogController({Iterable<DrinkSelection> initialEntries = const []})
    : _entries = List.of(initialEntries),
      _preferences = null,
      _today = null,
      _savedGrams = 0,
      _checkedIn = false;

  DrinkLogController._persistent(
    Iterable<DrinkSelection> initialEntries,
    this._preferences,
    this._today,
    this._savedGrams,
    this._checkedIn,
  ) : _entries = List.of(initialEntries);

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
    await storage.removeLegacyDemoSeed(today, demoEntries);
    final storedDay = await storage.readDay(today);
    final initialEntries = storedDay?.entries ?? const <DrinkSelection>[];
    final savedGrams = storedDay?.savedGrams ?? 0;

    if (storedDay == null) {
      await storage.write(today, initialEntries, savedGrams: savedGrams);
    }

    return DrinkLogController._persistent(
      initialEntries,
      storage,
      today,
      savedGrams,
      storedDay?.checkedIn ?? false,
    );
  }

  final List<DrinkSelection> _entries;
  final DrinkLogPreferences? _preferences;
  final DateTime? _today;
  double _savedGrams;
  bool _checkedIn;
  LoggedDrinkEvent? _pendingLoggedEvent;
  Future<void> _pendingWrite = Future.value();

  UnmodifiableListView<DrinkSelection> get entries =>
      UnmodifiableListView(_entries);

  double get totalGrams =>
      _entries.fold(0, (total, selection) => total + selection.grams);

  double get savedGrams => _savedGrams;

  bool get checkedInToday => _checkedIn;

  DateTime get currentDate => _today ?? DateTime.now();

  LoggedDrinkEvent? takePendingLoggedEvent() {
    final event = _pendingLoggedEvent;
    _pendingLoggedEvent = null;
    return event;
  }

  void log(DrinkSelection selection) {
    _logSelection(selection);
  }

  void logSwap(DrinkSelection selection, {required double savedGrams}) {
    _savedGrams += savedGrams.clamp(0, double.infinity);
    _logSelection(selection);
  }

  void _logSelection(DrinkSelection selection) {
    final previousTotalGrams = totalGrams;
    _entries.removeWhere((entry) => entry.identityId == selection.identityId);
    _entries.insert(0, selection);
    _pendingLoggedEvent = LoggedDrinkEvent(
      selection: selection,
      previousTotalGrams: previousTotalGrams,
    );
    _persist();
    notifyListeners();
  }

  void remove(String identityId) {
    final previousLength = _entries.length;
    _entries.removeWhere((entry) => entry.identityId == identityId);
    if (_entries.length != previousLength) {
      _persist();
      notifyListeners();
    }
  }

  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    _persist();
    notifyListeners();
  }

  void checkIn() {
    if (_checkedIn) return;
    _checkedIn = true;
    _persist();
    notifyListeners();
  }

  Future<void> flush() => _pendingWrite;

  Future<StoredDrinkLog?> loadDay(DateTime date) async {
    await _pendingWrite;
    final preferences = _preferences;
    if (preferences == null) {
      final current = currentDate;
      final isCurrentDay =
          current.year == date.year &&
          current.month == date.month &&
          current.day == date.day;
      return isCurrentDay
          ? StoredDrinkLog(
              entries: _entries,
              savedGrams: _savedGrams,
              checkedIn: _checkedIn,
            )
          : null;
    }
    return preferences.readDay(date);
  }

  Future<UnderLimitStreak> loadUnderLimitStreak({DateTime? anchor}) async {
    await _pendingWrite;
    final target = anchor ?? currentDate;
    var cursor = DateTime(target.year, target.month, target.day);
    final todayLog = await loadDay(cursor);
    final todayCheckedIn = todayLog?.checkedIn ?? false;
    final todayActive =
        todayCheckedIn && (todayLog?.totalGrams ?? double.infinity) <= 50;

    if (todayCheckedIn && !todayActive) {
      return const UnderLimitStreak(days: 0, todayActive: false);
    }
    if (!todayCheckedIn) cursor = cursor.subtract(const Duration(days: 1));

    var days = 0;
    for (var inspected = 0; inspected < 366; inspected++) {
      final log = await loadDay(cursor);
      if (log == null || !log.checkedIn || log.totalGrams > 50) break;
      days++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return UnderLimitStreak(days: days, todayActive: todayActive);
  }

  Future<WeeklySugarSummary> loadWeeklySummary({DateTime? anchor}) async {
    await _pendingWrite;
    final target = anchor ?? _today ?? DateTime.now();
    final monday = DateTime(
      target.year,
      target.month,
      target.day - (target.weekday - DateTime.monday),
    );
    final preferences = _preferences;
    if (preferences == null) {
      const demoGrams = <double?>[38, 55, 41, 42, null, null, null];
      return WeeklySugarSummary(
        days: List.generate(
          7,
          (index) => DailySugarSummary(
            date: monday.add(Duration(days: index)),
            grams: demoGrams[index],
          ),
        ),
        savedGrams: 46,
      );
    }

    final days = <DailySugarSummary>[];
    var weeklySavedGrams = 0.0;
    for (var index = 0; index < 7; index++) {
      final date = monday.add(Duration(days: index));
      final storedDay = await preferences.readDay(date);
      days.add(DailySugarSummary(date: date, grams: storedDay?.totalGrams));
      weeklySavedGrams += storedDay?.savedGrams ?? 0;
    }
    return WeeklySugarSummary(
      days: List.unmodifiable(days),
      savedGrams: weeklySavedGrams,
    );
  }

  void _persist() {
    final preferences = _preferences;
    final today = _today;
    if (preferences == null || today == null) return;
    final snapshot = List<DrinkSelection>.unmodifiable(_entries);
    final savedSnapshot = _savedGrams;
    _pendingWrite = _pendingWrite
        .then(
          (_) => preferences.write(
            today,
            snapshot,
            savedGrams: savedSnapshot,
            checkedIn: _checkedIn,
          ),
        )
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
