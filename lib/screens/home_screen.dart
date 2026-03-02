// lib/screens/home_screen.dart
import 'package:cal_ai/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../models/food_entry.dart';
import '../theme/app_text_styles.dart';
import 'camera_screen.dart';
import 'log_screen.dart';
import 'stats_screen.dart';
import 'setting_screen.dart';

const kLime = Color(0xFFC1FF72);
const kBlack = Color(0xFF000000);
const kSurface = Color(0xFF111111);
const kSurface2 = Color(0xFF1A1A1A);
const kGray = Color(0xFF888888);
const kGray2 = Color(0xFF555555);

// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    // Init data on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlack,
      body: IndexedStack(
        index: _tab,
        children: const [
          _Dashboard(),
          LogScreen(),
          StatsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'icon': Icons.home_outlined,
        'active': Icons.home_rounded,
        'label': 'Home',
      },
      {
        'icon': Icons.list_alt_outlined,
        'active': Icons.list_alt_rounded,
        'label': 'Log',
      },
      {
        'icon': Icons.bar_chart_outlined,
        'active': Icons.bar_chart_rounded,
        'label': 'Stats',
      },
      {
        'icon': Icons.person_outline,
        'active': Icons.person_rounded,
        'label': 'Profile',
      },
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: Color(0xFF1A1A1A))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final sel = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        sel
                            ? items[i]['active'] as IconData
                            : items[i]['icon'] as IconData,
                        color: sel ? kLime : kGray2,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i]['label'] as String,
                        style: AppTextStyles(context).display11W500.copyWith(
                          color: sel ? kLime : kGray2,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Dashboard tab ─────────────────────────────────────────────────────────────
class _Dashboard extends StatelessWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();

    if (prov.loadingDaily && prov.todayEntries.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kLime));
    }

    return RefreshIndicator(
      color: kLime,
      backgroundColor: kSurface,
      onRefresh: () => context.read<AppProvider>().init(),
      child: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: AppTextStyles(
                            context,
                          ).display14W500.copyWith(color: kGray),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          prov.userName,
                          style: AppTextStyles(context).display22W700.copyWith(
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    _SnapButton(),
                  ],
                ),
              ),
            ),
          ),

          // ── Calorie ring ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _CalorieRingCard(
                consumed: prov.totalCal,
                goal: prov.goalCalories,
                remaining: prov.goalCalories - prov.totalCal,
                progress: prov.goalCalories > 0
                    ? (prov.totalCal / prov.goalCalories).clamp(0.0, 1.0)
                    : 0.0,
              ),
            ),
          ),

          // ── Water row ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: _WaterCard(
                totalMl: prov.totalWater,
                goalMl: prov.goalWaterMl,
              ),
            ),
          ),

          // ── Macro cards ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _MacroCard(
                      'Protein',
                      prov.totalProtein,
                      prov.goalProtein,
                      const Color(0xFF4ECDC4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MacroCard(
                      'Carbs',
                      prov.totalCarbs,
                      prov.goalCarbs,
                      const Color(0xFFFFB347),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MacroCard(
                      'Fat',
                      prov.totalFat,
                      prov.goalFat,
                      const Color(0xFFFF6B9D),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Meals header ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Meals",
                    style: AppTextStyles(context).display18W700.copyWith(
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d').format(DateTime.now()),
                    style: AppTextStyles(
                      context,
                    ).display14W500.copyWith(color: kGray),
                  ),
                ],
              ),
            ),
          ),

          // ── Entries ──────────────────────────────────────────────────────
          if (prov.todayEntries.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _EmptyMeals(),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _MealTile(prov.todayEntries[i]),
                  ),
                  childCount: prov.todayEntries.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning 👋';
    if (h < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }
}

