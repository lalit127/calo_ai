// lib/models/food_entry.dart
// UPDATED: fromJson reads Supabase field names (food_name, protein_g etc.)
//          Backward-compatible with old local field names too

class FoodEntry {
  final String id;
  final String userId;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String mealType;
  final String cuisineType;
  final bool isIndianFood;
  final String? imageUrl; // Supabase Storage public URL
  final String? portionSize;
  final double? aiConfidence;
  final DateTime loggedAt;

  const FoodEntry({
    required this.id,
    required this.userId,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.mealType,
    this.cuisineType = 'unknown',
    this.isIndianFood = false,
    this.imageUrl,
    this.portionSize,
    this.aiConfidence,
    required this.loggedAt,
  });

  factory FoodEntry.fromJson(Map<String, dynamic> j) => FoodEntry(
    id: (j['id'] ?? '').toString(),
    userId: (j['user_id'] ?? '').toString(),
    // Supabase uses 'food_name', old local used 'name'
    name: (j['food_name'] ?? j['name'] ?? 'Unknown').toString(),
    calories: (j['calories'] ?? 0) as int,
    // Supabase uses 'protein_g', old local used 'protein'
    protein: (j['protein_g'] ?? j['protein'] ?? 0).toDouble(),
    carbs: (j['carbs_g'] ?? j['carbs'] ?? 0).toDouble(),
    fat: (j['fat_g'] ?? j['fat'] ?? 0).toDouble(),
    fiber: (j['fiber_g'] ?? j['fiber'] ?? 0).toDouble(),
    mealType: (j['meal_type'] ?? 'snack').toString(),
    cuisineType: (j['cuisine_type'] ?? 'unknown').toString(),
    isIndianFood: j['is_indian_food'] == true,
    imageUrl: j['image_url']?.toString(),
    portionSize: j['portion_size']?.toString(),
    aiConfidence: j['ai_confidence'] != null
        ? (j['ai_confidence'] as num).toDouble()
        : null,
    loggedAt:
        DateTime.tryParse(
          (j['logged_at'] ?? j['timestamp'] ?? '').toString(),
        ) ??
        DateTime.now(),
  );
}

// ── NutritionResult — returned by Python backend AI analysis ─────────────────
class NutritionResult {
  final String foodName;
  final String cuisineType;
  final bool isIndianFood;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  final String portionSize;
  final String description;
  final List<String> ingredients;
  final String cookingMethod;
  final double confidence;

  const NutritionResult({
    required this.foodName,
    required this.cuisineType,
    required this.isIndianFood,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.portionSize,
    required this.description,
    required this.ingredients,
    required this.cookingMethod,
    required this.confidence,
  });

  factory NutritionResult.fromJson(Map<String, dynamic> j) => NutritionResult(
    foodName: (j['food_name'] ?? 'Unknown').toString(),
    cuisineType: (j['cuisine_type'] ?? 'unknown').toString(),
    isIndianFood: j['is_indian_food'] == true,
    calories: (j['calories'] ?? 0) as int,
    protein: (j['protein_g'] ?? 0).toDouble(),
    carbs: (j['carbs_g'] ?? 0).toDouble(),
    fat: (j['fat_g'] ?? 0).toDouble(),
    fiber: (j['fiber_g'] ?? 0).toDouble(),
    sugar: (j['sugar_g'] ?? 0).toDouble(),
    sodium: (j['sodium_mg'] ?? 0).toDouble(),
    portionSize: (j['portion_size'] ?? '').toString(),
    description: (j['description'] ?? '').toString(),
    ingredients: List<String>.from(j['ingredients_detected'] ?? []),
    cookingMethod: (j['cooking_method'] ?? '').toString(),
    confidence: (j['confidence'] ?? 0.9).toDouble(),
  );
}
