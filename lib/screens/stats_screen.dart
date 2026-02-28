// lib/screens/stats_screen.dart
import 'package:cal_ai/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_text_styles.dart';
import 'home_screen.dart';

const _kLime    = Color(0xFFC1FF72);
const _kSurface = Color(0xFF111111);
const _kGray    = Color(0xFF888888);
const _kGray2   = Color(0xFF333333);

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadWeekly();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final weekly = prov.weekly;

    if (prov.loadingWeekly) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: kLime)),
      );
    }

    final days       = List<Map<String, dynamic>>.from(weekly['days'] ?? []);
    final avgCal     = (weekly['avg_calories'] ?? 0).toDouble();
    final streak     = weekly['streak'] ?? 0;
    final totalCal   = weekly['total_calories'] ?? 0;
    final goalCal    = prov.goalCalories;

    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        color: kLime,
        backgroundColor: kSurface,
        onRefresh: () => prov.loadWeekly(),
        child: CustomScrollView(
          slivers: [

            // ── Header ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text('Stats',
                      style: AppTextStyles(context)
                          .display22W700
                          .copyWith(
                          color: Colors.white, letterSpacing: -0.5)),
                ),
              ),
            ),

            // ── Streak + avg summary ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(children: [
                  Expanded(
                    child: _StatSummaryCard(
                      emoji: '🔥',
                      value: '$streak',
                      label: 'Day Streak',
                      color: kLime,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatSummaryCard(
                      emoji: '📊',
                      value: avgCal.toStringAsFixed(0),
                      label: 'Avg kcal/day',
                      color: const Color(0xFF4ECDC4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatSummaryCard(
                      emoji: '📅',
                      value: '${days.where((d) => (d['logged'] ?? false)).length}',
                      label: 'Days logged',
                      color: const Color(0xFFFFB347),
                    ),
                  ),
                ]),
              ),
            ),

            // ── Bar chart ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _WeeklyBarChart(days: days, goalCal: goalCal),
              ),
            ),

            // ── Today's macros breakdown ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _MacroBreakdown(prov: prov),
              ),
            ),

            // ── 7-day list ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Daily Breakdown',
                        style: AppTextStyles(context)
                            .display18W700
                            .copyWith(
                            color: Colors.white,
                            letterSpacing: -0.3)),
                    Text('This Week',
                        style: AppTextStyles(context)
                            .display13W400
                            .copyWith(color: kGray)),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (_, i) {
                    final d = days[days.length - 1 - i]; // newest first
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DayRow(day: d, goalCal: goalCal),
                    );
                  },
                  childCount: days.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────
class _StatSummaryCard extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  const _StatSummaryCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(height: 8),
      Text(value,
          style: AppTextStyles(context)
              .display20W700
              .copyWith(color: color, letterSpacing: -0.5)),
      const SizedBox(height: 4),
      Text(label,
          textAlign: TextAlign.center,
          style: AppTextStyles(context)
              .display10W400
              .copyWith(color: kGray)),
    ]),
  );
}

