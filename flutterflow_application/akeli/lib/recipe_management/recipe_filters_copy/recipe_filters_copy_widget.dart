import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_checkbox_group.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/recipe_management/type_and_or/type_and_or_widget.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'recipe_filters_copy_model.dart';
export 'recipe_filters_copy_model.dart';

/// recipe research
class RecipeFiltersCopyWidget extends StatefulWidget {
  const RecipeFiltersCopyWidget({super.key});

  @override
  State<RecipeFiltersCopyWidget> createState() =>
      _RecipeFiltersCopyWidgetState();
}

class _RecipeFiltersCopyWidgetState extends State<RecipeFiltersCopyWidget> {
  late RecipeFiltersCopyModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RecipeFiltersCopyModel());

    _model.calMinTextController ??= TextEditingController();
    _model.calMinFocusNode ??= FocusNode();
    _model.calMinFocusNode!.addListener(
      () async {
        logFirebaseEvent('RECIPE_FILTERS_COPY_calMin_ON_FOCUS_CHAN');
        logFirebaseEvent('calMin_update_app_state');
        FFAppState().calMin = int.parse(_model.calMinTextController.text);
        safeSetState(() {});
      },
    );
    _model.calMaxTextController ??= TextEditingController();
    _model.calMaxFocusNode ??= FocusNode();

    _model.cookingTimeTextController1 ??= TextEditingController();
    _model.cookingTimeFocusNode1 ??= FocusNode();

    _model.cookingTimeTextController2 ??= TextEditingController();
    _model.cookingTimeFocusNode2 ??= FocusNode();

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

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(0.0),
                bottomRight: Radius.circular(0.0),
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(10.0, 10.0, 10.0, 40.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 50.0,
                      height: 5.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).alternate,
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    Text(
                      FFLocalizations.of(context).getText(
                        'cfsr2iy0' /* Calorie */,
                      ),
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
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 150.0,
                          child: TextFormField(
                            controller: _model.calMinTextController,
                            focusNode: _model.calMinFocusNode,
                            autofocus: false,
                            obscureText: false,
                            decoration: InputDecoration(
                              isDense: true,
                              labelStyle: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .override(
                                    font: GoogleFonts.poppins(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                              hintText: FFLocalizations.of(context).getText(
                                '65x6pxwa' /* calorie min. */,
                              ),
                              hintStyle: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .override(
                                    font: GoogleFonts.poppins(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0x00000000),
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0x00000000),
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).error,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).error,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              filled: true,
                              fillColor: FlutterFlowTheme.of(context)
                                  .primaryBackground,
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
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                            cursorColor:
                                FlutterFlowTheme.of(context).primaryText,
                            enableInteractiveSelection: true,
                            validator: _model.calMinTextControllerValidator
                                .asValidator(context),
                          ),
                        ),
                        Flexible(
                          child: Container(
                            width: 150.0,
                            child: TextFormField(
                              controller: _model.calMaxTextController,
                              focusNode: _model.calMaxFocusNode,
                              onChanged: (_) => EasyDebounce.debounce(
                                '_model.calMaxTextController',
                                Duration(milliseconds: 2000),
                                () async {
                                  logFirebaseEvent(
                                      'RECIPE_FILTERS_COPY_calMax_ON_TEXTFIELD_');
                                  logFirebaseEvent('calMax_update_app_state');
                                  FFAppState().calMax = int.parse(
                                      _model.calMaxTextController.text);
                                  safeSetState(() {});
                                },
                              ),
                              autofocus: false,
                              obscureText: false,
                              decoration: InputDecoration(
                                isDense: true,
                                labelStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.poppins(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                hintText: FFLocalizations.of(context).getText(
                                  '0shsh5kp' /* calorie max. */,
                                ),
                                hintStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.poppins(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x00000000),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x00000000),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                filled: true,
                                fillColor: FlutterFlowTheme.of(context)
                                    .primaryBackground,
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
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                              cursorColor:
                                  FlutterFlowTheme.of(context).primaryText,
                              enableInteractiveSelection: true,
                              validator: _model.calMaxTextControllerValidator
                                  .asValidator(context),
                            ),
                          ),
                        ),
                      ].divide(SizedBox(width: 20.0)),
                    ),
                    FlutterFlowCheckboxGroup(
                      options: [
                        FFLocalizations.of(context).getText(
                          'o0xh9qto' /* Sans Porc */,
                        )
                      ],
                      onChanged: (val) async {
                        safeSetState(() => _model.sansPorcValues = val);
                        logFirebaseEvent(
                            'RECIPE_FILTERS_COPY_sansPorc_ON_FORM_WID');
                        logFirebaseEvent('sansPorc_update_app_state');
                        FFAppState().sansPorc =
                            !(FFAppState().sansPorc ?? true);
                        safeSetState(() {});
                      },
                      controller: _model.sansPorcValueController ??=
                          FormFieldController<List<String>>(
                        [],
                      ),
                      activeColor: FlutterFlowTheme.of(context).primary,
                      checkColor: FlutterFlowTheme.of(context).info,
                      checkboxBorderColor:
                          FlutterFlowTheme.of(context).secondaryText,
                      textStyle:
                          FlutterFlowTheme.of(context).bodyMedium.override(
                                font: GoogleFonts.poppins(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                      checkboxBorderRadius: BorderRadius.circular(4.0),
                      initialized: _model.sansPorcValues != null,
                    ),
                    Divider(
                      thickness: 2.0,
                      color: FlutterFlowTheme.of(context).alternate,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                              FFLocalizations.of(context).getText(
                                '5lj3nj8w' /* Type de Repas */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    font: GoogleFonts.poppins(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                            ),
                            InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                logFirebaseEvent(
                                    'RECIPE_FILTERS_COPY_Container_1tcxbgqj_O');
                                logFirebaseEvent('TypeAndOr_update_app_state');
                                FFAppState().tagLogic =
                                    FFAppState().typeLogic == 'AND'
                                        ? 'OR'
                                        : 'AND';
                                safeSetState(() {});
                              },
                              child: wrapWithModel(
                                model: _model.typeAndOrModel,
                                updateCallback: () => safeSetState(() {}),
                                child: TypeAndOrWidget(),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(5.0),
                              child: Container(
                                width: 150.0,
                                decoration: BoxDecoration(),
                                child: FlutterFlowCheckboxGroup(
                                  options: [
                                    FFLocalizations.of(context).getText(
                                      'wrdbt1zs' /* Petit-Déjeuner */,
                                    ),
                                    FFLocalizations.of(context).getText(
                                      'rrukj81q' /* Déjeuner */,
                                    ),
                                    FFLocalizations.of(context).getText(
                                      'grbybyer' /* Dîner */,
                                    ),
                                    FFLocalizations.of(context).getText(
                                      'e5ae1dzl' /* Collation */,
                                    )
                                  ],
                                  onChanged: (val) async {
                                    safeSetState(() => _model.typeValues = val);
                                    logFirebaseEvent(
                                        'RECIPE_FILTERS_COPY_type_ON_FORM_WIDGET_');
                                    logFirebaseEvent('type_update_app_state');
                                    FFAppState().type = _model.typeValues!
                                        .toList()
                                        .cast<String>();
                                    safeSetState(() {});
                                    logFirebaseEvent('type_update_app_state');
                                    FFAppState().typeJson =
                                        functions.listToJson(
                                            FFAppState().type.toList(),
                                            'type')!;
                                    safeSetState(() {});
                                  },
                                  controller: _model.typeValueController ??=
                                      FormFieldController<List<String>>(
                                    [],
                                  ),
                                  activeColor:
                                      FlutterFlowTheme.of(context).primary,
                                  checkColor: FlutterFlowTheme.of(context).info,
                                  checkboxBorderColor:
                                      FlutterFlowTheme.of(context)
                                          .secondaryText,
                                  textStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                  checkboxBorderRadius:
                                      BorderRadius.circular(4.0),
                                  initialized: _model.typeValues != null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Divider(
                      thickness: 2.0,
                      color: FlutterFlowTheme.of(context).alternate,
                    ),
                    Text(
                      FFLocalizations.of(context).getText(
                        '7qf5wnkq' /* Difficulté */,
                      ),
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
                    Container(
                      width: 150.0,
                      decoration: BoxDecoration(),
                      child: FlutterFlowCheckboxGroup(
                        options: [
                          FFLocalizations.of(context).getText(
                            'b6emlt3v' /* Facile */,
                          ),
                          FFLocalizations.of(context).getText(
                            'czc03edg' /* Modérée */,
                          ),
                          FFLocalizations.of(context).getText(
                            '1b7gjt9f' /* Difficile */,
                          )
                        ],
                        onChanged: (val) async {
                          safeSetState(() => _model.difficultyValues = val);
                          logFirebaseEvent(
                              'RECIPE_FILTERS_COPY_difficulty_ON_FORM_W');
                          logFirebaseEvent('difficulty_update_app_state');
                          FFAppState().dificulty =
                              _model.difficultyValues!.toList().cast<String>();
                          safeSetState(() {});
                        },
                        controller: _model.difficultyValueController ??=
                            FormFieldController<List<String>>(
                          [],
                        ),
                        activeColor: FlutterFlowTheme.of(context).primary,
                        checkColor: FlutterFlowTheme.of(context).info,
                        checkboxBorderColor:
                            FlutterFlowTheme.of(context).secondaryText,
                        textStyle:
                            FlutterFlowTheme.of(context).bodyMedium.override(
                                  font: GoogleFonts.poppins(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                        checkboxBorderRadius: BorderRadius.circular(4.0),
                        initialized: _model.difficultyValues != null,
                      ),
                    ),
                    Divider(
                      thickness: 2.0,
                      color: FlutterFlowTheme.of(context).alternate,
                    ),
                    Text(
                      FFLocalizations.of(context).getText(
                        'o26ziycg' /* Région Culinaire */,
                      ),
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
                    Container(
                      width: 150.0,
                      decoration: BoxDecoration(),
                      child: FutureBuilder<List<FoodRegionRow>>(
                        future: FoodRegionTable().queryRows(
                          queryFn: (q) => q,
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
                          List<FoodRegionRow> foodRegionFoodRegionRowList =
                              snapshot.data!;

                          return FlutterFlowCheckboxGroup(
                            options: foodRegionFoodRegionRowList
                                .map((e) => e.name)
                                .withoutNulls
                                .toList(),
                            onChanged: (val) async {
                              safeSetState(() => _model.foodRegionValues = val);
                              logFirebaseEvent(
                                  'RECIPE_FILTERS_COPY_FoodRegion_ON_FORM_W');
                              logFirebaseEvent('FoodRegion_update_app_state');
                              FFAppState().foodRegion = _model.foodRegionValues!
                                  .toList()
                                  .cast<String>();
                              safeSetState(() {});
                              logFirebaseEvent('FoodRegion_update_app_state');
                              FFAppState().foodRegionJson =
                                  functions.listToJson(
                                      FFAppState().foodRegion.toList(),
                                      'food_region')!;
                              safeSetState(() {});
                            },
                            controller: _model.foodRegionValueController ??=
                                FormFieldController<List<String>>(
                              [],
                            ),
                            activeColor: FlutterFlowTheme.of(context).primary,
                            checkColor: FlutterFlowTheme.of(context).info,
                            checkboxBorderColor:
                                FlutterFlowTheme.of(context).secondaryText,
                            textStyle: FlutterFlowTheme.of(context)
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
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                            checkboxBorderRadius: BorderRadius.circular(4.0),
                            initialized: _model.foodRegionValues != null,
                          );
                        },
                      ),
                    ),
                    Divider(
                      thickness: 2.0,
                      color: FlutterFlowTheme.of(context).alternate,
                    ),
                    Text(
                      FFLocalizations.of(context).getText(
                        'w1sjbt4e' /* Temps de préparation */,
                      ),
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
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100.0,
                          child: TextFormField(
                            controller: _model.cookingTimeTextController1,
                            focusNode: _model.cookingTimeFocusNode1,
                            onChanged: (_) => EasyDebounce.debounce(
                              '_model.cookingTimeTextController1',
                              Duration(milliseconds: 2000),
                              () async {
                                logFirebaseEvent(
                                    'RECIPE_FILTERS_COPY_cookingTime_ON_TEXTF');
                                logFirebaseEvent(
                                    'cookingTime_update_app_state');
                                FFAppState().cookingTIme = ((_model
                                                        .cookingTimeTextController1
                                                        .text !=
                                                    null &&
                                                _model.cookingTimeTextController1
                                                        .text !=
                                                    ''
                                            ? int.parse(_model
                                                .cookingTimeTextController1
                                                .text)
                                            : 0) *
                                        60) +
                                    (_model.cookingTimeTextController2.text !=
                                                null &&
                                            _model.cookingTimeTextController2.text !=
                                                ''
                                        ? int.parse(
                                            _model.cookingTimeTextController2.text)
                                        : 0);
                                safeSetState(() {});
                              },
                            ),
                            autofocus: false,
                            obscureText: false,
                            decoration: InputDecoration(
                              isDense: true,
                              labelStyle: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .override(
                                    font: GoogleFonts.poppins(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                              hintText: FFLocalizations.of(context).getText(
                                'n2afe4j0' /* h */,
                              ),
                              hintStyle: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .override(
                                    font: GoogleFonts.poppins(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0x00000000),
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0x00000000),
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).error,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).error,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              filled: true,
                              fillColor: FlutterFlowTheme.of(context)
                                  .primaryBackground,
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
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                            textAlign: TextAlign.center,
                            cursorColor:
                                FlutterFlowTheme.of(context).primaryText,
                            enableInteractiveSelection: true,
                            validator: _model
                                .cookingTimeTextController1Validator
                                .asValidator(context),
                          ),
                        ),
                        Container(
                          width: 100.0,
                          child: TextFormField(
                            controller: _model.cookingTimeTextController2,
                            focusNode: _model.cookingTimeFocusNode2,
                            onChanged: (_) => EasyDebounce.debounce(
                              '_model.cookingTimeTextController2',
                              Duration(milliseconds: 2000),
                              () async {
                                logFirebaseEvent(
                                    'RECIPE_FILTERS_COPY_cookingTime_ON_TEXTF');
                                logFirebaseEvent(
                                    'cookingTime_update_app_state');
                                FFAppState().cookingTIme = ((_model
                                                        .cookingTimeTextController1
                                                        .text !=
                                                    null &&
                                                _model.cookingTimeTextController1
                                                        .text !=
                                                    ''
                                            ? int.parse(_model
                                                .cookingTimeTextController1
                                                .text)
                                            : 0) *
                                        60) +
                                    (_model.cookingTimeTextController2.text !=
                                                null &&
                                            _model.cookingTimeTextController2.text !=
                                                ''
                                        ? int.parse(
                                            _model.cookingTimeTextController2.text)
                                        : 0);
                                safeSetState(() {});
                              },
                            ),
                            autofocus: false,
                            obscureText: false,
                            decoration: InputDecoration(
                              isDense: true,
                              labelStyle: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .override(
                                    font: GoogleFonts.poppins(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                              hintText: FFLocalizations.of(context).getText(
                                't19oqjfe' /* min  */,
                              ),
                              hintStyle: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .override(
                                    font: GoogleFonts.poppins(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0x00000000),
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0x00000000),
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).error,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).error,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              filled: true,
                              fillColor: FlutterFlowTheme.of(context)
                                  .primaryBackground,
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
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                            textAlign: TextAlign.center,
                            cursorColor:
                                FlutterFlowTheme.of(context).primaryText,
                            enableInteractiveSelection: true,
                            validator: _model
                                .cookingTimeTextController2Validator
                                .asValidator(context),
                          ),
                        ),
                      ].divide(SizedBox(width: 20.0)),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 30.0, 0.0, 0.0),
                      child: FFButtonWidget(
                        onPressed: () async {
                          logFirebaseEvent(
                              'RECIPE_FILTERS_COPY_RECHERCHER_BTN_ON_TA');
                          logFirebaseEvent('Button_backend_call');
                          _model.requestReceipeFilters = await SupabaseGroup
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

                          logFirebaseEvent('Button_backend_call');
                          _model.bodyFilter =
                              await SupabaseGroup.requestBodyCall.call(
                            testJson: functions.buildResearchRequestCopy(
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

                          logFirebaseEvent('Button_update_app_state');
                          FFAppState().receipeReserchResponse =
                              (_model.requestReceipeFilters?.jsonBody ?? '');
                          FFAppState().receipes = SupabaseGroup
                              .updatedRecipeResearchCall
                              .receipes(
                                (_model.requestReceipeFilters?.jsonBody ?? ''),
                              )!
                              .toList()
                              .cast<dynamic>();
                          FFAppState().filter = SupabaseGroup
                              .updatedRecipeResearchCall
                              .filters(
                                (_model.requestReceipeFilters?.jsonBody ?? ''),
                              )!
                              .toList()
                              .cast<dynamic>();
                          FFAppState().filtering = SupabaseGroup
                              .updatedRecipeResearchCall
                              .hasFilters(
                            (_model.requestReceipeFilters?.jsonBody ?? ''),
                          )!;
                          FFAppState().update(() {});
                          logFirebaseEvent('Button_bottom_sheet');
                          Navigator.pop(context);

                          safeSetState(() {});
                        },
                        text: FFLocalizations.of(context).getText(
                          'b6eese9z' /* Rechercher */,
                        ),
                        options: FFButtonOptions(
                          height: 40.0,
                          padding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 0.0, 16.0, 0.0),
                          iconPadding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 0.0, 0.0),
                          color: FlutterFlowTheme.of(context).primary,
                          textStyle:
                              FlutterFlowTheme.of(context).titleSmall.override(
                                    font: GoogleFonts.poppins(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                    color: Colors.white,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                          elevation: 0.0,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ].divide(SizedBox(height: 10.0)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
