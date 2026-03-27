import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'weekly_prorgression_model.dart';
export 'weekly_prorgression_model.dart';

class WeeklyProrgressionWidget extends StatefulWidget {
  const WeeklyProrgressionWidget({
    super.key,
    required this.mealPlan,
  });

  final int? mealPlan;

  @override
  State<WeeklyProrgressionWidget> createState() =>
      _WeeklyProrgressionWidgetState();
}

class _WeeklyProrgressionWidgetState extends State<WeeklyProrgressionWidget>
    with TickerProviderStateMixin {
  late WeeklyProrgressionModel _model;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WeeklyProrgressionModel());

    animationsMap.addAll({
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 90.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
    });
    setupAnimations(
      animationsMap.values.where((anim) =>
          anim.trigger == AnimationTrigger.onActionTrigger ||
          !anim.applyInitialState),
      this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: FutureBuilder<List<WeeklyUserTrackRow>>(
        future: WeeklyUserTrackTable().querySingleRow(
          queryFn: (q) => q.eqOrNull(
            'meal_plan_id',
            widget!.mealPlan,
          ),
        ),
        builder: (context, snapshot) {
          // Customize what your widget looks like when it's loading.
          if (!snapshot.hasData) {
            return Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: SpinKitDoubleBounce(
                  color: FlutterFlowTheme.of(context).tertiary,
                  size: 50.0,
                ),
              ),
            );
          }
          List<WeeklyUserTrackRow>
              annualHouseHoldContainerWeeklyUserTrackRowList = snapshot.data!;

          // Return an empty Container when the item does not exist.
          if (snapshot.data!.isEmpty) {
            return Container();
          }
          final annualHouseHoldContainerWeeklyUserTrackRow =
              annualHouseHoldContainerWeeklyUserTrackRowList.isNotEmpty
                  ? annualHouseHoldContainerWeeklyUserTrackRowList.first
                  : null;

          return Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: 500.0,
            ),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(12.0, 16.0, 12.0, 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FFLocalizations.of(context).getText(
                      '35dzzy9o' /* Calorie Hebdomadaire */,
                    ),
                    style: FlutterFlowTheme.of(context).headlineSmall.override(
                          font: GoogleFonts.outfit(
                            fontWeight: FlutterFlowTheme.of(context)
                                .headlineSmall
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .headlineSmall
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .fontWeight,
                          fontStyle: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .fontStyle,
                        ),
                  ),
                  Text(
                    '${FFLocalizations.of(context).getVariableText(
                      frText: 'Du  ',
                      enText: 'From  ',
                      arText: '',
                    )}${dateTimeFormat(
                      "MMMMEEEEd",
                      annualHouseHoldContainerWeeklyUserTrackRow?.startDate,
                      locale: FFLocalizations.of(context).languageCode,
                    )}${FFLocalizations.of(context).getVariableText(
                      frText: '  au   ',
                      enText: '  to  ',
                      arText: '',
                    )}${dateTimeFormat(
                      "MMMMEEEEd",
                      annualHouseHoldContainerWeeklyUserTrackRow?.endDate,
                      locale: FFLocalizations.of(context).languageCode,
                    )}',
                    style: FlutterFlowTheme.of(context).labelLarge.override(
                          font: GoogleFonts.poppins(
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelLarge
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelLarge
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .labelLarge
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelLarge.fontStyle,
                        ),
                  ),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 12.0),
                    child: LinearPercentIndicator(
                      percent: annualHouseHoldContainerWeeklyUserTrackRow!
                              .consumedCalories!
                              .toDouble() /
                          (annualHouseHoldContainerWeeklyUserTrackRow!
                              .targetCalorie!
                              .toDouble()),
                      width: 310.0,
                      lineHeight: 16.0,
                      animation: true,
                      animateFromLastPercent: true,
                      progressColor: FlutterFlowTheme.of(context).primary,
                      backgroundColor:
                          FlutterFlowTheme.of(context).primaryBackground,
                      barRadius: Radius.circular(16.0),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 4.0, 0.0),
                        child: Text(
                          '${annualHouseHoldContainerWeeklyUserTrackRow?.consumedCalories?.toString()} kcal',
                          style:
                              FlutterFlowTheme.of(context).bodyLarge.override(
                                    font: GoogleFonts.poppins(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyLarge
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyLarge
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyLarge
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyLarge
                                        .fontStyle,
                                  ),
                        ),
                      ),
                      Text(
                        'de  ${annualHouseHoldContainerWeeklyUserTrackRow?.targetCalorie?.toString()}  kcal',
                        style: FlutterFlowTheme.of(context)
                            .titleMedium
                            .override(
                              font: GoogleFonts.poppins(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .titleMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleMedium
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).secondaryText,
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .fontStyle,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation']!);
        },
      ),
    );
  }
}