// ── Weekly bar chart ──────────────────────────────────────────────────────────
class _WeeklyBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> days;
  final int goalCal;
  const _WeeklyBarChart({required this.days, required this.goalCal});

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox();

    final maxCal = days
        .map((d) => (d['calories'] ?? 0) as int)
        .fold(0, (a, b) => a > b ? a : b);
    final chartMax = (maxCal > goalCal ? maxCal : goalCal) * 1.2;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly Calories',
                  style: AppTextStyles(context)
                      .display15W700
                      .copyWith(color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kLime.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('Goal: $goalCal',
                    style: AppTextStyles(context)
                        .display11W500
                        .copyWith(color: kLime)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((d) {
                final cal     = (d['calories'] ?? 0) as int;
                final goalMet = d['goal_met'] ?? false;
                final barH    = cal == 0
                    ? 4.0
                    : (cal / chartMax * 100).clamp(4.0, 100.0);
                final dateStr = (d['date'] as String).substring(5); // MM-DD
                final dow     = _dayLabel(d['date'] as String);

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (cal > 0)
                        Text('$cal',
                            style: AppTextStyles(context)
                                .display10W400
                                .copyWith(color: kGray),
                            textScaleFactor: 0.85),
                      const SizedBox(height: 4),
                      Container(
                        width: 28,
                        height: barH,
                        decoration: BoxDecoration(
                          color: cal == 0
                              ? const Color(0xFF222222)
                              : goalMet
                              ? kLime
                              : kLime.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(dow,
                          style: AppTextStyles(context)
                              .display10W500
                              .copyWith(color: kGray)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          // Goal line label
          const SizedBox(height: 12),
          Row(children: [
            Container(
                width: 20, height: 2, color: kLime.withOpacity(0.4)),
            const SizedBox(width: 6),
            Text('Daily goal',
                style: AppTextStyles(context)
                    .display11W400
                    .copyWith(color: kGray)),
            const SizedBox(width: 20),
            Container(width: 20, height: 2, color: kLime),
            const SizedBox(width: 6),
            Text('Goal met',
                style: AppTextStyles(context)
                    .display11W400
                    .copyWith(color: kGray)),
          ]),
        ],
      ),
    );
  }

  String _dayLabel(String isoDate) {
    final d = DateTime.tryParse(isoDate);
    if (d == null) return '';
    return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][d.weekday % 7];
  }
}

// ── Macro breakdown (today) ───────────────────────────────────────────────────
class _MacroBreakdown extends StatelessWidget {
  final AppProvider prov;
  const _MacroBreakdown({required this.prov});

  @override
  Widget build(BuildContext context) {
    final macros = [
      {
        'label': 'Protein',
        'value': prov.totalProtein,
        'goal': prov.goalProtein,
        'color': const Color(0xFF4ECDC4),
        'unit': 'g',
      },
      {
        'label': 'Carbs',
        'value': prov.totalCarbs,
        'goal': prov.goalCarbs,
        'color': const Color(0xFFFFB347),
        'unit': 'g',
      },
      {
        'label': 'Fat',
        'value': prov.totalFat,
        'goal': prov.goalFat,
        'color': const Color(0xFFFF6B9D),
        'unit': 'g',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Macros",
              style: AppTextStyles(context)
                  .display15W700
                  .copyWith(color: Colors.white)),
          const SizedBox(height: 16),
          ...macros.map((m) {
            final val  = (m['value'] as double);
            final goal = (m['goal'] as double);
            final pct  = (val / goal).clamp(0.0, 1.0);
            final color = m['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(m['label'] as String,
                        style: AppTextStyles(context)
                            .display13W500
                            .copyWith(color: kGray)),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${val.toStringAsFixed(0)}',
                            style: AppTextStyles(context)
                                .display13W700
                                .copyWith(color: Colors.white),
                          ),
                          TextSpan(
                            text: ' / ${goal.toStringAsFixed(0)}${m['unit']}',
                            style: AppTextStyles(context)
                                .display12W400
                                .copyWith(color: kGray),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: const Color(0xFF222222),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ]),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ── Day row in the list ───────────────────────────────────────────────────────
class _DayRow extends StatelessWidget {
  final Map<String, dynamic> day;
  final int goalCal;
  const _DayRow({required this.day, required this.goalCal});

  @override
  Widget build(BuildContext context) {
    final cal     = (day['calories'] ?? 0) as int;
    final goalMet = day['goal_met'] ?? false;
    final logged  = day['logged'] ?? false;
    final dateStr = day['date'] as String;
    final dt      = DateTime.tryParse(dateStr);
    final label   = dt != null
        ? DateFormat('EEE, MMM d').format(dt)
        : dateStr;
    final pct = cal == 0 ? 0.0 : (cal / goalCal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        // Status dot
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: !logged
                ? const Color(0xFF333333)
                : goalMet
                ? kLime
                : const Color(0xFFFFB347),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles(context)
                      .display13W500
                      .copyWith(color: Colors.white)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 4,
                  backgroundColor: const Color(0xFF222222),
                  valueColor: AlwaysStoppedAnimation(
                      goalMet ? kLime : const Color(0xFFFFB347)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              logged ? '$cal kcal' : '—',
              style: AppTextStyles(context)
                  .display13W700
                  .copyWith(color: logged ? Colors.white : kGray),
            ),
            if (logged)
              Text(
                goalMet ? '✓ goal' : '${goalCal - cal} left',
                style: AppTextStyles(context)
                    .display10W400
                    .copyWith(
                    color: goalMet ? kLime : const Color(0xFFFFB347)),
              ),
          ],
        ),
      ]),
    );
  }
}