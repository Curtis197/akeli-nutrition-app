import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'oredering_selector_model.dart';
export 'oredering_selector_model.dart';

class OrederingSelectorWidget extends StatefulWidget {
  const OrederingSelectorWidget({super.key});

  @override
  State<OrederingSelectorWidget> createState() =>
      _OrederingSelectorWidgetState();
}

class _OrederingSelectorWidgetState extends State<OrederingSelectorWidget> {
  late OrederingSelectorModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OrederingSelectorModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        if (FFAppState().orderBy == '')
          Container(
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primaryBackground,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Align(
                    alignment: AlignmentDirectional(1.0, 0.0),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        logFirebaseEvent(
                            'OREDERING_SELECTOR_Icon_y9yve5er_ON_TAP');
                        logFirebaseEvent('Icon_update_app_state');
                        FFAppState().orderBy = '';
                        FFAppState().orderMenu = false;
                        FFAppState().ordering = true;
                        FFAppState().update(() {});
                        logFirebaseEvent('Icon_backend_call');
                        _model.requestReceipeClear =
                            await SupabaseGroup.updatedRecipeResearchCall.call(
                          bodyJson: functions.buildResearchRequestCopy(
                              FFAppState().name,
                              FFAppState().calMin,
                              FFAppState().calMax,
                              FFAppState().type.toList(),
                              FFAppState().typeLogic,
                              FFAppState().tags.toList(),
                              FFAppState().tagLogic,
                              FFAppState().foodRegion.toList(),
                              FFAppState().dificulty.toList(),
                              FFAppState().cookingTIme,
                              FFAppState().orderBy,
                              FFAppState().orderAscend,
                              FFAppState().sansPorc),
                        );

                        logFirebaseEvent('Icon_update_app_state');
                        FFAppState().receipeReserchResponse =
                            (_model.requestReceipeClear?.jsonBody ?? '');
                        FFAppState().receipes =
                            SupabaseGroup.updatedRecipeResearchCall
                                .receipes(
                                  (_model.requestReceipeClear?.jsonBody ?? ''),
                                )!
                                .toList()
                                .cast<dynamic>();
                        FFAppState().filter =
                            SupabaseGroup.updatedRecipeResearchCall
                                .filters(
                                  (_model.requestReceipeClear?.jsonBody ?? ''),
                                )!
                                .toList()
                                .cast<dynamic>();
                        FFAppState().filtering =
                            SupabaseGroup.updatedRecipeResearchCall.hasFilters(
                          (_model.requestReceipeClear?.jsonBody ?? ''),
                        )!;
                        FFAppState().update(() {});

                        safeSetState(() {});
                      },
                      child: Icon(
                        Icons.close,
                        color: FlutterFlowTheme.of(context).secondaryText,
                        size: 20.0,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          logFirebaseEvent(
                              'OREDERING_SELECTOR_Container_c36shhun_ON');
                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().orderBy = 'like_count';
                          FFAppState().ordering = true;
                          safeSetState(() {});
                          logFirebaseEvent('Container_backend_call');
                          _model.requestReceipeLikes = await SupabaseGroup
                              .updatedRecipeResearchCall
                              .call(
                            bodyJson: functions.buildResearchRequestCopy(
                                FFAppState().name,
                                FFAppState().calMin,
                                FFAppState().calMax,
                                FFAppState().type.toList(),
                                FFAppState().typeLogic,
                                FFAppState().tags.toList(),
                                FFAppState().tagLogic,
                                FFAppState().foodRegion.toList(),
                                FFAppState().dificulty.toList(),
                                FFAppState().cookingTIme,
                                FFAppState().orderBy,
                                FFAppState().orderAscend,
                                FFAppState().sansPorc),
                          );

                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().receipeReserchResponse =
                              (_model.requestReceipeLikes?.jsonBody ?? '');
                          FFAppState().receipes = SupabaseGroup
                              .updatedRecipeResearchCall
                              .receipes(
                                (_model.requestReceipeLikes?.jsonBody ?? ''),
                              )!
                              .toList()
                              .cast<dynamic>();
                          FFAppState().filter = SupabaseGroup
                              .updatedRecipeResearchCall
                              .filters(
                                (_model.requestReceipeLikes?.jsonBody ?? ''),
                              )!
                              .toList()
                              .cast<dynamic>();
                          FFAppState().filtering = SupabaseGroup
                              .updatedRecipeResearchCall
                              .hasFilters(
                            (_model.requestReceipeLikes?.jsonBody ?? ''),
                          )!;
                          FFAppState().update(() {});

                          safeSetState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                FlutterFlowTheme.of(context).primaryBackground,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                10.0, 5.0, 10.0, 5.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'gdb9uvlk' /* Les plus aimées */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          logFirebaseEvent(
                              'OREDERING_SELECTOR_Container_td7urefb_ON');
                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().orderBy = 'comment_count';
                          FFAppState().ordering = true;
                          FFAppState().update(() {});
                          logFirebaseEvent('Container_backend_call');
                          _model.requestReceipeCommment = await SupabaseGroup
                              .updatedRecipeResearchCall
                              .call(
                            bodyJson: functions.buildResearchRequestCopy(
                                FFAppState().name,
                                FFAppState().calMin,
                                FFAppState().calMax,
                                FFAppState().type.toList(),
                                FFAppState().typeLogic,
                                FFAppState().tags.toList(),
                                FFAppState().tagLogic,
                                FFAppState().foodRegion.toList(),
                                FFAppState().dificulty.toList(),
                                FFAppState().cookingTIme,
                                FFAppState().orderBy,
                                FFAppState().orderAscend,
                                FFAppState().sansPorc),
                          );

                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().receipeReserchResponse =
                              (_model.requestReceipeCommment?.jsonBody ?? '');
                          FFAppState().receipes = SupabaseGroup
                              .updatedRecipeResearchCall
                              .receipes(
                                (_model.requestReceipeCommment?.jsonBody ?? ''),
                              )!
                              .toList()
                              .cast<dynamic>();
                          FFAppState().filter = SupabaseGroup
                              .updatedRecipeResearchCall
                              .filters(
                                (_model.requestReceipeCommment?.jsonBody ?? ''),
                              )!
                              .toList()
                              .cast<dynamic>();
                          FFAppState().filtering = SupabaseGroup
                              .updatedRecipeResearchCall
                              .hasFilters(
                            (_model.requestReceipeCommment?.jsonBody ?? ''),
                          )!;
                          FFAppState().ordering = true;
                          FFAppState().update(() {});

                          safeSetState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                FlutterFlowTheme.of(context).primaryBackground,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                10.0, 5.0, 10.0, 5.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    '1b8ad1zo' /* Les plus commentées */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          logFirebaseEvent(
                              'OREDERING_SELECTOR_Container_f6isitx5_ON');
                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().orderBy = 'meal_consumed';
                          FFAppState().ordering = true;
                          FFAppState().update(() {});
                          logFirebaseEvent('Container_backend_call');
                          _model.requestReceipeMeal = await SupabaseGroup
                              .updatedRecipeResearchCall
                              .call(
                            bodyJson: functions.buildResearchRequestCopy(
                                FFAppState().name,
                                FFAppState().calMin,
                                FFAppState().calMax,
                                FFAppState().type.toList(),
                                FFAppState().typeLogic,
                                FFAppState().tags.toList(),
                                FFAppState().tagLogic,
                                FFAppState().foodRegion.toList(),
                                FFAppState().dificulty.toList(),
                                FFAppState().cookingTIme,
                                FFAppState().orderBy,
                                FFAppState().orderAscend,
                                FFAppState().sansPorc),
                          );

                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().receipeReserchResponse =
                              (_model.requestReceipeMeal?.jsonBody ?? '');
                          FFAppState().receipes =
                              SupabaseGroup.updatedRecipeResearchCall
                                  .receipes(
                                    (_model.requestReceipeMeal?.jsonBody ?? ''),
                                  )!
                                  .toList()
                                  .cast<dynamic>();
                          FFAppState().filter =
                              SupabaseGroup.updatedRecipeResearchCall
                                  .filters(
                                    (_model.requestReceipeMeal?.jsonBody ?? ''),
                                  )!
                                  .toList()
                                  .cast<dynamic>();
                          FFAppState().filtering = SupabaseGroup
                              .updatedRecipeResearchCall
                              .hasFilters(
                            (_model.requestReceipeMeal?.jsonBody ?? ''),
                          )!;
                          FFAppState().update(() {});

                          safeSetState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                FlutterFlowTheme.of(context).primaryBackground,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                10.0, 5.0, 10.0, 5.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'c3wdjms8' /* Les plus consomées */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (FFAppState().orderBy == 'like_count')
          Container(
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primaryBackground,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Align(
                    alignment: AlignmentDirectional(1.0, 0.0),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        logFirebaseEvent(
                            'OREDERING_SELECTOR_Icon_8kyehnlu_ON_TAP');
                        logFirebaseEvent('Icon_update_app_state');
                        FFAppState().orderBy = '';
                        FFAppState().ordering = false;
                        FFAppState().update(() {});
                        logFirebaseEvent('Icon_backend_call');
                        _model.requestReceipeLikeClear =
                            await SupabaseGroup.updatedRecipeResearchCall.call(
                          bodyJson: functions.buildResearchRequestCopy(
                              FFAppState().name,
                              FFAppState().calMin,
                              FFAppState().calMax,
                              FFAppState().type.toList(),
                              FFAppState().typeLogic,
                              FFAppState().tags.toList(),
                              FFAppState().tagLogic,
                              FFAppState().foodRegion.toList(),
                              FFAppState().dificulty.toList(),
                              FFAppState().cookingTIme,
                              FFAppState().orderBy,
                              FFAppState().orderAscend,
                              FFAppState().sansPorc),
                        );

                        logFirebaseEvent('Icon_update_app_state');
                        FFAppState().receipeReserchResponse =
                            (_model.requestReceipeLikeClear?.jsonBody ?? '');
                        FFAppState().receipes = SupabaseGroup
                            .updatedRecipeResearchCall
                            .receipes(
                              (_model.requestReceipeLikeClear?.jsonBody ?? ''),
                            )!
                            .toList()
                            .cast<dynamic>();
                        FFAppState().filter = SupabaseGroup
                            .updatedRecipeResearchCall
                            .filters(
                              (_model.requestReceipeLikeClear?.jsonBody ?? ''),
                            )!
                            .toList()
                            .cast<dynamic>();
                        FFAppState().filtering =
                            SupabaseGroup.updatedRecipeResearchCall.hasFilters(
                          (_model.requestReceipeLikeClear?.jsonBody ?? ''),
                        )!;
                        FFAppState().update(() {});

                        safeSetState(() {});
                      },
                      child: Icon(
                        Icons.close,
                        color: FlutterFlowTheme.of(context).secondaryText,
                        size: 20.0,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          logFirebaseEvent(
                              'OREDERING_SELECTOR_Container_b6qlqri4_ON');
                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().orderBy = 'like_count';
                          FFAppState().ordering = true;
                          safeSetState(() {});
                          logFirebaseEvent('Container_backend_call');
                          _model.requestReceipeLikeLikes = await SupabaseGroup
                              .updatedRecipeResearchCall
                              .call(
                            bodyJson: functions.buildResearchRequestCopy(
                                FFAppState().name,
                                FFAppState().calMin,
                                FFAppState().calMax,
                                FFAppState().type.toList(),
                                FFAppState().typeLogic,
                                FFAppState().tags.toList(),
                                FFAppState().tagLogic,
                                FFAppState().foodRegion.toList(),
                                FFAppState().dificulty.toList(),
                                FFAppState().cookingTIme,
                                FFAppState().orderBy,
                                FFAppState().orderAscend,
                                FFAppState().sansPorc),
                          );

                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().receipeReserchResponse =
                              (_model.requestReceipeLikeLikes?.jsonBody ?? '');
                          FFAppState().receipes =
                              SupabaseGroup.updatedRecipeResearchCall
                                  .receipes(
                                    (_model.requestReceipeLikeLikes?.jsonBody ??
                                        ''),
                                  )!
                                  .toList()
                                  .cast<dynamic>();
                          FFAppState().filter =
                              SupabaseGroup.updatedRecipeResearchCall
                                  .filters(
                                    (_model.requestReceipeLikeLikes?.jsonBody ??
                                        ''),
                                  )!
                                  .toList()
                                  .cast<dynamic>();
                          FFAppState().filtering = SupabaseGroup
                              .updatedRecipeResearchCall
                              .hasFilters(
                            (_model.requestReceipeLikeLikes?.jsonBody ?? ''),
                          )!;
                          FFAppState().update(() {});

                          safeSetState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).primary,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                10.0, 5.0, 10.0, 5.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'phmtmqye' /* Les plus aimées */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          logFirebaseEvent(
                              'OREDERING_SELECTOR_Container_kc62xtzz_ON');
                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().orderBy = 'comment_count';
                          FFAppState().ordering = true;
                          safeSetState(() {});
                          logFirebaseEvent('Container_backend_call');
                          _model.requestReceipeLikeCommment =
                              await SupabaseGroup.updatedRecipeResearchCall
                                  .call(
                            bodyJson: functions.buildResearchRequestCopy(
                                FFAppState().name,
                                FFAppState().calMin,
                                FFAppState().calMax,
                                FFAppState().type.toList(),
                                FFAppState().typeLogic,
                                FFAppState().tags.toList(),
                                FFAppState().tagLogic,
                                FFAppState().foodRegion.toList(),
                                FFAppState().dificulty.toList(),
                                FFAppState().cookingTIme,
                                FFAppState().orderBy,
                                FFAppState().orderAscend,
                                FFAppState().sansPorc),
                          );

                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().receipeReserchResponse =
                              (_model.requestReceipeLikeCommment?.jsonBody ??
                                  '');
                          FFAppState().receipes = SupabaseGroup
                              .updatedRecipeResearchCall
                              .receipes(
                                (_model.requestReceipeLikeCommment?.jsonBody ??
                                    ''),
                              )!
                              .toList()
                              .cast<dynamic>();
                          FFAppState().filter = SupabaseGroup
                              .updatedRecipeResearchCall
                              .filters(
                                (_model.requestReceipeLikeCommment?.jsonBody ??
                                    ''),
                              )!
                              .toList()
                              .cast<dynamic>();
                          FFAppState().filtering = SupabaseGroup
                              .updatedRecipeResearchCall
                              .hasFilters(
                            (_model.requestReceipeLikeCommment?.jsonBody ?? ''),
                          )!;
                          FFAppState().update(() {});

                          safeSetState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                FlutterFlowTheme.of(context).primaryBackground,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                10.0, 5.0, 10.0, 5.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'nrx9pbf2' /* Les plus commentées */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          logFirebaseEvent(
                              'OREDERING_SELECTOR_Container_zcq9p4ef_ON');
                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().orderBy = 'meal_consumed';
                          FFAppState().ordering = true;
                          safeSetState(() {});
                          logFirebaseEvent('Container_backend_call');
                          _model.requestReceipeLikeMeal = await SupabaseGroup
                              .updatedRecipeResearchCall
                              .call(
                            bodyJson: functions.buildResearchRequestCopy(
                                FFAppState().name,
                                FFAppState().calMin,
                                FFAppState().calMax,
                                FFAppState().type.toList(),
                                FFAppState().typeLogic,
                                FFAppState().tags.toList(),
                                FFAppState().tagLogic,
                                FFAppState().foodRegion.toList(),
                                FFAppState().dificulty.toList(),
                                FFAppState().cookingTIme,
                                FFAppState().orderBy,
                                FFAppState().orderAscend,
                                FFAppState().sansPorc),
                          );

                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().receipeReserchResponse =
                              (_model.requestReceipeLikeMeal?.jsonBody ?? '');
                          FFAppState().receipes = SupabaseGroup
                              .updatedRecipeResearchCall
                              .receipes(
                                (_model.requestReceipeLikeMeal?.jsonBody ?? ''),
                              )!
                              .toList()
                              .cast<dynamic>();
                          FFAppState().filter = SupabaseGroup
                              .updatedRecipeResearchCall
                              .filters(
                                (_model.requestReceipeLikeMeal?.jsonBody ?? ''),
                              )!
                              .toList()
                              .cast<dynamic>();
                          FFAppState().filtering = SupabaseGroup
                              .updatedRecipeResearchCall
                              .hasFilters(
                            (_model.requestReceipeLikeMeal?.jsonBody ?? ''),
                          )!;
                          FFAppState().update(() {});

                          safeSetState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                FlutterFlowTheme.of(context).primaryBackground,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                10.0, 5.0, 10.0, 5.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    '3hfvnhg1' /* Les plus consomées */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (FFAppState().orderBy == 'comment_count')
          Container(
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primaryBackground,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Align(
                    alignment: AlignmentDirectional(1.0, 0.0),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        logFirebaseEvent(
                            'OREDERING_SELECTOR_Icon_upl43ilq_ON_TAP');
                        logFirebaseEvent('Icon_update_app_state');
                        FFAppState().orderBy = '';
                        FFAppState().ordering = false;
                        safeSetState(() {});
                        logFirebaseEvent('Icon_backend_call');
                        _model.requestReceipeLikeCommentClear =
                            await SupabaseGroup.updatedRecipeResearchCall.call(
                          bodyJson: functions.buildResearchRequestCopy(
                              FFAppState().name,
                              FFAppState().calMin,
                              FFAppState().calMax,
                              FFAppState().type.toList(),
                              FFAppState().typeLogic,
                              FFAppState().tags.toList(),
                              FFAppState().tagLogic,
                              FFAppState().foodRegion.toList(),
                              FFAppState().dificulty.toList(),
                              FFAppState().cookingTIme,
                              FFAppState().orderBy,
                              FFAppState().orderAscend,
                              FFAppState().sansPorc),
                        );

                        logFirebaseEvent('Icon_update_app_state');
                        FFAppState().receipeReserchResponse =
                            (_model.requestReceipeLikeCommentClear?.jsonBody ??
                                '');
                        FFAppState().receipes =
                            SupabaseGroup.updatedRecipeResearchCall
                                .receipes(
                                  (_model.requestReceipeLikeCommentClear
                                          ?.jsonBody ??
                                      ''),
                                )!
                                .toList()
                                .cast<dynamic>();
                        FFAppState().filter =
                            SupabaseGroup.updatedRecipeResearchCall
                                .filters(
                                  (_model.requestReceipeLikeCommentClear
                                          ?.jsonBody ??
                                      ''),
                                )!
                                .toList()
                                .cast<dynamic>();
                        FFAppState().filtering =
                            SupabaseGroup.updatedRecipeResearchCall.hasFilters(
                          (_model.requestReceipeLikeCommentClear?.jsonBody ??
                              ''),
                        )!;
                        FFAppState().update(() {});

                        safeSetState(() {});
                      },
                      child: Icon(
                        Icons.close,
                        color: FlutterFlowTheme.of(context).secondaryText,
                        size: 20.0,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          logFirebaseEvent(
                              'OREDERING_SELECTOR_Container_gyd7cfjp_ON');
                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().orderBy = 'like_count';
                          FFAppState().ordering = true;
                          safeSetState(() {});
                          logFirebaseEvent('Container_backend_call');
                          _model.requestReceipeCommentLikes =
                              await SupabaseGroup.updatedRecipeResearchCall
                                  .call(
                            bodyJson: functions.buildResearchRequestCopy(
                                FFAppState().name,
                                FFAppState().calMin,
                                FFAppState().calMax,
                                FFAppState().type.toList(),
                                FFAppState().typeLogic,
                                FFAppState().tags.toList(),
                                FFAppState().tagLogic,
                                FFAppState().foodRegion.toList(),
                                FFAppState().dificulty.toList(),
                                FFAppState().cookingTIme,
                                FFAppState().orderBy,
                                FFAppState().orderAscend,
                                FFAppState().sansPorc),
                          );

                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().receipeReserchResponse =
                              (_model.requestReceipeCommentLikes?.jsonBody ??
                                  '');
                          FFAppState().receipes = SupabaseGroup
                              .updatedRecipeResearchCall
                              .receipes(
                                (_model.requestReceipeCommentLikes?.jsonBody ??
                                    ''),
                              )!
                              .toList()
                              .cast<dynamic>();
                          FFAppState().filter = SupabaseGroup
                              .updatedRecipeResearchCall
                              .filters(
                                (_model.requestReceipeCommentLikes?.jsonBody ??
                                    ''),
                              )!
                              .toList()
                              .cast<dynamic>();
                          FFAppState().filtering = SupabaseGroup
                              .updatedRecipeResearchCall
                              .hasFilters(
                            (_model.requestReceipeCommentLikes?.jsonBody ?? ''),
                          )!;
                          FFAppState().update(() {});

                          safeSetState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                FlutterFlowTheme.of(context).primaryBackground,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                10.0, 5.0, 10.0, 5.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'u7ihq4ji' /* Les plus aimées */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          logFirebaseEvent(
                              'OREDERING_SELECTOR_Container_f0dpv2sw_ON');
                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().orderBy = 'comment_count';
                          FFAppState().ordering = true;
                          safeSetState(() {});
                          logFirebaseEvent('Container_backend_call');
                          _model.requestReceipeCommentCommment =
                              await SupabaseGroup.updatedRecipeResearchCall
                                  .call(
                            bodyJson: functions.buildResearchRequestCopy(
                                FFAppState().name,
                                FFAppState().calMin,
                                FFAppState().calMax,
                                FFAppState().type.toList(),
                                FFAppState().typeLogic,
                                FFAppState().tags.toList(),
                                FFAppState().tagLogic,
                                FFAppState().foodRegion.toList(),
                                FFAppState().dificulty.toList(),
                                FFAppState().cookingTIme,
                                FFAppState().orderBy,
                                FFAppState().orderAscend,
                                FFAppState().sansPorc),
                          );

                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().receipeReserchResponse =
                              (_model.requestReceipeCommentCommment?.jsonBody ??
                                  '');
                          FFAppState().receipes =
                              SupabaseGroup.updatedRecipeResearchCall
                                  .receipes(
                                    (_model.requestReceipeCommentCommment
                                            ?.jsonBody ??
                                        ''),
                                  )!
                                  .toList()
                                  .cast<dynamic>();
                          FFAppState().filter =
                              SupabaseGroup.updatedRecipeResearchCall
                                  .filters(
                                    (_model.requestReceipeCommentCommment
                                            ?.jsonBody ??
                                        ''),
                                  )!
                                  .toList()
                                  .cast<dynamic>();
                          FFAppState().filtering = SupabaseGroup
                              .updatedRecipeResearchCall
                              .hasFilters(
                            (_model.requestReceipeCommentCommment?.jsonBody ??
                                ''),
                          )!;
                          FFAppState().update(() {});

                          safeSetState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).primary,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                10.0, 5.0, 10.0, 5.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'uq73ac7d' /* Les plus commentées */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          logFirebaseEvent(
                              'OREDERING_SELECTOR_Container_xyps48j3_ON');
                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().orderBy = 'meal_consumed';
                          FFAppState().ordering = true;
                          safeSetState(() {});
                          logFirebaseEvent('Container_backend_call');
                          _model.requestReceipeCommentMeal = await SupabaseGroup
                              .updatedRecipeResearchCall
                              .call(
                            bodyJson: functions.buildResearchRequestCopy(
                                FFAppState().name,
                                FFAppState().calMin,
                                FFAppState().calMax,
                                FFAppState().type.toList(),
                                FFAppState().typeLogic,
                                FFAppState().tags.toList(),
                                FFAppState().tagLogic,
                                FFAppState().foodRegion.toList(),
                                FFAppState().dificulty.toList(),
                                FFAppState().cookingTIme,
                                FFAppState().orderBy,
                                FFAppState().orderAscend,
                                FFAppState().sansPorc),
                          );

                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().receipeReserchResponse =
                              (_model.requestReceipeCommentMeal?.jsonBody ??
                                  '');
                          FFAppState().receipes = SupabaseGroup
                              .updatedRecipeResearchCall
                              .receipes(
                                (_model.requestReceipeCommentMeal?.jsonBody ??
                                    ''),
                              )!
                              .toList()
                              .cast<dynamic>();
                          FFAppState().filter = SupabaseGroup
                              .updatedRecipeResearchCall
                              .filters(
                                (_model.requestReceipeCommentMeal?.jsonBody ??
                                    ''),
                              )!
                              .toList()
                              .cast<dynamic>();
                          FFAppState().filtering = SupabaseGroup
                              .updatedRecipeResearchCall
                              .hasFilters(
                            (_model.requestReceipeCommentMeal?.jsonBody ?? ''),
                          )!;
                          FFAppState().update(() {});

                          safeSetState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                FlutterFlowTheme.of(context).primaryBackground,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                10.0, 5.0, 10.0, 5.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'bwqm26i2' /* Les plus consomées */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (FFAppState().orderBy == 'meal_consumed')
          Container(
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primaryBackground,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Align(
                    alignment: AlignmentDirectional(1.0, 0.0),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        logFirebaseEvent(
                            'OREDERING_SELECTOR_Icon_x00lsagz_ON_TAP');
                        logFirebaseEvent('Icon_update_app_state');
                        FFAppState().orderBy = '';
                        FFAppState().ordering = false;
                        safeSetState(() {});
                        logFirebaseEvent('Icon_backend_call');
                        _model.requestReceipeLikeMealClear =
                            await SupabaseGroup.updatedRecipeResearchCall.call(
                          bodyJson: functions.buildResearchRequestCopy(
                              FFAppState().name,
                              FFAppState().calMin,
                              FFAppState().calMax,
                              FFAppState().type.toList(),
                              FFAppState().typeLogic,
                              FFAppState().tags.toList(),
                              FFAppState().tagLogic,
                              FFAppState().foodRegion.toList(),
                              FFAppState().dificulty.toList(),
                              FFAppState().cookingTIme,
                              FFAppState().orderBy,
                              FFAppState().orderAscend,
                              FFAppState().sansPorc),
                        );

                        logFirebaseEvent('Icon_update_app_state');
                        FFAppState().receipeReserchResponse =
                            (_model.requestReceipeLikeMealClear?.jsonBody ??
                                '');
                        FFAppState().receipes = SupabaseGroup
                            .updatedRecipeResearchCall
                            .receipes(
                              (_model.requestReceipeLikeMealClear?.jsonBody ??
                                  ''),
                            )!
                            .toList()
                            .cast<dynamic>();
                        FFAppState().filter = SupabaseGroup
                            .updatedRecipeResearchCall
                            .filters(
                              (_model.requestReceipeLikeMealClear?.jsonBody ??
                                  ''),
                            )!
                            .toList()
                            .cast<dynamic>();
                        FFAppState().filtering =
                            SupabaseGroup.updatedRecipeResearchCall.hasFilters(
                          (_model.requestReceipeLikeMealClear?.jsonBody ?? ''),
                        )!;
                        FFAppState().update(() {});

                        safeSetState(() {});
                      },
                      child: Icon(
                        Icons.close,
                        color: FlutterFlowTheme.of(context).secondaryText,
                        size: 20.0,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          logFirebaseEvent(
                              'OREDERING_SELECTOR_Container_aowvmpp1_ON');
                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().orderBy = 'like_count';
                          FFAppState().ordering = true;
                          safeSetState(() {});
                          logFirebaseEvent('Container_backend_call');
                          _model.requestReceipeMealLikes = await SupabaseGroup
                              .updatedRecipeResearchCall
                              .call(
                            bodyJson: functions.buildResearchRequestCopy(
                                FFAppState().name,
                                FFAppState().calMin,
                                FFAppState().calMax,
                                FFAppState().type.toList(),
                                FFAppState().typeLogic,
                                FFAppState().tags.toList(),
                                FFAppState().tagLogic,
                                FFAppState().foodRegion.toList(),
                                FFAppState().dificulty.toList(),
                                FFAppState().cookingTIme,
                                FFAppState().orderBy,
                                FFAppState().orderAscend,
                                FFAppState().sansPorc),
                          );

                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().receipeReserchResponse =
                              (_model.requestReceipeMealLikes?.jsonBody ?? '');
                          FFAppState().receipes =
                              SupabaseGroup.updatedRecipeResearchCall
                                  .receipes(
                                    (_model.requestReceipeMealLikes?.jsonBody ??
                                        ''),
                                  )!
                                  .toList()
                                  .cast<dynamic>();
                          FFAppState().filter =
                              SupabaseGroup.updatedRecipeResearchCall
                                  .filters(
                                    (_model.requestReceipeMealLikes?.jsonBody ??
                                        ''),
                                  )!
                                  .toList()
                                  .cast<dynamic>();
                          FFAppState().filtering = SupabaseGroup
                              .updatedRecipeResearchCall
                              .hasFilters(
                            (_model.requestReceipeMealLikes?.jsonBody ?? ''),
                          )!;
                          FFAppState().update(() {});

                          safeSetState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                FlutterFlowTheme.of(context).primaryBackground,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                10.0, 5.0, 10.0, 5.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'l4lvetgn' /* Les plus aimées */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          logFirebaseEvent(
                              'OREDERING_SELECTOR_Container_50saaeia_ON');
                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().orderBy = 'comment_count';
                          FFAppState().ordering = true;
                          safeSetState(() {});
                          logFirebaseEvent('Container_backend_call');
                          _model.requestReceipeMealCommment =
                              await SupabaseGroup.updatedRecipeResearchCall
                                  .call(
                            bodyJson: functions.buildResearchRequestCopy(
                                FFAppState().name,
                                FFAppState().calMin,
                                FFAppState().calMax,
                                FFAppState().type.toList(),
                                FFAppState().typeLogic,
                                FFAppState().tags.toList(),
                                FFAppState().tagLogic,
                                FFAppState().foodRegion.toList(),
                                FFAppState().dificulty.toList(),
                                FFAppState().cookingTIme,
                                FFAppState().orderBy,
                                FFAppState().orderAscend,
                                FFAppState().sansPorc),
                          );

                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().receipeReserchResponse =
                              (_model.requestReceipeMealCommment?.jsonBody ??
                                  '');
                          FFAppState().receipes = SupabaseGroup
                              .updatedRecipeResearchCall
                              .receipes(
                                (_model.requestReceipeMealCommment?.jsonBody ??
                                    ''),
                              )!
                              .toList()
                              .cast<dynamic>();
                          FFAppState().filter = SupabaseGroup
                              .updatedRecipeResearchCall
                              .filters(
                                (_model.requestReceipeMealCommment?.jsonBody ??
                                    ''),
                              )!
                              .toList()
                              .cast<dynamic>();
                          FFAppState().filtering = SupabaseGroup
                              .updatedRecipeResearchCall
                              .hasFilters(
                            (_model.requestReceipeMealCommment?.jsonBody ?? ''),
                          )!;
                          FFAppState().update(() {});

                          safeSetState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                FlutterFlowTheme.of(context).primaryBackground,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                10.0, 5.0, 10.0, 5.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'h9upxskk' /* Les plus commentées */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          logFirebaseEvent(
                              'OREDERING_SELECTOR_Container_s76sokcv_ON');
                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().orderBy = 'meal_consumed';
                          FFAppState().ordering = true;
                          safeSetState(() {});
                          logFirebaseEvent('Container_backend_call');
                          _model.requestReceipeMealMeal = await SupabaseGroup
                              .updatedRecipeResearchCall
                              .call(
                            bodyJson: functions.buildResearchRequestCopy(
                                FFAppState().name,
                                FFAppState().calMin,
                                FFAppState().calMax,
                                FFAppState().type.toList(),
                                FFAppState().typeLogic,
                                FFAppState().tags.toList(),
                                FFAppState().tagLogic,
                                FFAppState().foodRegion.toList(),
                                FFAppState().dificulty.toList(),
                                FFAppState().cookingTIme,
                                FFAppState().orderBy,
                                FFAppState().orderAscend,
                                FFAppState().sansPorc),
                          );

                          logFirebaseEvent('Container_update_app_state');
                          FFAppState().receipeReserchResponse =
                              (_model.requestReceipeMealMeal?.jsonBody ?? '');
                          FFAppState().receipes = SupabaseGroup
                              .updatedRecipeResearchCall
                              .receipes(
                                (_model.requestReceipeMealMeal?.jsonBody ?? ''),
                              )!
                              .toList()
                              .cast<dynamic>();
                          FFAppState().filter = SupabaseGroup
                              .updatedRecipeResearchCall
                              .filters(
                                (_model.requestReceipeMealMeal?.jsonBody ?? ''),
                              )!
                              .toList()
                              .cast<dynamic>();
                          FFAppState().filtering = SupabaseGroup
                              .updatedRecipeResearchCall
                              .hasFilters(
                            (_model.requestReceipeMealMeal?.jsonBody ?? ''),
                          )!;
                          FFAppState().update(() {});

                          safeSetState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).primary,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                10.0, 5.0, 10.0, 5.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'oif3bq15' /* Les plus consomées */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
