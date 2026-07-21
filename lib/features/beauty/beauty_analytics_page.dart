import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/beauty_plan_provider.dart';
import '../../shared/models/beauty_log.dart';
import '../../shared/models/beauty_plan.dart';
import 'widgets/beauty_checkin_sheet.dart';

class BeautyAnalyticsPage extends ConsumerStatefulWidget {
  const BeautyAnalyticsPage({super.key});

  @override
  ConsumerState<BeautyAnalyticsPage> createState() => _BeautyAnalyticsPageState();
}

class _BeautyAnalyticsPageState extends ConsumerState<BeautyAnalyticsPage> {
  String _selectedTimeframe = '30 Jours';

  static const Color _rosewood = Color(0xFF8A3B58);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _darkCardBg = Color(0xFF231821);

  @override
  Widget build(BuildContext context) {
    final activePlanAsync = ref.watch(activeBeautyPlanProvider);
    final beautyLogsAsync = ref.watch(beautyLogsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF140D13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF140D13),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Suivi Beauté & Rituals',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined, color: _gold, size: 22),
            tooltip: 'Nouveau Bilan Beauté',
            onPressed: () => _openCheckinSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _rosewood,
        backgroundColor: const Color(0xFF231821),
        onRefresh: () async {
          ref.invalidate(activeBeautyPlanProvider);
          ref.invalidate(beautyLogsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildEditorialHeader(),
            const SizedBox(height: 16),
            _buildTimeframeFilterPills(),
            const SizedBox(height: 20),
            
            // 1. Ritual Adherence Metric Card
            activePlanAsync.when(
              data: (plan) => _buildAdherenceCard(plan),
              loading: () => const Center(child: CircularProgressIndicator(color: _rosewood)),
              error: (_, __) => _buildAdherenceCard(null),
            ),
            const SizedBox(height: 24),

            // 2. Progression Logs Visualizer & Diagnostics
            beautyLogsAsync.when(
              data: (logs) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHairProgressionSection(logs),
                  const SizedBox(height: 24),
                  _buildSkinProgressionSection(logs),
                  const SizedBox(height: 28),
                  _buildLogsHistoryTimeline(logs),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator(color: _rosewood)),
              error: (err, _) => Center(
                child: Text(
                  'Erreur de chargement des bilans: $err',
                  style: GoogleFonts.nunito(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCheckinSheet(context),
        backgroundColor: _rosewood,
        elevation: 6,
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        label: Text(
          'Nouveau Bilan',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _openCheckinSheet(BuildContext context) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final checkinData = await BeautyCheckinSheet.show(
      context,
      userId: user.id,
    );

    if (checkinData != null) {
      await ref.read(addBeautyLogNotifierProvider.notifier).addLog(
        hairLengthCm: (checkinData['hairLengthCm'] as num?)?.toDouble() ?? 15.0,
        hairStrengthScore: (checkinData['hairStrengthScore'] as num?)?.toDouble() ?? 7.0,
        hairThicknessScore: (checkinData['hairThicknessScore'] as num?)?.toDouble() ?? 7.0,
        hairSheddingRate: checkinData['hairSheddingRate'] as String? ?? 'moderate',
        skinHydrationLevel: (checkinData['skinHydrationLevel'] as num?)?.toDouble() ?? 7.0,
        skinClarityScore: (checkinData['skinClarityScore'] as num?)?.toDouble() ?? 7.0,
        checkinNotes: checkinData['checkinNotes'] as String?,
      );
    }
  }

  Widget _buildEditorialHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _rosewood.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _rosewood.withOpacity(0.5)),
              ),
              child: Text(
                'DIAGNOSTIC & SUIVI RITUEL',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: _gold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tableau de Bord Beauté 👑',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Analysez votre régularité rituelle, la repousse capillaire et l\'évolution de votre teint.',
          style: GoogleFonts.nunito(
            fontSize: 13,
            color: Colors.white70,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeframeFilterPills() {
    final options = ['7 Jours', '30 Jours', '90 Jours', 'Tout'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((label) {
          final isSelected = _selectedTimeframe == label;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedTimeframe = label);
                }
              },
              selectedColor: _rosewood,
              backgroundColor: const Color(0xFF231821),
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white60,
              ),
              side: BorderSide(
                color: isSelected ? _gold : Colors.white10,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdherenceCard(BeautyPlan? plan) {
    int totalSlots = plan?.slots.length ?? 0;
    int completedSlots = plan?.slots.where((s) => s.isCompleted).length ?? 0;
    double percentage = totalSlots > 0 ? (completedSlots / totalSlots) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _darkCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _rosewood.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: _rosewood.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assiduité du Rituel',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: _gold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($completedSlots/$totalSlots soins)',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_rosewood, _gold.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: totalSlots > 0 ? completedSlots / totalSlots : 0,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(_gold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHairProgressionSection(List<BeautyLog> logs) {
    final latestLog = logs.isNotEmpty ? logs.first : null;
    final initialLog = logs.isNotEmpty ? logs.last : null;

    double currentLength = latestLog?.hairLengthCm ?? 15.0;
    double initialLength = initialLog?.hairLengthCm ?? 15.0;
    double growthDelta = currentLength - initialLength;

    double strengthScore = latestLog?.hairStrengthScore ?? 7.0;
    String sheddingRate = latestLog?.hairSheddingRate ?? 'moderate';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.content_cut_rounded, color: _gold, size: 20),
            const SizedBox(width: 8),
            Text(
              'Diagnostic Capillaire 👑',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Longueur',
                value: '${currentLength.toStringAsFixed(1)} cm',
                subtitle: growthDelta >= 0 ? '+${growthDelta.toStringAsFixed(1)} cm gagnés' : '${growthDelta.toStringAsFixed(1)} cm',
                subtitleColor: growthDelta >= 0 ? Colors.greenAccent : Colors.orangeAccent,
                icon: Icons.straighten_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Force & Densité',
                value: '${strengthScore.toStringAsFixed(0)}/10',
                subtitle: 'Score de résistance',
                subtitleColor: Colors.white60,
                icon: Icons.fitness_center_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _darkCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Niveau de Chute (Anti-Casse)',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.87),
                ),
              ),
              _buildSheddingBadge(sheddingRate),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkinProgressionSection(List<BeautyLog> logs) {
    final latestLog = logs.isNotEmpty ? logs.first : null;

    double hydrationLevel = latestLog?.skinHydrationLevel ?? 7.0;
    double clarityScore = latestLog?.skinClarityScore ?? 7.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.wb_twilight_rounded, color: _gold, size: 20),
            const SizedBox(width: 8),
            Text(
              'Diagnostic Cutané ✨',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Hydratation Cutanée',
                value: '${hydrationLevel.toStringAsFixed(0)}/10',
                subtitle: 'Barrière hydrique',
                subtitleColor: Colors.cyanAccent,
                icon: Icons.water_drop_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Éclat & Teint',
                value: '${clarityScore.toStringAsFixed(0)}/10',
                subtitle: 'Clarification du grain',
                subtitleColor: _gold,
                icon: Icons.wb_sunny_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required Color subtitleColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _darkCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white60,
                ),
              ),
              Icon(icon, size: 16, color: _rosewood),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheddingBadge(String rate) {
    String label = 'Modérée';
    Color color = Colors.orangeAccent;

    if (rate == 'low' || rate == 'Faible') {
      label = 'Faible (Idéal)';
      color = Colors.greenAccent;
    } else if (rate == 'high' || rate == 'Élevée') {
      label = 'Élevée (Attention)';
      color = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLogsHistoryTimeline(List<BeautyLog> logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Historique du Journal 📖',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${logs.length} bilans',
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (logs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _darkCardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'Aucun bilan beauté enregistré pour l\'instant.',
                style: GoogleFonts.nunito(color: Colors.white60),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final log = logs[index];
              final dateStr = '${log.loggedAt.day}/${log.loggedAt.month}/${log.loggedAt.year}';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _darkCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: _gold),
                            const SizedBox(width: 6),
                            Text(
                              dateStr,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _rosewood.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Bilan #${logs.length - index}',
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _gold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildChipTag('📏 ${log.hairLengthCm} cm'),
                        _buildChipTag('💪 Force: ${log.hairStrengthScore.toStringAsFixed(0)}/10'),
                        _buildChipTag('💧 Hydratation: ${log.skinHydrationLevel.toStringAsFixed(0)}/10'),
                        _buildChipTag('✨ Éclat: ${log.skinClarityScore.toStringAsFixed(0)}/10'),
                      ],
                    ),
                    if (log.checkinNotes != null && log.checkinNotes!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        log.checkinNotes!,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildChipTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 11,
          color: Colors.white.withOpacity(0.87),
        ),
      ),
    );
  }
}