// ── Snap button ───────────────────────────────────────────────────────────────
class _SnapButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CameraScreen()),
        );
        context.read<AppProvider>().loadDaily();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: kLime,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 18),
            const SizedBox(width: 6),
            Text(
              'Snap',
              style: AppTextStyles(
                context,
              ).display14W700.copyWith(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Calorie Ring Card ─────────────────────────────────────────────────────────
class _CalorieRingCard extends StatelessWidget {
  final int consumed, goal, remaining;
  final double progress;
  const _CalorieRingCard({
    required this.consumed,
    required this.goal,
    required this.remaining,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final over = remaining < 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  painter: _RingPainter(progress: progress, over: over),
                  size: const Size(120, 120),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      remaining.abs().toString(),
                      style: AppTextStyles(context).display24W600.copyWith(
                        color: over ? Colors.red : Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      over ? 'over' : 'left',
                      style: AppTextStyles(
                        context,
                      ).display11W500.copyWith(color: kGray),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statRow(context, 'Eaten', '$consumed kcal', kLime),
                const SizedBox(height: 14),
                _statRow(context, 'Goal', '$goal kcal', Colors.white),
                const SizedBox(height: 14),
                _statRow(
                  context,
                  'Remaining',
                  '${remaining.abs()} kcal',
                  over ? Colors.red : const Color(0xFF888888),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(BuildContext ctx, String label, String value, Color vc) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles(ctx).display13W500.copyWith(color: kGray),
          ),
          Text(
            value,
            style: AppTextStyles(ctx).display13W700.copyWith(color: vc),
          ),
        ],
      );
}

// ── Ring Painter ──────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final bool over;
  const _RingPainter({required this.progress, required this.over});
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 10;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0xFF222222)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = over ? Colors.red : kLime
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.progress != progress || o.over != over;
}

// ── Water Card ────────────────────────────────────────────────────────────────
class _WaterCard extends StatelessWidget {
  final int totalMl, goalMl;
  const _WaterCard({required this.totalMl, required this.goalMl});

  @override
  Widget build(BuildContext context) {
    final pct = (totalMl / goalMl).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Text('💧', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Water',
                      style: AppTextStyles(
                        context,
                      ).display13W500.copyWith(color: kGray),
                    ),
                    Text(
                      '${totalMl}ml / ${goalMl}ml',
                      style: AppTextStyles(
                        context,
                      ).display12W400.copyWith(color: kGray),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: const Color(0xFF222222),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF5BC0EB)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Quick add buttons
          GestureDetector(
            onTap: () => context.read<AppProvider>().logWater(250),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF5BC0EB).withOpacity(0.15),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: const Color(0xFF5BC0EB).withOpacity(0.3),
                ),
              ),
              child: Text(
                '+250ml',
                style: AppTextStyles(
                  context,
                ).display12W400.copyWith(color: const Color(0xFF5BC0EB)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Macro Card ────────────────────────────────────────────────────────────────
class _MacroCard extends StatelessWidget {
  final String label;
  final double value, goal;
  final Color color;
  const _MacroCard(this.label, this.value, this.goal, this.color);
  @override
  Widget build(BuildContext context) {
    final progress = (value / goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles(context).display11W500.copyWith(color: kGray),
          ),
          const SizedBox(height: 6),
          Text(
            '${value.toStringAsFixed(0)}g',
            style: AppTextStyles(
              context,
            ).display18W700.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFF2A2A2A),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '/ ${goal.toStringAsFixed(0)}g',
            style: AppTextStyles(context).display10W500.copyWith(color: kGray2),
          ),
        ],
      ),
    );
  }
}

// ── Meal Tile ─────────────────────────────────────────────────────────────────
class _MealTile extends StatelessWidget {
  final FoodEntry entry;
  const _MealTile(this.entry);
  @override
  Widget build(BuildContext context) {
    const emojis = {
      'breakfast': '🍳',
      'lunch': '🥗',
      'dinner': '🍽️',
      'snack': '🍎',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          // Image or emoji
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: entry.imageUrl != null
                ? Image.network(
                    entry.imageUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _emojiBox(context, emojis, entry.mealType),
                  )
                : _emojiBox(context, emojis, entry.mealType),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.name,
                        style: AppTextStyles(
                          context,
                        ).display15W600.copyWith(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.isIndianFood)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: kLime.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '🇮🇳',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'P ${entry.protein.toStringAsFixed(0)}g · C ${entry.carbs.toStringAsFixed(0)}g · F ${entry.fat.toStringAsFixed(0)}g',
                  style: const TextStyle(color: kGray, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.calories}',
                style: AppTextStyles(
                  context,
                ).display18W700.copyWith(color: kLime),
              ),
              Text(
                'kcal',
                style: AppTextStyles(
                  context,
                ).display11W500.copyWith(color: kGray),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emojiBox(BuildContext ctx, Map<String, String> emojis, String type) =>
      Container(
        width: 44,
        height: 44,
        color: kSurface2,
        child: Center(
          child: Text(
            emojis[type] ?? '🍽️',
            style: AppTextStyles(ctx).display22W700,
          ),
        ),
      );
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyMeals extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CameraScreen()),
        );
        context.read<AppProvider>().loadDaily();
      },
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E1E1E)),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: kLime.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: kLime,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No meals logged yet',
              style: AppTextStyles(
                context,
              ).display14W500.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap to snap your first meal',
              style: AppTextStyles(
                context,
              ).display14W500.copyWith(color: kGray),
            ),
          ],
        ),
      ),
    );
  }
}
