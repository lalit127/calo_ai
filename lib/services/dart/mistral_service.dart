// lib/services/mistral_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cal_ai/models/food_entry.dart';

class MistralService {
  static const String _baseUrl =
      'http://10.0.2.2:8000';

  final SupabaseClient _supabase = Supabase.instance.client;

  MistralService();

  // ==============================
  // 🔐 Get JWT Token
  // ==============================
  String? _getAccessToken() {
    final session = _supabase.auth.currentSession;
    return session?.accessToken;
  }

  // ==============================
  // 📸 Analyze Image via Backend
  // ==============================
  Future<NutritionResult> analyzeFood(File imageFile) async {
    final token = _getAccessToken();

    if (token == null) {
      throw Exception("User not authenticated");
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/analyze-image'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Backend error: ${response.body}');
    }

    final nutritionData = json.decode(response.body);
    return NutritionResult.fromJson(nutritionData);
  }

  // ==============================
  // 📝 Analyze Text via Backend
  // ==============================
  Future<NutritionResult> analyzeFoodByText(String foodDescription) async {
    final token = _getAccessToken();

    if (token == null) {
      throw Exception("User not authenticated");
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/analyze-text'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'food': foodDescription,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Backend error: ${response.body}');
    }

    final nutritionData = json.decode(response.body);
    return NutritionResult.fromJson(nutritionData);
  }
}