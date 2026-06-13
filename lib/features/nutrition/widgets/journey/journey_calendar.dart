import 'package:flutter/material.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/shared/models/journey_stats.dart';

class JourneyCalendar extends StatelessWidget {
  final int year;
  final int month;
  final List<JourneyCalendarDay> days;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final bool canGoNext;

  const JourneyCalendar({
    super.key,
    required this.year,
    required this.month,
    required this.days,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.canGoNext,
  });

  static const _monthNames = [
    '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];
  static const _dayHeaders = ['Di', 'Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa'];

  @override
  Widget build(BuildContext context) {
    appLogger.provider('JourneyCalendar build() | $year-$month');

    final firstOfMonth = DateTime(year, month, 1);
    final startDow    = firstOfMonth.weekday % 7; // 0=Sun … 6=Sat
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final today       = DateTime.now();
    final isCurrentMonth = today.year == year && today.month == month;

    final dayMap = {for (final d in days) d.date.day: d};

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // ── Month navigation ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AkeliColors.onSurfaceVariant),
                onPressed: onPrevMonth,
                visualDensity: VisualDensity.compact,
              ),
              Text(
                '${_monthNames[month]} $year',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AkeliColors.onSurface,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: canGoNext ? AkeliColors.onSurfaceVariant : AkeliColors.outlineVariant,
                ),
                onPressed: canGoNext ? onNextMonth : null,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Day-of-week headers ──
          Row(
            children: _dayHeaders
                .map((h) => Expanded(
                      child: Center(
                        child: Text(
                          h,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AkeliColors.outlineVariant,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          // ── Day grid ──
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 0.85,
            ),
            itemCount: startDow + daysInMonth,
            itemBuilder: (context, i) {
              if (i < startDow) return const SizedBox.shrink();
              final dayNum  = i - startDow + 1;
              final isToday = isCurrentMonth && dayNum == today.day;
              final isFuture = DateTime(year, month, dayNum).isAfter(today);
              final dayData  = dayMap[dayNum];
              return _DayCell(
                dayNum:   dayNum,
                isToday:  isToday,
                isFuture: isFuture,
                planned:  isFuture ? 0 : (dayData?.planned  ?? 0),
                consumed: isFuture ? 0 : (dayData?.consumed ?? 0),
              );
            },
          ),
          const SizedBox(height: 12),
          // ── Legend ──
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: Color(0xFF4ADE80), label: 'Tous'),
              SizedBox(width: 14),
              _LegendItem(color: Color(0xFFFACC15), label: 'Partiel'),
              SizedBox(width: 14),
              _LegendItem(color: Color(0xFFEF4444), label: 'Aucun'),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Day cell ──────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final int  dayNum;
  final bool isToday;
  final bool isFuture;
  final int  planned;
  final int  consumed;

  // Show pips only when planned count is small enough to fit legibly.
  static const _maxPips = 4;

  const _DayCell({
    required this.dayNum,
    required this.isToday,
    required this.isFuture,
    required this.planned,
    required this.consumed,
  });

  Color _bgColor() {
    if (isFuture || planned == 0) return AkeliColors.surfaceContainer;
    if (consumed == planned)      return const Color(0xFFDCFCE7); // full — green tint
    if (consumed > 0)             return const Color(0xFFFEF9C3); // partial — yellow tint
    return const Color(0xFFFEE2E2);                               // missed — red tint
  }

  Color _accentColor() {
    if (isFuture || planned == 0) return AkeliColors.onSurfaceVariant;
    if (consumed == planned)      return const Color(0xFF166534);
    if (consumed > 0)             return const Color(0xFF854D0E);
    return const Color(0xFF991B1B);
  }

  @override
  Widget build(BuildContext context) {
    final showPips = !isFuture && planned > 0 && planned <= _maxPips;
    final accent   = _accentColor();

    return Container(
      decoration: BoxDecoration(
        color: _bgColor(),
        borderRadius: BorderRadius.circular(6),
        border: isToday ? Border.all(color: AkeliColors.primary, width: 1.5) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$dayNum',
            style: TextStyle(
              fontSize: 11,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              color: isToday ? AkeliColors.primary : accent,
            ),
          ),
          if (showPips) ...[
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(planned, (i) {
                final eaten = i < consumed;
                return Container(
                  width:  4,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: eaten ? accent : Colors.transparent,
                    border: eaten
                        ? null
                        : Border.all(color: accent.withValues(alpha: 0.45), width: 1),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Legend item ───────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color  color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AkeliColors.onSurfaceVariant)),
      ],
    );
  }
}
