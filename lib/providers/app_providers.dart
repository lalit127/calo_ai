// lib/providers/app_provider.dart
// Replaces StorageService — all data comes from Supabase via Python backend
import 'package:cal_ai/services/dart/api_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_entry.dart';

class AppProvider extends ChangeNotifier {
  final _api = apiService;

  // ── State ─────────────────────────────────────────────────────────────────
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _daily   = {};
  Map<String, dynamic> _weekly  = {};
  Map<String, dynamic> _water   = {};

  bool _loadingProfile = false;
  bool _loadingDaily   = false;
  bool _loadingWeekly  = false;

  // ── Getters ───────────────────────────────────────────────────────────────
  Map<String, dynamic> get profile => _profile;
  Map<String, dynamic> get daily   => _daily;
  Map<String, dynamic> get weekly  => _weekly;
  Map<String, dynamic> get water   => _water;

  bool get loadingProfile => _loadingProfile;
  bool get loadingDaily   => _loadingDaily;
  bool get loadingWeekly  => _loadingWeekly;

  // Profile values (with defaults matching original StorageService defaults)
  String get userName    => (_profile['name'] as String?)?.isNotEmpty == true
      ? _profile['name'] as String
      : Supabase.instance.client.auth.currentUser?.email?.split('@')[0] ?? 'User';

  int    get goalCalories => (_profile['goal_calories'] as int?)    ?? 2000;
  double get goalProtein  => (_profile['goal_protein']  as num?)?.toDouble() ?? 150.0;
  double get goalCarbs    => (_profile['goal_carbs']    as num?)?.toDouble() ?? 250.0;
  double get goalFat      => (_profile['goal_fat']      as num?)?.toDouble() ?? 65.0;
  int    get goalWaterMl  => (_profile['goal_water_ml'] as int?)    ?? 2500;

  // Daily totals
  int    get totalCal     => (_daily['total_calories'] as int?)    ?? 0;
  double get totalProtein => (_daily['total_protein']  as num?)?.toDouble() ?? 0.0;
  double get totalCarbs   => (_daily['total_carbs']    as num?)?.toDouble() ?? 0.0;
  double get totalFat     => (_daily['total_fat']      as num?)?.toDouble() ?? 0.0;
  int    get totalWater   => (_water['total_ml']       as int?)    ?? 0;

  List<FoodEntry> get todayEntries {
    final raw = List<Map<String, dynamic>>.from(_daily['entries'] ?? []);
    return raw.map(FoodEntry.fromJson).toList();
  }

  // ── Init — loads everything on first open ─────────────────────────────────
  Future<void> init() async {
    await Future.wait([loadProfile(), loadDaily(), loadWater()]);
  }

  Future<void> loadProfile() async {
    _loadingProfile = true; notifyListeners();
    try {
      _profile = await _api.getProfile();
    } catch (_) {
      // Keep defaults if backend unreachable
    } finally {
      _loadingProfile = false; notifyListeners();
    }
  }

  Future<void> loadDaily({String? date}) async {
    _loadingDaily = true; notifyListeners();
    try {
      _daily = await _api.getDailyNutrition(date: date);
    } catch (_) {} finally {
      _loadingDaily = false; notifyListeners();
    }
  }

  Future<void> loadWeekly() async {
    _loadingWeekly = true; notifyListeners();
    try {
      _weekly = await _api.getWeeklyStats();
    } catch (_) {} finally {
      _loadingWeekly = false; notifyListeners();
    }
  }

  Future<void> loadWater() async {
    try {
      _water = await _api.getTodayWater();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logWater(int ml) async {
    await _api.logWater(ml);
    await loadWater();
  }

  Future<void> deleteEntry(String id) async {
    await _api.deleteLog(id);
    await loadDaily();
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      _profile = await _api.updateProfile(updates);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}