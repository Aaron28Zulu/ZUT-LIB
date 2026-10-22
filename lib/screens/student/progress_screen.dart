import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/study_assistant_service.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

/// FR-SSA-11: quiz scores over time per course, strongest and weakest topics.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String? _courseId;

  @override
  Widget build(BuildContext context) {
    final study = context.watch<AppState>().study;
    final courses = study.enrolledCourses();
    final withAttempts = courses.where((c) => study.attempts(courseId: c.id).isNotEmpty).toList();
    _courseId ??= withAttempts.firstOrNull?.id ?? courses.firstOrNull?.id;
    final attempts = _courseId == null ? <QuizAttempt>[] : study.attempts(courseId: _courseId);
    final stats = _courseId == null ? <TopicStat>[] : study.topicStats(courseId: _courseId);

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: courses.isEmpty
          ? const EmptyState(icon: Icons.show_chart, message: 'Add courses to your profile to track progress.')
          : ListView(
              padding: const EdgeInsets.only(bottom: Space.xl),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(Space.l),
                  child: Row(
                    spacing: Space.s,
                    children: [
                      for (final c in courses)
                        ChoiceChip(
                          label: Text(c.code),
                          selected: c.id == _courseId,
                          onSelected: (_) => setState(() => _courseId = c.id),
                        ),
                    ],
                  ),
                ),
                if (attempts.isEmpty)
                  const Padding(
                    padding: Space.screen,
                    child: Text('No quizzes taken for this course yet. Take a practice quiz to see your scores here.'),
                  )
                else ...[
                  Padding(
                    padding: Space.screen,
                    child: Text('Quiz scores', style: Theme.of(context).textTheme.titleSmall),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.s, Space.l, Space.xl, 0),
                    child: SizedBox(height: 220, child: _ScoreChart(attempts: attempts)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
                    child: Text(
                      '${attempts.length} attempts. Latest ${attempts.last.score}% on ${formatDate(attempts.last.finishedAt)}.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SectionHeader('Weakest topics'),
                  for (final s in stats.take(3))
                    ListTile(dense: true, title: Text(s.topic), trailing: Text('${s.percent}%', style: AppText.code(context))),
                  const SectionHeader('Strongest topics'),
                  for (final s in stats.reversed.take(3))
                    ListTile(dense: true, title: Text(s.topic), trailing: Text('${s.percent}%', style: AppText.code(context))),
                ],
              ],
            ),
    );
  }
}

class _ScoreChart extends StatelessWidget {
  const _ScoreChart({required this.attempts});

  final List<QuizAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    return Semantics(
      label: 'Line chart of ${attempts.length} quiz scores, latest ${attempts.last.score} percent',
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          minX: 0,
          maxX: (attempts.length - 1).toDouble().clamp(1, double.infinity),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) => FlLine(color: scheme.outlineVariant, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 25,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: labelStyle),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= attempts.length || v != i.toDouble()) return const SizedBox.shrink();
                  final d = attempts[i].finishedAt.toLocal();
                  return Padding(padding: const EdgeInsets.only(top: 4), child: Text('${d.day}/${d.month}', style: labelStyle));
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < attempts.length; i++) FlSpot(i.toDouble(), attempts[i].score.toDouble())],
              color: scheme.primary,
              barWidth: 2,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}
