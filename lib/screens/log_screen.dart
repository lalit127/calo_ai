// lib/screens/log_screen.dart
import 'package:cal_ai/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/food_entry.dart';
import '../theme/app_text_styles.dart';
import 'camera_screen.dart';
import 'home_screen.dart';

const _kLime    = Color(0xFFC1FF72);
const _kSurface = Color(0xFF111111);
const _kGray    = Color(0xFF888888);

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});
  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  DateTime _date = DateTime.now();

  bool get _isToday {
    final n = DateTime.now();
    return _date.year == n.year &&
        _date.month == n.month &&
        _date.day == n.day;
  }

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _changeDate(int delta) {
    setState(() => _date = _date.add(Duration(days: delta)));
    context.read<AppProvider>().loadDaily(date: _isoDate(_date));
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final entries = prov.todayEntries;

    // Group by meal type
    final grouped = <String, List<FoodEntry>>{};
    for (final e in entries) {
      grouped.putIfAbsent(e.mealType, () => []).add(e);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [

          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Text('Food Log',
                  style: AppTextStyles(context)
                      .display22W700
                      .copyWith(color: Colors.white, letterSpacing: -0.5)),
              const Spacer(),
              // Date navigator
              Container(
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(children: [
                  _navBtn(Icons.chevron_left, () => _changeDate(-1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _isToday
                          ? 'Today'
                          : DateFormat('MMM d').format(_date),
                      style: AppTextStyles(context)
                          .display13W600
                          .copyWith(color: Colors.white),
                    ),
                  ),
                  _navBtn(
                    Icons.chevron_right,
                    _isToday ? null : () => _changeDate(1),
                  ),
                ]),
              ),
            ]),
          ),

          // ── Daily summary card ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Calories',
                            style: AppTextStyles(context)
                                .display12W400
                                .copyWith(color: kGray)),
                        Text('${prov.totalCal}',
                            style: AppTextStyles(context)
                                .display30W400
                                .copyWith(
                                color: kLime,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1)),
                      ],
                    ),
                    Text('/ ${prov.goalCalories} kcal',
                        style: AppTextStyles(context)
                            .display14W400
                            .copyWith(color: kGray)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (prov.totalCal / prov.goalCalories)
                        .clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: const Color(0xFF222222),
                    valueColor: AlwaysStoppedAnimation(
                      prov.totalCal > prov.goalCalories
                          ? Colors.red
                          : kLime,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  _macroStat('Protein',
                      '${prov.totalProtein.toStringAsFixed(0)}g',
                      const Color(0xFF4ECDC4)),
                  _macroStat('Carbs',
                      '${prov.totalCarbs.toStringAsFixed(0)}g',
                      const Color(0xFFFFB347)),
                  _macroStat('Fat',
                      '${prov.totalFat.toStringAsFixed(0)}g',
                      const Color(0xFFFF6B9D)),
                  _macroStat('Meals', '${entries.length}',
                      Colors.white),
                ]),
              ]),
            ),
          ),

          // ── Entries list ────────────────────────────────────────────────
          Expanded(
            child: prov.loadingDaily
                ? const Center(
                child: CircularProgressIndicator(color: kLime))
                : entries.isEmpty
                ? _emptyState(context)
                : RefreshIndicator(
              color: kLime,
              backgroundColor: kSurface,
              onRefresh: () =>
                  prov.loadDaily(date: _isoDate(_date)),
              child: ListView(
                padding:
                const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  'breakfast', 'lunch', 'dinner', 'snack'
                ]
                    .where((m) => grouped.containsKey(m))
                    .map((m) =>
                    _mealSection(context, m, grouped[m]!))
                    .toList(),
              ),
            ),
          ),
        ]),
      ),

      // FAB to add meal
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CameraScreen()));
          context.read<AppProvider>().loadDaily(date: _isoDate(_date));
        },
        backgroundColor: kLime,
        foregroundColor: Colors.black,
        elevation: 0,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Icon(icon,
          color: onTap == null
              ? const Color(0xFF333333)
              : Colors.white,
          size: 20),
    ),
  );

  Widget _macroStat(String label, String value, Color color) =>
      Expanded(
        child: Column(children: [
          Text(value,
              style: AppTextStyles(context)
                  .display15W700
                  .copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles(context)
                  .display10W400
                  .copyWith(color: kGray)),
        ]),
      );

  Widget _mealSection(
      BuildContext ctx, String mealType, List<FoodEntry> meals) {
    const emojis = {
      'breakfast': '🍳', 'lunch': '🥗',
      'dinner': '🍽️', 'snack': '🍎'
    };
    final totalCal = meals.fold(0, (s, e) => s + e.calories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Text(emojis[mealType]!,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              mealType[0].toUpperCase() + mealType.substring(1),
              style: AppTextStyles(ctx)
                  .display15W700
                  .copyWith(color: Colors.white),
            ),
            const Spacer(),
            Text('$totalCal kcal',
                style: AppTextStyles(ctx)
                    .display13W600
                    .copyWith(color: kLime)),
          ]),
        ),
        ...meals.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Dismissible(
            key: Key(e.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red.shade900,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Colors.white),
            ),
            onDismissed: (_) =>
                context.read<AppProvider>().deleteEntry(e.id),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                // Image thumbnail
                if (e.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      e.imageUrl!,
                      width: 40, height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const SizedBox(width: 40),
                    ),
                  ),
                if (e.imageUrl != null) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(e.name,
                              style: AppTextStyles(ctx)
                                  .display14W600
                                  .copyWith(color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (e.isIndianFood)
                          const Text('🇮🇳',
                              style: TextStyle(fontSize: 11)),
                      ]),
                      const SizedBox(height: 3),
                      Text(
                        'P ${e.protein.toStringAsFixed(0)}g  C ${e.carbs.toStringAsFixed(0)}g  F ${e.fat.toStringAsFixed(0)}g',
                        style: AppTextStyles(ctx)
                            .display12W400
                            .copyWith(color: kGray),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${e.calories}',
                        style: AppTextStyles(ctx)
                            .display18W700
                            .copyWith(color: kLime)),
                    Text('kcal',
                        style: AppTextStyles(ctx)
                            .display11W400
                            .copyWith(color: kGray)),
                  ],
                ),
              ]),
            ),
          ),
        )),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _emptyState(BuildContext ctx) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🍽️', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text('Nothing logged yet',
            style: AppTextStyles(ctx)
                .display18W700
                .copyWith(color: Colors.white)),
        const SizedBox(height: 6),
        Text(
          _isToday
              ? 'Tap + to log your first meal'
              : 'No meals logged on this day',
          style: AppTextStyles(ctx)
              .display14W400
              .copyWith(color: kGray),
        ),
      ],
    ),
  );
}