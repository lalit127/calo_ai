// lib/services/storage_service.dart
import 'package:cal_ai/models/food_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  // ── Food Entries ─────────────────────────────────────────────

  Future<List<FoodEntry>> getAllEntries() async {
    final data = await _client
        .from('food_logs')
        .select()
        .eq('user_id', _userId)
        .isFilter('deleted_at', null)
        .order('logged_at', ascending: false);

    return (data as List)
        .map((e) => FoodEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FoodEntry>> getTodayEntries() async {
    return getEntriesForDate(DateTime.now());
  }

  Future<List<FoodEntry>> getEntriesForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day).toIso8601String();
    final end =
    DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final data = await _client
        .from('food_logs')
        .select()
        .eq('user_id', _userId)
        .isFilter('deleted_at', null)
        .gte('logged_at', start)
        .lte('logged_at', end)
        .order('logged_at', ascending: false);

    return (data as List)
        .map((e) => FoodEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> addEntry({
    required String name,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required double fiber,
    String? imagePath,
    required String mealType,
    String cuisineType = 'unknown',
    bool isIndianFood = false,
    String? portionSize,
    double? aiConfidence,
    List<String> ingredients = const [],
    String? cookingMethod,
    bool isManualEntry = false,
    DateTime? loggedAt,
  }) async {
    final row = {
      'user_id': _userId,
      'food_name': name,
      'calories': calories,
      'protein_g': protein,
      'carbs_g': carbs,
      'fat_g': fat,
      'fiber_g': fiber,
      'meal_type': mealType,
      'cuisine_type': cuisineType,
      'is_indian_food': isIndianFood,
      'image_url': imagePath,
      'portion_size': portionSize,
      'ai_confidence': aiConfidence,
      'ingredients': ingredients,
      'cooking_method': cookingMethod,
      'is_manual_entry': isManualEntry,
      'logged_at': (loggedAt ?? DateTime.now()).toIso8601String(),
    };

    final result = await _client
        .from('food_logs')
        .insert(row)
        .select('id')
        .single();

    return result['id'] as String;
  }

  Future<void> deleteEntry(String id) async {
    // Soft delete — keeps data for analytics
    await _client
        .from('food_logs')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  // ── User Goals / Preferences ─────────────────────────────────

  Future<Map<String, dynamic>> _getUserRow() async {
    final data = await _client
        .from('users')
        .select()
        .eq('id', _userId)
        .single();
    return data as Map<String, dynamic>;
  }

  Future<void> _updateUser(Map<String, dynamic> fields) async {
    await _client
        .from('users')
        .update({...fields, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', _userId);
  }

  Future<int> getGoalCalories() async {
    final row = await _getUserRow();
    return (row['goal_calories'] as int?) ?? 2000;
  }

  Future<void> setGoalCalories(int calories) async {
    await _updateUser({'goal_calories': calories});
  }

  Future<double> getGoalProtein() async {
    final row = await _getUserRow();
    return (row['goal_protein'] as num?)?.toDouble() ?? 150.0;
  }

  Future<void> setGoalProtein(double protein) async {
    await _updateUser({'goal_protein': protein});
  }

  Future<String?> getUserName() async {
    final row = await _getUserRow();
    return row['name'] as String?;
  }

  Future<void> setUserName(String name) async {
    await _updateUser({'name': name});
  }

  // ── Weekly chart data ────────────────────────────────────────

  Future<Map<DateTime, int>> getWeeklyCalories() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day - 6);

    final data = await _client
        .from('food_logs')
        .select('logged_at, calories')
        .eq('user_id', _userId)
        .isFilter('deleted_at', null)
        .gte('logged_at', start.toIso8601String())
        .order('logged_at', ascending: true);

    final result = <DateTime, int>{};
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      result[date] = 0;
    }

    for (final row in (data as List)) {
      final ts = DateTime.parse(row['logged_at'] as String).toLocal();
      final day = DateTime(ts.year, ts.month, ts.day);
      if (result.containsKey(day)) {
        result[day] = result[day]! + (row['calories'] as int);
      }
    }

    return result;
  }

  // ── Sync onboarding data saved before auth ───────────────────
  // Call once right after the user successfully signs in.
  Future<void> syncPendingOnboardingData() async {
    final prefs = await SharedPreferences.getInstance();

    final name     = prefs.getString('pending_name');
    final calories = prefs.getInt('pending_goal_calories');
    final protein  = prefs.getDouble('pending_goal_protein');

    if (name == null && calories == null && protein == null) return;

    final updates = <String, dynamic>{};
    if (name != null)     updates['name']         = name;
    if (calories != null) updates['goal_calories'] = calories;
    if (protein != null)  updates['goal_protein']  = protein;

    await _updateUser(updates);

    await prefs.remove('pending_name');
    await prefs.remove('pending_goal_calories');
    await prefs.remove('pending_goal_protein');
  }

  // ── Water Logs ───────────────────────────────────────────────

  Future<void> addWaterLog(int amountMl) async {
    await _client.from('water_logs').insert({
      'user_id': _userId,
      'amount_ml': amountMl,
      'logged_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> getTodayWaterMl() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    final end =
    DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final data = await _client
        .from('water_logs')
        .select('amount_ml')
        .eq('user_id', _userId)
        .gte('logged_at', start)
        .lte('logged_at', end);

    return (data as List)
        .fold<int>(0, (sum, row) => sum + (row['amount_ml'] as int));
  }

  // ── Weight Logs ──────────────────────────────────────────────

  Future<void> addWeightLog(double weightKg, {String? note}) async {
    await _client.from('weight_logs').insert({
      'user_id': _userId,
      'weight_kg': weightKg,
      'note': note,
      'logged_at': DateTime.now().toIso8601String(),
    });
  }
}