// lib/screens/camera_screen.dart
import 'dart:io';
import 'package:cal_ai/services/dart/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/food_entry.dart';
import '../theme/app_text_styles.dart';
import 'home_screen.dart';

const _kLime    = Color(0xFFC1FF72);
const _kSurface = Color(0xFF111111);
const _kGray    = Color(0xFF888888);

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _api      = apiService;
  final _textCtrl = TextEditingController();

  File?            _image;
  NutritionResult? _result;
  bool             _analyzing = false;
  bool             _saving    = false;
  String           _mealType  = 'lunch';
  bool             _textMode  = false;
  String?          _error;

  // ── Image pick ────────────────────────────────────────────────────────────
  Future<void> _pick(ImageSource src) async {
    final p = await ImagePicker()
        .pickImage(source: src, imageQuality: 85, maxWidth: 1280);
    if (p == null) return;
    setState(() {
      _image  = File(p.path);
      _result = null;
      _error  = null;
    });
    await _analyzeImage();
  }

  // ── Analyze image via Python backend → Mistral/Groq ──────────────────────
  Future<void> _analyzeImage() async {
    if (_image == null) return;
    setState(() { _analyzing = true; _error = null; });
    try {
      final json = await _api.analyzeImage(_image!);
      setState(() => _result = NutritionResult.fromJson(json));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Analysis failed. Check backend connection.');
    } finally {
      setState(() => _analyzing = false);
    }
  }

  // ── Analyze text via Python backend ──────────────────────────────────────
  Future<void> _analyzeText() async {
    final t = _textCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() { _analyzing = true; _error = null; });
    try {
      // ✅ await the future properly
      final json = await _api.analyzeText(t, cuisineHint: 'indian');
      final data = await json;
      setState(() => _result = NutritionResult.fromJson(data));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Analysis failed. Try again.');
    } finally {
      setState(() => _analyzing = false);
    }
  }

  // ── Log food: image + analyze + save all in one backend call ─────────────
  Future<void> _log() async {
    if (_result == null) return;
    setState(() => _saving = true);
    try {
      final client = Supabase.instance.client;
      final uid    = client.auth.currentUser!.id;

      await client.from('food_logs').insert({
        'user_id':       uid,
        'food_name':     _result!.foodName,
        'meal_type':     _mealType,
        'calories':      _result!.calories,
        'protein_g':     _result!.protein,
        'carbs_g':       _result!.carbs,
        'fat_g':         _result!.fat,
        'fiber_g':       _result!.fiber,
        'cuisine_type':  _result!.cuisineType,
        'is_indian_food': _result!.isIndianFood,
        'portion_size':  _result!.portionSize,
        'ai_confidence': _result!.confidence,
        'image_url':     null, // image upload handled separately if needed
        'logged_at':     DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ ${_result!.foodName} added to your log'),
          backgroundColor: kSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ));
      }
    } catch (e) {
      setState(() => _error = 'Failed to save: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
        ),
        title: const Text('Track Food'),
        actions: [
          GestureDetector(
            onTap: () => setState(() {
              _textMode = !_textMode;
              _image    = null;
              _result   = null;
              _error    = null;
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(children: [
                Icon(
                  _textMode
                      ? Icons.camera_alt_outlined
                      : Icons.edit_outlined,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(_textMode ? 'Camera' : 'Text',
                    style: AppTextStyles(context).display13W500),
              ]),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_textMode) _buildTextMode() else _buildCameraMode(),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _buildError(),
            ],
            if (_analyzing) _buildAnalyzing(),
            if (_result != null && !_analyzing) _buildResult(),
          ],
        ),
      ),
    );
  }

  // ── Camera mode ───────────────────────────────────────────────────────────
  Widget _buildCameraMode() => Column(children: [
    ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: _image != null
          ? Stack(children: [
        Image.file(_image!,
            width: double.infinity, height: 280, fit: BoxFit.cover),
        Positioned(
          top: 12, right: 12,
          child: GestureDetector(
            onTap: () => setState(() {
              _image  = null;
              _result = null;
              _error  = null;
            }),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.close,
                  color: Colors.white, size: 16),
            ),
          ),
        ),
        if (_result != null)
          Positioned(
            bottom: 12, left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kLime,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${_result!.calories} kcal',
                  style: AppTextStyles(context)
                      .display13W700
                      .copyWith(color: Colors.black)),
            ),
          ),
      ])
          : GestureDetector(
        onTap: () => _pick(ImageSource.camera),
        child: Container(
          width: double.infinity, height: 280,
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF222222)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: kLime.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(36),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: kLime, size: 32),
              ),
              const SizedBox(height: 16),
              Text('Tap to snap your food',
                  style: AppTextStyles(context)
                      .display16W600
                      .copyWith(color: Colors.white)),
              const SizedBox(height: 4),
              Text('AI identifies ingredients & calories instantly',
                  style: AppTextStyles(context)
                      .display13W400
                      .copyWith(color: kGray)),
            ],
          ),
        ),
      ),
    ),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(
          child: _actionBtn(
              onTap: () => _pick(ImageSource.camera),
              icon: Icons.camera_alt_rounded,
              label: 'Camera',
              primary: true)),
      const SizedBox(width: 10),
      Expanded(
          child: _actionBtn(
              onTap: () => _pick(ImageSource.gallery),
              icon: Icons.photo_library_rounded,
              label: 'Gallery',
              primary: false)),
    ]),
  ]);

  // ── Text mode ─────────────────────────────────────────────────────────────
  Widget _buildTextMode() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Describe your meal',
                style: AppTextStyles(context)
                    .display16W600
                    .copyWith(color: Colors.white)),
            const SizedBox(height: 4),
            Text('Be specific for best accuracy',
                style: AppTextStyles(context)
                    .display13W400
                    .copyWith(color: kGray)),
            const SizedBox(height: 16),
            TextField(
              controller: _textCtrl,
              maxLines: 4,
              style: AppTextStyles(context)
                  .display15W500
                  .copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText:
                'e.g. "2 rotis with dal makhani and rice"',
                hintStyle: AppTextStyles(context)
                    .display14W400
                    .copyWith(color: const Color(0xFF444444)),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                    const BorderSide(color: kLime, width: 1.5)),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _analyzing ? null : _analyzeText,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kLime,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                  elevation: 0,
                ),
                child: Text('Analyze Meal',
                    style: AppTextStyles(context).display15W700),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text('QUICK EXAMPLES',
          style: AppTextStyles(context)
              .display11W500
              .copyWith(color: kGray, letterSpacing: 1)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: [
          '2 rotis with dal tadka',
          'Chicken biryani plate',
          'Masala dosa',
          'Palak paneer with rice',
          'Chicken breast 200g',
          'Greek yogurt 150g',
        ]
            .map((s) => GestureDetector(
          onTap: () =>
              setState(() => _textCtrl.text = s),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                  color: const Color(0xFF222222)),
            ),
            child: Text(s,
                style: AppTextStyles(context)
                    .display13W500
                    .copyWith(color: Colors.white)),
          ),
        ))
            .toList(),
      ),
    ],
  );

  // ── Analyzing spinner ─────────────────────────────────────────────────────
  Widget _buildAnalyzing() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(children: [
      const SizedBox(
        width: 48, height: 48,
        child: CircularProgressIndicator(
            color: kLime, strokeWidth: 3),
      ),
      const SizedBox(height: 16),
      Text('Analyzing with AI...',
          style: AppTextStyles(context)
              .display15W600
              .copyWith(color: Colors.white)),
      const SizedBox(height: 6),
      Text('Identifying ingredients & macros',
          style: AppTextStyles(context)
              .display13W400
              .copyWith(color: kGray)),
    ]),
  );

  // ── Error banner ──────────────────────────────────────────────────────────
  Widget _buildError() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red.withOpacity(0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 18),
      const SizedBox(width: 10),
      Expanded(
        child: Text(_error!,
            style: AppTextStyles(context)
                .display13W400
                .copyWith(color: Colors.red.shade300)),
      ),
    ]),
  );

  // ── Result card ───────────────────────────────────────────────────────────
  Widget _buildResult() {
    final r = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // AI badge
        Row(children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: kLime.withOpacity(0.15),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(children: [
              const Icon(Icons.auto_awesome, color: kLime, size: 13),
              const SizedBox(width: 5),
              Text('AI Result',
                  style: AppTextStyles(context)
                      .display12W400
                      .copyWith(color: kLime)),
              if (r.isIndianFood) ...[
                const SizedBox(width: 8),
                const Text('🇮🇳',
                    style: TextStyle(fontSize: 12)),
              ],
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '${(r.confidence * 100).toStringAsFixed(0)}% confident',
              style: AppTextStyles(context)
                  .display11W500
                  .copyWith(color: kGray),
            ),
          ),
        ]),

        const SizedBox(height: 12),

        // Main nutrition card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.foodName,
                            style: AppTextStyles(context)
                                .display20W700
                                .copyWith(
                                color: Colors.white,
                                letterSpacing: -0.3)),
                        if (r.portionSize.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(r.portionSize,
                                style: AppTextStyles(context)
                                    .display13W400
                                    .copyWith(color: kGray)),
                          ),
                        if (r.cuisineType.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF222222),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(r.cuisineType,
                                style: AppTextStyles(context)
                                    .display10W500
                                    .copyWith(color: kGray)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${r.calories}',
                          style: AppTextStyles(context)
                              .display30W400
                              .copyWith(
                              color: kLime,
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -2)),
                      Text('kcal',
                          style: AppTextStyles(context)
                              .display13W400
                              .copyWith(color: kGray)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Macro boxes
              Row(children: [
                _macroBox('Protein', '${r.protein.toStringAsFixed(0)}g',
                    const Color(0xFF4ECDC4)),
                const SizedBox(width: 8),
                _macroBox('Carbs', '${r.carbs.toStringAsFixed(0)}g',
                    const Color(0xFFFFB347)),
                const SizedBox(width: 8),
                _macroBox('Fat', '${r.fat.toStringAsFixed(0)}g',
                    const Color(0xFFFF6B9D)),
                const SizedBox(width: 8),
                _macroBox('Fiber', '${r.fiber.toStringAsFixed(0)}g',
                    const Color(0xFF90EE90)),
              ]),

              if (r.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF1E1E1E)),
                const SizedBox(height: 12),
                Text(r.description,
                    style: AppTextStyles(context)
                        .display13W400
                        .copyWith(color: kGray, height: 1.5)),
              ],

              // Ingredients
              if (r.ingredients.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF1E1E1E)),
                const SizedBox(height: 12),
                Text('Detected ingredients',
                    style: AppTextStyles(context)
                        .display11W500
                        .copyWith(
                        color: kGray,
                        letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: r.ingredients
                      .take(8)
                      .map((ing) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius:
                      BorderRadius.circular(100),
                    ),
                    child: Text(ing,
                        style: AppTextStyles(context)
                            .display11W500
                            .copyWith(color: kGray)),
                  ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Meal type selector
        Text('LOG AS',
            style: AppTextStyles(context)
                .display11W500
                .copyWith(
                color: kGray, letterSpacing: 1.2)),
        const SizedBox(height: 10),
        Row(
          children: ['breakfast', 'lunch', 'dinner', 'snack'].map((m) {
            final sel = _mealType == m;
            const icons = {
              'breakfast': '🍳', 'lunch': '🥗',
              'dinner': '🍽️', 'snack': '🍎'
            };
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _mealType = m),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? kLime.withOpacity(0.12) : kSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                      sel ? kLime : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(children: [
                    Text(icons[m]!,
                        style: AppTextStyles(context)
                            .display20W700),
                    const SizedBox(height: 4),
                    Text(
                      m[0].toUpperCase() + m.substring(1),
                      style: AppTextStyles(context)
                          .display11W500
                          .copyWith(
                          color: sel ? kLime : kGray,
                          fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Add to Log button
        SizedBox(
          width: double.infinity, height: 58,
          child: ElevatedButton(
            onPressed: _saving ? null : _log,
            style: ElevatedButton.styleFrom(
              backgroundColor: kLime,
              foregroundColor: Colors.black,
              disabledBackgroundColor: kLime.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.black))
                : Text('Add to Log',
                style: AppTextStyles(context).display17W700),
          ),
        ),
      ],
    );
  }

  Widget _macroBox(String label, String value, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(children: [
            Text(value,
                style: AppTextStyles(context).display15W700.copyWith(
                    color: color, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(label,
                style: AppTextStyles(context)
                    .display10W500
                    .copyWith(color: kGray)),
          ]),
        ),
      );

  Widget _actionBtn({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required bool primary,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: primary ? kLime : kSurface,
            borderRadius: BorderRadius.circular(100),
            border: primary
                ? null
                : Border.all(color: const Color(0xFF222222)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: primary ? Colors.black : Colors.white,
                  size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: AppTextStyles(context).display15W700.copyWith(
                      color: primary ? Colors.black : Colors.white)),
            ],
          ),
        ),
      );
}