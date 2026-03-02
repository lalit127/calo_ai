// lib/screens/onboarding_screen.dart — Cal AI exact design
// UPDATED: Removed Mistral API key input (backend handles AI now)
//          Saves profile to Supabase via Python backend instead of SharedPreferences
import 'package:cal_ai/main.dart'; // kOnboardingDoneKey
import 'package:cal_ai/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:cal_ai/theme/app_text_styles.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController    = PageController();
  final _nameController    = TextEditingController();
  final _calorieController = TextEditingController(text: '2000');
  final _proteinController = TextEditingController(text: '150');

  // No more API key controller — backend handles AI
  int    _currentPage  = 0;
  String _selectedGoal = 'Lose Weight';
  bool   _saving       = false;

  static const _lime = Color(0xFFC1FF72);

  void _next() {
    if (_currentPage < 3) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  // Saves profile to Supabase via Python backend
// Replace the _finish() method in onboarding_screen.dart
// This saves directly to Supabase — no backend call needed for profile setup.
// Bypasses the Railway timeout issue completely.

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final client = Supabase.instance.client;
      final user   = client.auth.currentUser;

      print('DEBUG token: ${client.auth.currentSession?.accessToken}');
      print('DEBUG userId: ${user?.id}');

      if (user == null) {
        throw Exception('Not logged in. Please sign in again.');
      }

      final name = _nameController.text.trim();

      // ✅ Save directly to Supabase — no Railway/backend needed for this step
      await client.from('users').upsert({
        'id':            user.id,
        'email':         user.email,
        'name':          name.isEmpty ? user.email!.split('@')[0] : name,
        'goal':          _goalKey(_selectedGoal),
        'goal_calories': int.tryParse(_calorieController.text) ?? 2000,
        'goal_protein':  double.tryParse(_proteinController.text) ?? 150.0,
        'updated_at':    DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      print('DEBUG: profile saved to Supabase ✅');

      // Mark onboarding complete
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kOnboardingDoneKey, true);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      print('DEBUG onboarding error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  String _goalKey(String label) {
    const map = {
      'Lose Weight':     'lose_weight',
      'Build Muscle':    'build_muscle',
      'Maintain Weight': 'maintain',
      'Eat Healthier':   'eat_healthier',
    };
    return map[label] ?? 'maintain';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress dots — unchanged UI ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: List.generate(4, (i) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 3,
                    decoration: BoxDecoration(
                      color: i <= _currentPage ? _lime : const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [_page1(), _page2(), _page3(), _page4()],
              ),
            ),
            // ── CTA button ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity, height: 58,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _lime,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: _lime.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100)),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.black))
                          : Text(
                        _currentPage < 3 ? 'Continue' : 'Start Tracking',
                        style: AppTextStyles(context).display17W700.copyWith(
                            color: Colors.black, letterSpacing: -0.3),
                      ),
                    ),
                  ),
                  if (_currentPage == 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Free to start · No credit card required',
                      style: AppTextStyles(context).display13W400.copyWith(
                          color: const Color(0xFF555555)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Page 1: Welcome — unchanged UI ───────────────────────────────────────
  Widget _page1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: _lime, borderRadius: BorderRadius.circular(12)),
                child: Center(
                    child: Text('🥗',
                        style: AppTextStyles(context).display24W400)),
              ),
              const SizedBox(width: 12),
              Text('Calo AI',
                  style: AppTextStyles(context).display22W700.copyWith(
                      color: Colors.white, letterSpacing: -0.5)),
            ],
          ),
          const SizedBox(height: 48),
          Text(
            'Track calories\nwith just a\npicture 📸',
            style: AppTextStyles(context).display18W700.copyWith(
              fontSize: 42, fontWeight: FontWeight.w800,
              color: Colors.white, letterSpacing: -1.5, height: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'The fastest, most accurate calorie tracker. Snap your food — AI does the rest.',
            style: AppTextStyles(context).display16W400.copyWith(
                color: const Color(0xFF888888), height: 1.5),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                Row(
                  children: [
                    _starRow(),
                    const Spacer(),
                    Text('4.9 / 5',
                        style: AppTextStyles(context).display16W700.copyWith(
                            color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '"Cal AI is literally the best calorie tracker. Fastest and most accurate I\'ve ever used."',
                  style: AppTextStyles(context).display14W400.copyWith(
                      color: const Color(0xFFCCCCCC), height: 1.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                          color: _lime, borderRadius: BorderRadius.circular(14)),
                      child: Center(
                          child: Text('A',
                              style: AppTextStyles(context).display13W700.copyWith(
                                  color: Colors.black))),
                    ),
                    const SizedBox(width: 8),
                    Text('Alex Eubank',
                        style: AppTextStyles(context).display13W400.copyWith(
                            color: const Color(0xFF888888))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statBadge('5M+', 'Users'),
              const SizedBox(width: 12),
              _statBadge('100K+', '5-star ratings'),
              const SizedBox(width: 12),
              _statBadge('#1', 'Health App'),
            ],
          ),
          const SizedBox(height: 32),
          _inputField(_nameController, 'Your name (optional)', Icons.person_outline),
        ],
      ),
    );
  }

  // ── Page 2: Goal — unchanged UI ──────────────────────────────────────────
  Widget _page2() {
    final goals = ['Lose Weight', 'Build Muscle', 'Maintain Weight', 'Eat Healthier'];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What's your\nmain goal?",
              style: AppTextStyles(context).display18W700.copyWith(
                  color: Colors.white, fontSize: 38,
                  fontWeight: FontWeight.w700, letterSpacing: -1, height: 1.1)),
          const SizedBox(height: 8),
          Text("We'll personalize your experience",
              style: AppTextStyles(context).display15W400.copyWith(
                  color: const Color(0xFF666666))),
          const SizedBox(height: 36),
          ...goals.map((g) {
            final icons = {
              'Lose Weight': '🔥', 'Build Muscle': '💪',
              'Maintain Weight': '⚖️', 'Eat Healthier': '🥦',
            };
            final selected = _selectedGoal == g;
            return GestureDetector(
              onTap: () => setState(() => _selectedGoal = g),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: selected ? _lime.withOpacity(0.12) : const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: selected ? _lime : Colors.transparent, width: 1.5),
                ),
                child: Row(
                  children: [
                    Text(icons[g]!,
                        style: AppTextStyles(context).display24W400),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(g,
                          style: AppTextStyles(context).display16W600.copyWith(
                              color: selected ? _lime : Colors.white)),
                    ),
                    if (selected)
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                            color: _lime, borderRadius: BorderRadius.circular(11)),
                        child: const Icon(Icons.check, size: 14, color: Colors.black),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ── Page 3: Goals — REMOVED Mistral API key, kept calorie/protein goals ──
  Widget _page3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Set your\ndaily goals',
              style: AppTextStyles(context).display18W700.copyWith(
                  fontSize: 38, fontWeight: FontWeight.w700,
                  color: Colors.white, letterSpacing: -1, height: 1.1)),
          const SizedBox(height: 8),
          Text('Adjustable anytime in settings',
              style: AppTextStyles(context).display15W400.copyWith(
                  color: const Color(0xFF666666))),
          const SizedBox(height: 36),

          Text('DAILY CALORIES',
              style: AppTextStyles(context).display11W500.copyWith(
                  color: const Color(0xFF555555), letterSpacing: 1.2)),
          const SizedBox(height: 10),
          _inputField(_calorieController, '2000',
              Icons.local_fire_department_outlined,
              keyboardType: TextInputType.number),
          const SizedBox(height: 20),

          Text('PROTEIN GOAL (g)',
              style: AppTextStyles(context).display11W500.copyWith(
                  color: const Color(0xFF555555), letterSpacing: 1.2)),
          const SizedBox(height: 10),
          _inputField(_proteinController, '150',
              Icons.fitness_center_outlined,
              keyboardType: TextInputType.number),
          const SizedBox(height: 28),

          Text('QUICK PRESETS',
              style: AppTextStyles(context).display11W500.copyWith(
                  color: const Color(0xFF555555), letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Row(
            children: [
              _presetChip('Cut',      '1500', '130'),
              const SizedBox(width: 8),
              _presetChip('Maintain', '2000', '150'),
              const SizedBox(width: 8),
              _presetChip('Bulk',     '2600', '180'),
            ],
          ),
          const SizedBox(height: 28),

          // ── AI info box (replaces API key input) ──────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _lime.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _lime.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Text('🤖', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI is ready to go',
                          style: AppTextStyles(context).display14W600.copyWith(
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                        'No API key needed — our backend handles AI analysis for you.',
                        style: AppTextStyles(context).display12W400.copyWith(
                            color: const Color(0xFF999999), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 4: All set — unchanged UI ───────────────────────────────────────
  Widget _page4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
                color: _lime, borderRadius: BorderRadius.circular(20)),
            child: Center(child: Text('🎯',
                style: AppTextStyles(context)
                    .display36W700
                    .copyWith(fontWeight: FontWeight.w400))),
          ),
          const SizedBox(height: 32),
          Text("You're all\nset up! 🚀",
              style: AppTextStyles(context).display36W700.copyWith(
                  fontSize: 42, fontWeight: FontWeight.w800,
                  color: Colors.white, letterSpacing: -1.5, height: 1.1)),
          const SizedBox(height: 16),
          Text(
            'Start tracking your meals with AI. Just snap a photo and get instant nutrition data.',
            style: AppTextStyles(context).display16W400.copyWith(
                color: const Color(0xFF888888), height: 1.5),
          ),
          const SizedBox(height: 40),
          _checkItem('📷', 'Snap food photos for instant analysis'),
          _checkItem('📊', 'Track calories, protein, carbs & fat'),
          _checkItem('📈', 'See your weekly progress'),
          _checkItem('🎯', 'Stay on target with custom goals'),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _lime.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _lime.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Text('💡', style: AppTextStyles(context).display24W400),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Pro tip: Good lighting = better AI accuracy. Place food on a flat surface.',
                    style: AppTextStyles(context).display14W400.copyWith(
                        color: const Color(0xFFCCCCCC), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers — unchanged UI ────────────────────────────────────────
  Widget _checkItem(String emoji, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(emoji,
              style: AppTextStyles(context).display20W500)),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(text,
            style: AppTextStyles(context).display15W500.copyWith(
                color: Colors.white))),
      ],
    ),
  );

  Widget _starRow() => Row(
    children: List.generate(5, (_) =>
    const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 18)),
  );

  Widget _statBadge(String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles(context).display18W700.copyWith(
                  color: const Color(0xFFC1FF72))),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: AppTextStyles(context).display10W400.copyWith(
                  color: const Color(0xFF666666))),
        ],
      ),
    ),
  );

  Widget _presetChip(String label, String cal, String protein) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() {
        _calorieController.text = cal;
        _proteinController.text = protein;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(label,
                style: AppTextStyles(context).display13W600.copyWith(
                    color: Colors.white)),
            const SizedBox(height: 2),
            Text('$cal kcal',
                style: AppTextStyles(context).display11W400.copyWith(
                    color: const Color(0xFF666666))),
          ],
        ),
      ),
    ),
  );

  Widget _inputField(
      TextEditingController controller,
      String hint,
      IconData icon, {
        TextInputType? keyboardType,
        bool obscure = false,
        Widget? suffix,
      }) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: AppTextStyles(context).display15W500.copyWith(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles(context).display15W400.copyWith(
              color: const Color(0xFF444444)),
          prefixIcon: Icon(icon, color: const Color(0xFF555555), size: 20),
          suffixIcon: suffix != null
              ? Padding(padding: const EdgeInsets.only(right: 14), child: suffix)
              : null,
          filled: true,
          fillColor: const Color(0xFF111111),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: Color(0xFFC1FF72), width: 1.5)),
        ),
      );
}