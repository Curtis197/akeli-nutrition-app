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
import 'tag_and_or_model.dart';
export 'tag_and_or_model.dart';

class TagAndOrWidget extends StatefulWidget {
  const TagAndOrWidget({super.key});

  @override
  State<TagAndOrWidget> createState() => _TagAndOrWidgetState();
}

class _TagAndOrWidgetState extends State<TagAndOrWidget> {
  late TagAndOrModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TagAndOrModel());

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

    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (FFAppState().tagLogic == 'AND')
            Padding(
              padding: EdgeInsets.all(10.0),
              child: InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                  logFirebaseEvent('TAG_AND_OR_COMP_Row_mglo3pge_ON_TAP');
                  logFirebaseEvent('Row_update_app_state');
                  FFAppState().tagLogic = 'OR';
                  safeSetState(() {});
                  logFirebaseEvent('Row_backend_call');
                  _model.requestReceipeTagOR =
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

                  logFirebaseEvent('Row_update_app_state');
                  FFAppState().receipeReserchResponse =
                      (_model.requestReceipeTagOR?.jsonBody ?? '');
                  FFAppState().receipes =
                      SupabaseGroup.updatedRecipeResearchCall
                          .receipes(
                            (_model.requestReceipeTagOR?.jsonBody ?? ''),
                          )!
                          .toList()
                          .cast<dynamic>();
                  FFAppState().filtering =
                      SupabaseGroup.updatedRecipeResearchCall.hasFilters(
                    (_model.requestReceipeTagOR?.jsonBody ?? ''),
                  )!;
                  FFAppState().filter = SupabaseGroup.updatedRecipeResearchCall
                      .filters(
                        (_model.requestReceipeTagOR?.jsonBody ?? ''),
                      )!
                      .toList()
                      .cast<dynamic>();
                  _model.updatePage(() {});

                  safeSetState(() {});
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50.0,
                      height: 30.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).alternate,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(15.0),
                          bottomRight: Radius.circular(0.0),
                          topLeft: Radius.circular(15.0),
                          topRight: Radius.circular(0.0),
                        ),
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).alternate,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            FFLocalizations.of(context).getText(
                              'ymvujyaz' /* ET */,
                            ),
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.poppins(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 50.0,
                      height: 30.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(0.0),
                          bottomRight: Radius.circular(15.0),
                          topLeft: Radius.circular(0.0),
                          topRight: Radius.circular(15.0),
                        ),
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).alternate,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            FFLocalizations.of(context).getText(
                              'n6rzoxn1' /* OU */,
                            ),
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.poppins(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (FFAppState().tagLogic == 'OR')
            Padding(
              padding: EdgeInsets.all(10.0),
              child: InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                  logFirebaseEvent('TAG_AND_OR_COMP_Row_mlq6hgaw_ON_TAP');
                  logFirebaseEvent('Row_update_app_state');
                  FFAppState().tagLogic = 'AND';
                  safeSetState(() {});
                  logFirebaseEvent('Row_backend_call');
                  _model.requestReceipeTagAND =
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

                  logFirebaseEvent('Row_update_app_state');
                  FFAppState().receipeReserchResponse =
                      (_model.requestReceipeTagAND?.jsonBody ?? '');
                  FFAppState().receipes =
                      SupabaseGroup.updatedRecipeResearchCall
                          .receipes(
                            (_model.requestReceipeTagAND?.jsonBody ?? ''),
                          )!
                          .toList()
                          .cast<dynamic>();
                  FFAppState().filtering =
                      SupabaseGroup.updatedRecipeResearchCall.hasFilters(
                    (_model.requestReceipeTagAND?.jsonBody ?? ''),
                  )!;
                  FFAppState().filter = SupabaseGroup.updatedRecipeResearchCall
                      .filters(
                        (_model.requestReceipeTagAND?.jsonBody ?? ''),
                      )!
                      .toList()
                      .cast<dynamic>();
                  _model.updatePage(() {});

                  safeSetState(() {});
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50.0,
                      height: 30.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(15.0),
                          bottomRight: Radius.circular(0.0),
                          topLeft: Radius.circular(15.0),
                          topRight: Radius.circular(0.0),
                        ),
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).alternate,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            FFLocalizations.of(context).getText(
                              '2h7sza7b' /* ET */,
                            ),
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.poppins(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 50.0,
                      height: 30.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).alternate,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(0.0),
                          bottomRight: Radius.circular(15.0),
                          topLeft: Radius.circular(0.0),
                          topRight: Radius.circular(15.0),
                        ),
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).alternate,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            FFLocalizations.of(context).getText(
                              'zorl14ub' /* OU */,
                            ),
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.poppins(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
