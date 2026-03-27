import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/backend/schema/structs/index.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'add_new_meal_model.dart';
export 'add_new_meal_model.dart';

class AddNewMealWidget extends StatefulWidget {
  const AddNewMealWidget({
    super.key,
    required this.recipeToMeal,
  });

  final ReceipeRow? recipeToMeal;

  @override
  State<AddNewMealWidget> createState() => _AddNewMealWidgetState();
}

class _AddNewMealWidgetState extends State<AddNewMealWidget> {
  late AddNewMealModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddNewMealModel());

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
      width: double.infinity,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0.0),
          bottomRight: Radius.circular(0.0),
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(15.0, 0.0, 15.0, 0.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 15.0),
                child: Container(
                  width: 100.0,
                  height: 6.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).alternate,
                    borderRadius: BorderRadius.circular(50.0),
                  ),
                ),
              ),
              Text(
                FFLocalizations.of(context).getText(
                  '0q2ehaqp' /* Ajouter un repas au calendrier */,
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
                      fontWeight:
                          FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                    ),
              ),
              Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (FFAppState().mealID != 0)
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          FFLocalizations.of(context).getText(
                            'wm1vxvig' /* Pour ce repas */,
                          ),
                          style:
                              FlutterFlowTheme.of(context).titleLarge.override(
                                    font: GoogleFonts.outfit(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .titleLarge
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleLarge
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleLarge
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleLarge
                                        .fontStyle,
                                  ),
                        ),
                        FutureBuilder<List<MealRow>>(
                          future: MealTable().querySingleRow(
                            queryFn: (q) => q.eqOrNull(
                              'id',
                              FFAppState().mealID,
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
                                    color:
                                        FlutterFlowTheme.of(context).tertiary,
                                    size: 50.0,
                                  ),
                                ),
                              );
                            }
                            List<MealRow> containerMealRowList = snapshot.data!;

                            final containerMealRow =
                                containerMealRowList.isNotEmpty
                                    ? containerMealRowList.first
                                    : null;

                            return Container(
                              width: 300.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(
                                  color: FlutterFlowTheme.of(context).alternate,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(10.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        FutureBuilder<List<ReceipeImageRow>>(
                                          future: ReceipeImageTable()
                                              .querySingleRow(
                                            queryFn: (q) => q
                                                .eqOrNull(
                                                  'receipe_id',
                                                  containerMealRow?.id,
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
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .tertiary,
                                                    size: 50.0,
                                                  ),
                                                ),
                                              );
                                            }
                                            List<ReceipeImageRow>
                                                imageReceipeImageRowList =
                                                snapshot.data!;

                                            // Return an empty Container when the item does not exist.
                                            if (snapshot.data!.isEmpty) {
                                              return Container();
                                            }
                                            final imageReceipeImageRow =
                                                imageReceipeImageRowList
                                                        .isNotEmpty
                                                    ? imageReceipeImageRowList
                                                        .first
                                                    : null;

                                            return ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              child: Image.network(
                                                imageReceipeImageRow!.url!,
                                                width: 75.0,
                                                height: 75.0,
                                                fit: BoxFit.cover,
                                              ),
                                            );
                                          },
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            if (containerMealRow?.name !=
                                                    null &&
                                                containerMealRow?.name != '')
                                              Text(
                                                valueOrDefault<String>(
                                                  containerMealRow?.name,
                                                  'meal name',
                                                ),
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .titleMedium
                                                    .override(
                                                      font: GoogleFonts.poppins(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleMedium
                                                                .fontStyle,
                                                      ),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleMedium
                                                              .fontStyle,
                                                    ),
                                              ),
                                            Text(
                                              () {
                                                if (containerMealRow
                                                        ?.mealType ==
                                                    'breakfast') {
                                                  return 'Petit-Déjeuner';
                                                } else if (containerMealRow
                                                        ?.mealType ==
                                                    'lunch') {
                                                  return 'Déjeuner';
                                                } else if (containerMealRow
                                                        ?.mealType ==
                                                    'dinner') {
                                                  return 'Dîner';
                                                } else {
                                                  return 'Collation';
                                                }
                                              }(),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .labelLarge
                                                      .override(
                                                        font:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelLarge
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelLarge
                                                                  .fontStyle,
                                                        ),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelLarge
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelLarge
                                                                .fontStyle,
                                                      ),
                                            ),
                                            Text(
                                              dateTimeFormat(
                                                "MMMMEEEEd",
                                                containerMealRow!.mealDate!,
                                                locale:
                                                    FFLocalizations.of(context)
                                                        .languageCode,
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .override(
                                                        font:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontStyle,
                                                        ),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontStyle,
                                                      ),
                                            ),
                                          ],
                                        ),
                                      ].divide(SizedBox(width: 10.0)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        if (!(_model.newMeal1?.succeeded ?? true))
                          Text(
                            valueOrDefault<String>(
                              AddMealErrorStruct.maybeFromMap(
                                      (_model.newMeal1?.jsonBody ?? ''))
                                  ?.uiMessage,
                              'error message',
                            ),
                            textAlign: TextAlign.center,
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
                                  color: FlutterFlowTheme.of(context).accent2,
                                  fontSize: 12.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                          ),
                        FFButtonWidget(
                          onPressed: () async {
                            logFirebaseEvent(
                                'ADD_NEW_MEAL_COMP_MODIFIER_BTN_ON_TAP');
                            logFirebaseEvent('Button_backend_call');
                            _model.newMeal1 =
                                await SupabaseGroup.addANewMealCall.call(
                              mealId: FFAppState().mealID,
                              receipeId: widget!.recipeToMeal?.id,
                              userId:
                                  valueOrDefault(currentUserDocument?.id, 0),
                            );

                            if ((_model.newMeal1?.succeeded ?? true)) {
                              logFirebaseEvent('Button_backend_call');
                              _model.mealScaled = await SupabaseGroup
                                  .mealIngredientsScaleCall
                                  .call(
                                mealId: FFAppState().mealID,
                                mealType:
                                    SupabaseGroup.addANewMealCall.newMealType(
                                  (_model.newMeal1?.jsonBody ?? ''),
                                ),
                                receipeId: widget!.recipeToMeal?.id,
                                userId:
                                    valueOrDefault(currentUserDocument?.id, 0),
                              );

                              if ((_model.mealScaled?.succeeded ?? true)) {
                                logFirebaseEvent('Button_backend_call');
                                _model.shoppingList =
                                    await SupabaseGroup.shoppingListCall.call(
                                  userId: valueOrDefault(
                                      currentUserDocument?.id, 0),
                                  mealId: FFAppState().mealID,
                                  updateMode: 'replace',
                                );

                                if ((_model.shoppingList?.succeeded ?? true)) {
                                  logFirebaseEvent('Button_navigate_to');

                                  context
                                      .pushNamed(MealPlannerWidget.routeName);

                                  logFirebaseEvent('Button_update_app_state');
                                  FFAppState().mealID = 0;
                                  safeSetState(() {});
                                }
                              }
                            }

                            safeSetState(() {});
                          },
                          text: FFLocalizations.of(context).getText(
                            'i4uuxywb' /* Modifier */,
                          ),
                          options: FFButtonOptions(
                            height: 40.0,
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 0.0, 16.0, 0.0),
                            iconPadding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 0.0),
                            color: FlutterFlowTheme.of(context).primary,
                            textStyle: FlutterFlowTheme.of(context)
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
                      ].divide(SizedBox(height: 15.0)),
                    ),
                  if (FFAppState().mealID != 0)
                    Divider(
                      thickness: 2.0,
                      color: FlutterFlowTheme.of(context).alternate,
                    ),
                  if (FFAppState().mealID != 0)
                    Text(
                      FFLocalizations.of(context).getText(
                        '5i1fbrb6' /* Pour un autre repas */,
                      ),
                      style: FlutterFlowTheme.of(context).titleLarge.override(
                            font: GoogleFonts.outfit(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .titleLarge
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleLarge
                                  .fontStyle,
                            ),
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .titleLarge
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .titleLarge
                                .fontStyle,
                          ),
                    ),
                ].divide(SizedBox(height: 20.0)),
              ),
              Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  FlutterFlowDropDown<String>(
                    controller: _model.mealTypeValueController ??=
                        FormFieldController<String>(null),
                    options: [
                      FFLocalizations.of(context).getText(
                        '8nexdmm4' /* Petit-Déjeuner */,
                      ),
                      FFLocalizations.of(context).getText(
                        '647mfxo3' /* Déjeuner */,
                      ),
                      FFLocalizations.of(context).getText(
                        '5irnl4va' /* Collation */,
                      ),
                      FFLocalizations.of(context).getText(
                        'mnt1scsz' /* Dîner */,
                      )
                    ],
                    onChanged: (val) =>
                        safeSetState(() => _model.mealTypeValue = val),
                    width: 300.0,
                    height: 56.0,
                    textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
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
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                    hintText: FFLocalizations.of(context).getText(
                      'yhq0ll6a' /* Selectionner le type de repas */,
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: FlutterFlowTheme.of(context).secondaryText,
                      size: 24.0,
                    ),
                    fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                    elevation: 2.0,
                    borderColor: FlutterFlowTheme.of(context).alternate,
                    borderWidth: 2.0,
                    borderRadius: 8.0,
                    margin:
                        EdgeInsetsDirectional.fromSTEB(16.0, 4.0, 16.0, 4.0),
                    hidesUnderline: true,
                    isOverButton: true,
                    isSearchable: false,
                    isMultiSelect: false,
                  ),
                  FlutterFlowDropDown<String>(
                    controller: _model.meaDayValueController ??=
                        FormFieldController<String>(null),
                    options: [
                      FFLocalizations.of(context).getText(
                        'zon2xeru' /* Lundi */,
                      ),
                      FFLocalizations.of(context).getText(
                        'k1kkyv0s' /* Mardi */,
                      ),
                      FFLocalizations.of(context).getText(
                        'fyqnfqqw' /* Mercredi */,
                      ),
                      FFLocalizations.of(context).getText(
                        '5jb30544' /* Jeudi */,
                      ),
                      FFLocalizations.of(context).getText(
                        'hops39aq' /* Vendredi */,
                      ),
                      FFLocalizations.of(context).getText(
                        'y4e5nsaq' /* Samedi */,
                      ),
                      FFLocalizations.of(context).getText(
                        'm81cdmwc' /* Dimanche */,
                      )
                    ],
                    onChanged: (val) =>
                        safeSetState(() => _model.meaDayValue = val),
                    width: 300.0,
                    height: 56.0,
                    textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
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
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                    hintText: FFLocalizations.of(context).getText(
                      '65nj6akg' /* Selectionner le jour du repas */,
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: FlutterFlowTheme.of(context).secondaryText,
                      size: 24.0,
                    ),
                    fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                    elevation: 2.0,
                    borderColor: FlutterFlowTheme.of(context).alternate,
                    borderWidth: 2.0,
                    borderRadius: 8.0,
                    margin:
                        EdgeInsetsDirectional.fromSTEB(16.0, 4.0, 16.0, 4.0),
                    hidesUnderline: true,
                    isOverButton: true,
                    isSearchable: false,
                    isMultiSelect: false,
                  ),
                  if (!(_model.updatedMeal?.succeeded ?? true))
                    Text(
                      valueOrDefault<String>(
                        SupabaseGroup.addANewMealCall.message(
                          (_model.updatedMeal?.jsonBody ?? ''),
                        ),
                        'error mesage',
                      ),
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
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
                    ),
                  if (!(_model.updatedSnack?.succeeded ?? true))
                    Text(
                      valueOrDefault<String>(
                        SupabaseGroup.addANewMealCall.message(
                          (_model.updatedSnack?.jsonBody ?? ''),
                        ),
                        'message',
                      ),
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
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
                    ),
                  Container(
                    decoration: BoxDecoration(),
                    child: FFButtonWidget(
                      onPressed: () async {
                        logFirebaseEvent(
                            'ADD_NEW_MEAL_COMP_VALIDER_BTN_ON_TAP');
                        if (_model.mealTypeValue == 'Collation') {
                          logFirebaseEvent('Button_backend_call');
                          _model.snackMealPlan =
                              await MealPlanTable().queryRows(
                            queryFn: (q) => q
                                .eqOrNull(
                                  'user_id',
                                  valueOrDefault(currentUserDocument?.id, 0),
                                )
                                .lteOrNull(
                                  'start_date',
                                  supaSerialize<DateTime>(getCurrentTimestamp),
                                )
                                .gteOrNull(
                                  'end_date',
                                  supaSerialize<DateTime>(getCurrentTimestamp),
                                ),
                          );
                          logFirebaseEvent('Button_backend_call');
                          _model.mappedSnack = await MealTable().queryRows(
                            queryFn: (q) => q.eqOrNull(
                              'day',
                              () {
                                if (_model.meaDayValue == 'Lundi') {
                                  return 'Monday';
                                } else if (_model.meaDayValue == 'Mardi') {
                                  return 'Tuesday';
                                } else if (_model.meaDayValue == 'Mercredi') {
                                  return 'Wednesday';
                                } else if (_model.meaDayValue == 'Jeudi') {
                                  return 'Thursday';
                                } else if (_model.meaDayValue == 'Vendredi') {
                                  return 'Friday';
                                } else if (_model.meaDayValue == 'Samedi') {
                                  return 'Saturday';
                                } else {
                                  return 'Sunday';
                                }
                              }(),
                            ).eqOrNull(
                              'meal_plan_id',
                              _model.snackMealPlan?.firstOrNull?.id,
                            ),
                          );
                          logFirebaseEvent('Button_backend_call');
                          _model.newSnackMeal = await MealTable().insert({
                            'meal_plan_id':
                                _model.snackMealPlan?.firstOrNull?.id,
                            'day': () {
                              if (_model.meaDayValue == 'Lundi') {
                                return 'Monday';
                              } else if (_model.meaDayValue == 'Mardi') {
                                return 'Tuesday';
                              } else if (_model.meaDayValue == 'Mercredi') {
                                return 'Wednesday';
                              } else if (_model.meaDayValue == 'Jeudi') {
                                return 'Thursday';
                              } else if (_model.meaDayValue == 'Vendredi') {
                                return 'Friday';
                              } else if (_model.meaDayValue == 'Samedi') {
                                return 'Saturday';
                              } else {
                                return 'Sunday';
                              }
                            }(),
                            'consumed': false,
                            'personal': false,
                            'meal_type': 'snack',
                            'user_id':
                                valueOrDefault(currentUserDocument?.id, 0),
                            'receipe_id': widget!.recipeToMeal?.id,
                            'meal_date': supaSerialize<DateTime>(
                                _model.mappedSnack?.firstOrNull?.mealDate),
                          });
                          logFirebaseEvent('Button_backend_call');
                          _model.updatedSnack =
                              await SupabaseGroup.addANewMealCall.call(
                            mealId: _model.newSnackMeal?.id,
                            receipeId: widget!.recipeToMeal?.id,
                            userId: valueOrDefault(currentUserDocument?.id, 0),
                          );

                          if ((_model.updatedSnack?.succeeded ?? true)) {
                            logFirebaseEvent('Button_backend_call');
                            _model.scaledSnack = await SupabaseGroup
                                .mealIngredientsScaleCall
                                .call(
                              mealId: _model.newSnackMeal?.id,
                              receipeId: widget!.recipeToMeal?.id,
                              mealType: _model.newSnackMeal?.mealType,
                              userId:
                                  valueOrDefault(currentUserDocument?.id, 0),
                            );

                            if ((_model.scaledSnack?.succeeded ?? true)) {
                              logFirebaseEvent('Button_backend_call');
                              _model.addedShoppingList = await SupabaseGroup
                                  .mealPlanShoppingListCall
                                  .call(
                                mealPlanId: _model.newSnackMeal?.mealPlanId,
                                updateMode: 'replace',
                                userId:
                                    valueOrDefault(currentUserDocument?.id, 0),
                              );

                              if ((_model.addedShoppingList?.succeeded ??
                                  true)) {
                                logFirebaseEvent('Button_bottom_sheet');
                                Navigator.pop(context);
                                logFirebaseEvent('Button_navigate_to');

                                context.pushNamed(MealPlannerWidget.routeName);
                              }
                            }
                          }
                        } else {
                          logFirebaseEvent('Button_backend_call');
                          _model.mealPlan = await MealPlanTable().queryRows(
                            queryFn: (q) => q
                                .eqOrNull(
                                  'user_id',
                                  valueOrDefault(currentUserDocument?.id, 0),
                                )
                                .lteOrNull(
                                  'start_date',
                                  supaSerialize<DateTime>(getCurrentTimestamp),
                                )
                                .gteOrNull(
                                  'end_date',
                                  supaSerialize<DateTime>(getCurrentTimestamp),
                                ),
                          );
                          logFirebaseEvent('Button_backend_call');
                          _model.meal = await MealTable().queryRows(
                            queryFn: (q) => q
                                .eqOrNull(
                              'meal_plan_id',
                              _model.mealPlan?.firstOrNull?.id,
                            )
                                .eqOrNull(
                              'meal_type',
                              () {
                                if (_model.mealTypeValue == 'Petit-Déjeuner') {
                                  return 'breakfast';
                                } else if (_model.mealTypeValue == 'Déjeuner') {
                                  return 'lunch';
                                } else if (_model.mealTypeValue == 'Dîner') {
                                  return 'dinner';
                                } else {
                                  return 'snack';
                                }
                              }(),
                            ).eqOrNull(
                              'day',
                              () {
                                if (_model.meaDayValue == 'Lundi') {
                                  return 'Monday';
                                } else if (_model.meaDayValue == 'Mardi') {
                                  return 'Tuesday';
                                } else if (_model.meaDayValue == 'Mercredi') {
                                  return 'Wednesday';
                                } else if (_model.meaDayValue == 'Jeudi') {
                                  return 'Thursday';
                                } else if (_model.meaDayValue == 'Vendredi') {
                                  return 'Friday';
                                } else if (_model.meaDayValue == 'Samedi') {
                                  return 'Saturday';
                                } else {
                                  return 'Sunday';
                                }
                              }(),
                            ),
                          );
                          logFirebaseEvent('Button_backend_call');
                          _model.updatedMeal =
                              await SupabaseGroup.addANewMealCall.call(
                            mealId: _model.meal?.firstOrNull?.id,
                            receipeId: widget!.recipeToMeal?.id,
                            userId: valueOrDefault(currentUserDocument?.id, 0),
                          );

                          if ((_model.updatedMeal?.succeeded ?? true)) {
                            logFirebaseEvent('Button_backend_call');
                            _model.updateMealIngredients = await SupabaseGroup
                                .mealIngredientsScaleCall
                                .call(
                              mealId: SupabaseGroup.addANewMealCall.newMealID(
                                (_model.updatedMeal?.jsonBody ?? ''),
                              ),
                              receipeId: widget!.recipeToMeal?.id,
                              userId:
                                  valueOrDefault(currentUserDocument?.id, 0),
                            );

                            if ((_model.updateMealIngredients?.succeeded ??
                                true)) {
                              logFirebaseEvent('Button_backend_call');
                              _model.updatedShoppingList =
                                  await SupabaseGroup.shoppingListCall.call(
                                mealId: _model.meal?.firstOrNull?.id,
                                userId:
                                    valueOrDefault(currentUserDocument?.id, 0),
                                updateMode: 'replace',
                              );

                              if ((_model.updatedShoppingList?.succeeded ??
                                  true)) {
                                logFirebaseEvent('Button_navigate_to');

                                context.pushNamed(MealPlannerWidget.routeName);
                              }
                            }
                          }
                        }

                        safeSetState(() {});
                      },
                      text: FFLocalizations.of(context).getText(
                        '2ey4dlyv' /* Valider */,
                      ),
                      options: FFButtonOptions(
                        height: 40.0,
                        padding: EdgeInsetsDirectional.fromSTEB(
                            24.0, 0.0, 24.0, 0.0),
                        iconPadding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
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
                        elevation: 3.0,
                        borderSide: BorderSide(
                          color: Colors.transparent,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ].divide(SizedBox(height: 10.0)),
              ),
            ]
                .divide(SizedBox(height: 15.0))
                .addToStart(SizedBox(height: 25.0))
                .addToEnd(SizedBox(height: 25.0)),
          ),
        ),
      ),
    );
  }
}
