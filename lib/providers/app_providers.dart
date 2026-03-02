// lib/providers/app_provider.dart
// Uses Supabase directly for all data operations.
// Only food AI analysis (camera) still goes through Railway backend.
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_entry.dart';

class AppProvider extends ChangeNotifier {
  final _db = Supabase.instance.client;

  String get _uid => _db.auth.currentUser!.id;

  // ── State ─────────────────────────────────────────────────────────────────
  Map<String, dynamic> _profile = {};
  List<FoodEntry>      _entries = [];
  int                  _totalWater = 0;

  bool _loadingDaily   = false;
  bool _loadingProfile = false;

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get loadingDaily   => _loadingDaily;
  bool get loadingProfile => _loadingProfile;

  String get userName => (_profile['name'] as String?)?.isNotEmpty == true
      ? _profile['name'] as String
      : _db.auth.currentUser?.email?.split('@')[0] ?? 'User';

  int    get goalCalories => (_profile['goal_calories'] as int?)         ?? 2000;
  double get goalProtein  => (_profile['goal_protein']  as num?)?.toDouble() ?? 150.0;
  double get goalCarbs    => (_profile['goal_carbs']    as num?)?.toDouble() ?? 250.0;
  double get goalFat      => (_profile['goal_fat']      as num?)?.toDouble() ?? 65.0;
  int    get goalWaterMl  => (_profile['goal_water_ml'] as int?)         ?? 2500;

  List<FoodEntry> get todayEntries => _entries;

  int get totalCal     => _entries.fold(0, (s, e) => s + e.calories);
  double get totalProtein => _entries.fold(0.0, (s, e) => s + e.protein);
  double get totalCarbs   => _entries.fold(0.0, (s, e) => s + e.carbs);
  double get totalFat     => _entries.fold(0.0, (s, e) => s + e.fat);
  int    get totalWater   => _totalWater;

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    await Future.wait([loadProfile(), loadDaily(), loadWater()]);
  }

  // ── Profile ───────────────────────────────────────────────────────────────
  Future<void> loadProfile() async {
    _loadingProfile = true;
    notifyListeners();
    try {
      final data = await _db
          .from('users')
          .select()
          .eq('id', _uid)
          .maybeSingle();
      if (data != null) _profile = Map<String, dynamic>.from(data);
    } catch (e) {
      debugPrint('loadProfile error: $e');
    } finally {
      _loadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    await _db.from('users').upsert({
      'id': _uid,
      ...updates,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'id');
    _profile = {..._profile, ...updates};
    notifyListeners();
  }

  // ── Daily food entries ────────────────────────────────────────────────────
  Future<void> loadDaily({String? date}) async {
    _loadingDaily = true;
    notifyListeners();
    try {
      final now   = date != null ? DateTime.parse(date) : DateTime.now();
      final start = DateTime(now.year, now.month, now.day).toIso8601String();
      final end   = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

      final data = await _db
          .from('food_logs')
          .select()
          .eq('user_id', _uid)
          .isFilter('deleted_at', null)
          .gte('logged_at', start)
          .lte('logged_at', end)
          .order('logged_at', ascending: false);

      _entries = (data as List)
          .map((e) => FoodEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('loadDaily error: $e');
    } finally {
      _loadingDaily = false;
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String id) async {
    await _db
        .from('food_logs')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .eq('user_id', _uid);
    await loadDaily();
  }

  // ── Water ─────────────────────────────────────────────────────────────────
  Future<void> loadWater() async {
    try {
      final now   = DateTime.now();
      final start = DateTime(now.year, now.month, now.day).toIso8601String();
      final end   = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

      final data = await _db
          .from('water_logs')
          .select('amount_ml')
          .eq('user_id', _uid)
          .gte('logged_at', start)
          .lte('logged_at', end);

      _totalWater = (data as List)
          .fold<int>(0, (sum, row) => sum + (row['amount_ml'] as int));
      notifyListeners();
    } catch (e) {
      debugPrint('loadWater error: $e');
    }
  }

  Future<void> logWater(int ml) async {
    await _db.from('water_logs').insert({
      'user_id':   _uid,
      'amount_ml': ml,
      'logged_at': DateTime.now().toIso8601String(),
    });
    await loadWater();
  }

  // ── Weekly stats (for StatsScreen) ───────────────────────────────────────
  Future<List<Map<String, dynamic>>> loadWeekly() async {
    try {
      final now   = DateTime.now();
      final start = DateTime(now.year, now.month, now.day - 6).toIso8601String();

      final data = await _db
          .from('food_logs')
          .select('calories, protein_g, logged_at')
          .eq('user_id', _uid)
          .isFilter('deleted_at', null)
          .gte('logged_at', start)
          .order('logged_at', ascending: true);

      // Build 7-day buckets
      final days = <Map<String, dynamic>>[];
      for (int i = 6; i >= 0; i--) {
        final d       = DateTime(now.year, now.month, now.day - i);
        final dayStr  = d.toIso8601String().substring(0, 10);
        final dayLogs = (data as List).where((l) =>
            (l['logged_at'] as String).startsWith(dayStr)).toList();
        final cal     = dayLogs.fold<int>(0, (s, l) => s + (l['calories'] as int));
        days.add({
          'date'    : dayStr,
          'calories': cal,
          'protein' : dayLogs.fold<double>(0, (s, l) => s + (l['protein_g'] as num).toDouble()),
          'logged'  : cal > 0,
          'goal_met': cal >= goalCalories * 0.8,
        });
      }
      return days;
    } catch (e) {
      debugPrint('loadWeekly error: $e');
      return [];
    }
  }
}