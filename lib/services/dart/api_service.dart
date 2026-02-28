// lib/services/api_service.dart
// Calls YOUR Python backend, automatically attaches Supabase token
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
  // ⚠️ Change this to your backend URL
  // Local dev (Android emulator): http://10.0.2.2:8000
  // Real device: http://YOUR_LAPTOP_IP:8000
  // Production: https://your-railway-app.up.railway.app
  static const String baseUrl = 'http://10.0.2.2:8000';

  /// Gets the current Supabase JWT — sent to Python backend
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

  /// Analyze image — calls Python → Mistral → returns nutrition
  Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    final ext  = imageFile.path.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'png' : 'jpeg';

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/food/analyze/image'),
    );
    request.headers['Authorization'] = 'Bearer $_token';
    request.files.add(await http.MultipartFile.fromPath(
      'file', imageFile.path,
      contentType: MediaType('image', mime),
    ));

    final streamed = await request.send()
        .timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    return _handle(response);
  }

  Future<Future<dynamic>> analyzeText(String text,
      {String? cuisineHint}) async {
    return _post('/food/analyze/text', {
      'text': text,
      if (cuisineHint != null) 'cuisine_hint': cuisineHint,
    });
  }

  // ── Food Log ──────────────────────────────────────────────────────────────

  /// Upload image + auto-analyze + save to Supabase in one call
  Future<Map<String, dynamic>> logWithImage({
    required File imageFile,
    required String mealType,
  }) async {
    final ext  = imageFile.path.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'png' : 'jpeg';

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/food/log/image'),
    );
    request.headers['Authorization'] = 'Bearer $_token';
    request.fields['meal_type'] = mealType;
    request.files.add(await http.MultipartFile.fromPath(
      'file', imageFile.path,
      contentType: MediaType('image', mime),
    ));

    final streamed = await request.send()
        .timeout(const Duration(seconds: 90));
    final response = await http.Response.fromStream(streamed);
    return _handle(response);
  }

  Future<Future<dynamic>> logManual({
    required String foodName,
    required String mealType,
    required int calories,
    double proteinG = 0,
    double carbsG = 0,
    double fatG = 0,
    String? portionSize,
  }) async {
    return _post('/food/log', {
      'food_name': foodName,
      'meal_type': mealType,
      'calories':  calories,
      'protein_g': proteinG,
      'carbs_g':   carbsG,
      'fat_g':     fatG,
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

  Future<dynamic> getTodayWater() =>
      _get('/users/me/water/today');

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