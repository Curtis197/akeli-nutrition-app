import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'unpaid_meal_model.dart';
export 'unpaid_meal_model.dart';

class UnpaidMealWidget extends StatefulWidget {
  const UnpaidMealWidget({
    super.key,
    required this.mealRow,
  });

  final MealRow? mealRow;

  @override
  State<UnpaidMealWidget> createState() => _UnpaidMealWidgetState();
}

class _UnpaidMealWidgetState extends State<UnpaidMealWidget>
    with TickerProviderStateMixin {
  late UnpaidMealModel _model;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => UnpaidMealModel());

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
            begin: Offset(0.0, 50.0),
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
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 8.0),
          child: InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () async {
              logFirebaseEvent('UNPAID_MEAL_Container_cr159s65_ON_TAP');
              logFirebaseEvent('Container_navigate_to');

              context.pushNamed(
                MealDetailWidget.routeName,
                queryParameters: {
                  'mealID': serializeParam(
                    widget!.mealRow?.id,
                    ParamType.int,
                  ),
                }.withoutNulls,
              );
            },
            child: Container(
              width: 275.0,
              height: 275.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 2.0,
                    color: Color(0x520E151B),
                    offset: Offset(
                      0.0,
                      1.0,
                    ),
                  )
                ],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Stack(
                alignment: AlignmentDirectional(0.0, -1.0),
                children: [
                  Align(
                    alignment: AlignmentDirectional(0.0, 1.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                10.0, 10.0, 10.0, 0.0),
                            child: FutureBuilder<List<ReceipeImageRow>>(
                              future: ReceipeImageTable().querySingleRow(
                                queryFn: (q) => q
                                    .eqOrNull(
                                      'receipe_id',
                                      widget!.mealRow?.receipeId != null
                                          ? widget!.mealRow?.receipeId
                                          : 0,
                                    )
                                    .eqOrNull(
                                      'type',
                                      'main',
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
                                        color: FlutterFlowTheme.of(context)
                                            .tertiary,
                                        size: 50.0,
                                      ),
                                    ),
                                  );
                                }
                                List<ReceipeImageRow> imageReceipeImageRowList =
                                    snapshot.data!;

                                // Return an empty Container when the item does not exist.
                                if (snapshot.data!.isEmpty) {
                                  return Container();
                                }
                                final imageReceipeImageRow =
                                    imageReceipeImageRowList.isNotEmpty
                                        ? imageReceipeImageRowList.first
                                        : null;

                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    () {
                                      if ((widget!.mealRow?.personal == true) &&
                                          (widget!.mealRow?.imageUrl != null &&
                                              widget!.mealRow?.imageUrl !=
                                                  '')) {
                                        return widget!.mealRow!.imageUrl!;
                                      } else if ((widget!.mealRow?.personal ==
                                              true) &&
                                          (widget!.mealRow?.personal == null)) {
                                        return 'https://jfbfymiyqlyciapfloug.supabase.co/storage/v1/object/public/images/group_photo/pexels-picha-6210449%20(1).jpg';
                                      } else if (imageReceipeImageRow?.id ==
                                              null ||
                                          imageReceipeImageRow?.id == '') {
                                        return 'https://jfbfymiyqlyciapfloug.supabase.co/storage/v1/object/public/images/group_photo/pexels-picha-6210449%20(1).jpg';
                                      } else {
                                        return imageReceipeImageRow!.url!;
                                      }
                                    }(),
                                    width: double.infinity,
                                    height: 170.0,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  constraints: BoxConstraints(
                                    maxHeight: 32.0,
                                  ),
                                  decoration: BoxDecoration(),
                                  child: Visibility(
                                    visible: widget!.mealRow?.generated ?? true,
                                    child: Text(
                                      valueOrDefault<String>(
                                        widget!.mealRow?.name,
                                        'meal name',
                                      ),
                                      maxLines: 1,
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            font: GoogleFonts.poppins(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                            color: () {
                                              if (widget!.mealRow?.mealType ==
                                                  'breakfast') {
                                                return FlutterFlowTheme.of(
                                                        context)
                                                    .secondary;
                                              } else if (widget!
                                                      .mealRow?.mealType ==
                                                  'lunch') {
                                                return FlutterFlowTheme.of(
                                                        context)
                                                    .tertiary;
                                              } else if (widget!
                                                      .mealRow?.mealType ==
                                                  'snack') {
                                                return FlutterFlowTheme.of(
                                                        context)
                                                    .accent1;
                                              } else {
                                                return FlutterFlowTheme.of(
                                                        context)
                                                    .primary;
                                              }
                                            }(),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                ),
                                Text(
                                  '${widget!.mealRow?.adjustedCalories?.toString()} kcal',
                                  style: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                        ),
                                        color: () {
                                          if (widget!.mealRow?.mealType ==
                                              'breakfast') {
                                            return FlutterFlowTheme.of(context)
                                                .secondary;
                                          } else if (widget!
                                                  .mealRow?.mealType ==
                                              'lunch') {
                                            return FlutterFlowTheme.of(context)
                                                .tertiary;
                                          } else if (widget!
                                                  .mealRow?.mealType ==
                                              'snack') {
                                            return FlutterFlowTheme.of(context)
                                                .accent1;
                                          } else {
                                            return FlutterFlowTheme.of(context)
                                                .primary;
                                          }
                                        }(),
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    if (widget!.mealRow?.mealType ==
                                        'breakfast')
                                      Icon(
                                        Icons.wb_sunny_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .secondary,
                                        size: 24.0,
                                      ),
                                    if (widget!.mealRow?.mealType == 'snack')
                                      Icon(
                                        Icons.cookie_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .accent1,
                                        size: 24.0,
                                      ),
                                    if (widget!.mealRow?.mealType == 'lunch')
                                      Icon(
                                        Icons.lunch_dining_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .tertiary,
                                        size: 24.0,
                                      ),
                                    if (widget!.mealRow?.mealType == 'dinner')
                                      Icon(
                                        Icons.dinner_dining_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        size: 24.0,
                                      ),
                                    Text(
                                      () {
                                        if (widget!.mealRow?.mealType ==
                                            'breakfast') {
                                          return 'Petit-Déjenuer';
                                        } else if (widget!.mealRow?.mealType ==
                                            'lunch') {
                                          return 'Déjeuner';
                                        } else if (widget!.mealRow?.mealType ==
                                            'snack') {
                                          return 'Collation';
                                        } else {
                                          return 'Dîner';
                                        }
                                      }(),
                                      style: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .override(
                                            font: GoogleFonts.poppins(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .fontStyle,
                                            ),
                                            color: () {
                                              if (widget!.mealRow?.mealType ==
                                                  'breakfast') {
                                                return FlutterFlowTheme.of(
                                                        context)
                                                    .secondary;
                                              } else if (widget!
                                                      .mealRow?.mealType ==
                                                  'lunch') {
                                                return FlutterFlowTheme.of(
                                                        context)
                                                    .tertiary;
                                              } else if (widget!
                                                      .mealRow?.mealType ==
                                                  'snack') {
                                                return FlutterFlowTheme.of(
                                                        context)
                                                    .accent1;
                                              } else {
                                                return FlutterFlowTheme.of(
                                                        context)
                                                    .primary;
                                              }
                                            }(),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      if (widget!.mealRow!.mealDate! <= getCurrentTimestamp)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 10.0, 10.0, 0.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if ((widget!.mealRow?.consumed == true) &&
                                    (widget!.mealRow?.id != null))
                                  InkWell(
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () async {
                                      logFirebaseEvent(
                                          'UNPAID_MEAL_COMP_Icon_c6vfavfa_ON_TAP');
                                      logFirebaseEvent('Icon_backend_call');
                                      await MealTable().update(
                                        data: {
                                          'consumed': false,
                                        },
                                        matchingRows: (rows) => rows.eqOrNull(
                                          'id',
                                          widget!.mealRow?.id,
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      Icons.check_box,
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      size: 24.0,
                                    ),
                                  ),
                                if ((widget!.mealRow?.consumed == false) &&
                                    (widget!.mealRow?.id != null))
                                  InkWell(
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () async {
                                      logFirebaseEvent(
                                          'UNPAID_MEAL_COMP_Icon_bugalms8_ON_TAP');
                                      logFirebaseEvent('Icon_backend_call');
                                      await MealTable().update(
                                        data: {
                                          'consumed': true,
                                        },
                                        matchingRows: (rows) => rows.eqOrNull(
                                          'id',
                                          widget!.mealRow?.id,
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      Icons.check_box_outline_blank,
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      size: 24.0,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation']!),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 8.0),
          child: InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () async {
              logFirebaseEvent('UNPAID_MEAL_Container_48g88sas_ON_TAP');
              logFirebaseEvent('Container_update_app_state');
              FFAppState().mealID = widget!.mealRow!.id;
              safeSetState(() {});
              logFirebaseEvent('Container_navigate_to');

              context.pushNamed(RecipeResearchingListWidget.routeName);
            },
            child: Material(
              color: Colors.transparent,
              elevation: 3.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Container(
                width: 275.0,
                height: 275.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primaryBackground,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: FlutterFlowTheme.of(context).primary,
                        size: 100.0,
                      ),
                      Text(
                        () {
                          if (widget!.mealRow?.mealType == 'breakfast') {
                            return 'Petit-Déjenuer';
                          } else if (widget!.mealRow?.mealType == 'lunch') {
                            return 'Déjeuner';
                          } else if (widget!.mealRow?.mealType == 'snack') {
                            return 'Collation';
                          } else {
                            return 'Dîner';
                          }
                        }(),
                        style: FlutterFlowTheme.of(context).titleSmall.override(
                              font: GoogleFonts.poppins(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).secondaryText,
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .fontStyle,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
