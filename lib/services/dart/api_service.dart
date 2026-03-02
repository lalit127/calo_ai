// lib/services/dart/api_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = 'https://web-production-4b65.up.railway.app';

  String? get _token =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  Map<String, String> get _headers => {
    'Content-Type':  'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<dynamic> _get(String path) async {
    final r = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
    ).timeout(const Duration(seconds: 30));
    return _handle(r);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final r = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));
    return _handle(r);
  }

  Future<dynamic> _patch(String path, Map<String, dynamic> body) async {
    final r = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));
    return _handle(r);
  }

  Future<void> _delete(String path) async {
    final r = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
    ).timeout(const Duration(seconds: 30));
    if (r.statusCode >= 400) _handleError(r);
  }

  dynamic _handle(http.Response r) {
    // ✅ Safe debug print — won't crash on short responses
    final preview = r.body.length > 200 ? r.body.substring(0, 200) : r.body;
    print('DEBUG ${r.request?.method} ${r.request?.url} → ${r.statusCode}: $preview');
    if (r.statusCode >= 400) _handleError(r);
    if (r.body.isEmpty) return {};
    return jsonDecode(r.body);
  }

  void _handleError(http.Response r) {
    String msg = 'Request failed';
    try {
      final body = jsonDecode(r.body);
      msg = body['detail'] ?? body['message'] ?? msg;
    } catch (_) {}
    throw ApiException(r.statusCode, msg);
  }

  // ── User Profile ──────────────────────────────────────────────────────────

  Future<dynamic> getProfile() => _get('/users/me');

  Future<dynamic> updateProfile(Map<String, dynamic> updates) =>
      _patch('/users/me', updates);

  // ── Food Analysis ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    final ext = imageFile.path.split('.').last.toLowerCase();

    print('DEBUG analyzeImage token: $_token');
    print('DEBUG analyzeImage url: $baseUrl/food/analyze/image');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/food/analyze/image'),
    );
    // ✅ Only Authorization — let http set Content-Type with boundary automatically
    request.headers['Authorization'] = 'Bearer $_token';
    request.files.add(await http.MultipartFile.fromPath(
      'file', imageFile.path,
      contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
    ));

    final streamed  = await request.send().timeout(const Duration(seconds: 60));
    final response  = await http.Response.fromStream(streamed);
    return _handle(response) as Map<String, dynamic>;
  }

  // ✅ Fixed — was returning Future<Future<dynamic>>
  Future<dynamic> analyzeText(String text, {String? cuisineHint}) {
    return _post('/food/analyze/text', {
      'text': text,
      if (cuisineHint != null) 'cuisine_hint': cuisineHint,
    });
  }

  // ── Food Log ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> logWithImage({
    required File imageFile,
    required String mealType,
  }) async {
    final ext = imageFile.path.split('.').last.toLowerCase();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/food/log/image'),
    );
    request.headers['Authorization'] = 'Bearer $_token';
    request.fields['meal_type'] = mealType;
    request.files.add(await http.MultipartFile.fromPath(
      'file', imageFile.path,
      contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
    ));

    final streamed = await request.send().timeout(const Duration(seconds: 90));
    final response = await http.Response.fromStream(streamed);
    return _handle(response) as Map<String, dynamic>;
  }

  // ✅ Fixed — was returning Future<Future<dynamic>>
  Future<dynamic> logManual({
    required String foodName,
    required String mealType,
    required int calories,
    double proteinG = 0,
    double carbsG = 0,
    double fatG = 0,
    String? portionSize,
  }) {
    return _post('/food/log', {
      'food_name':  foodName,
      'meal_type':  mealType,
      'calories':   calories,
      'protein_g':  proteinG,
      'carbs_g':    carbsG,
      'fat_g':      fatG,
      if (portionSize != null) 'portion_size': portionSize,
    });
  }

  Future<dynamic> getDailyNutrition({String? date}) =>
      _get('/food/daily${date != null ? '?date=$date' : ''}');

  Future<dynamic> getWeeklyStats() => _get('/food/weekly');

  Future<void> deleteLog(String logId) => _delete('/food/log/$logId');

  // ── Water ─────────────────────────────────────────────────────────────────

  Future<void> logWater(int amountMl) =>
      _post('/users/me/water', {'amount_ml': amountMl});

  Future<dynamic> getTodayWater() => _get('/users/me/water/today');

  // ── Weight ────────────────────────────────────────────────────────────────

  Future<void> logWeight(double weightKg) =>
      _post('/users/me/weight', {'weight_kg': weightKg});

  // ── Health ────────────────────────────────────────────────────────────────

  Future<bool> isBackendReachable() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

final apiService = ApiService();