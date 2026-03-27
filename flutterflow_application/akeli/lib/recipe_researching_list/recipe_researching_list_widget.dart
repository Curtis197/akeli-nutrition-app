import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/components/oredering_selector_widget.dart';
import '/components/tag_and_or_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/recipe_management/recipe_card_j_s_o_n_copy/recipe_card_j_s_o_n_copy_widget.dart';
import '/recipe_management/recipe_filters_copy/recipe_filters_copy_widget.dart';
import 'dart:ui';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'recipe_researching_list_model.dart';
export 'recipe_researching_list_model.dart';

class RecipeResearchingListWidget extends StatefulWidget {
  const RecipeResearchingListWidget({super.key});

  static String routeName = 'recipeResearchingList';
  static String routePath = '/recipeResearchingList';

  @override
  State<RecipeResearchingListWidget> createState() =>
      _RecipeResearchingListWidgetState();
}

class _RecipeResearchingListWidgetState
    extends State<RecipeResearchingListWidget> {
  late RecipeResearchingListModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RecipeResearchingListModel());

    logFirebaseEvent('screen_view',
        parameters: {'screen_name': 'recipeResearchingList'});
    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      logFirebaseEvent('RECIPE_RESEARCHING_LIST_recipeResearchin');
      logFirebaseEvent('recipeResearchingList_backend_call');
      _model.requestReceipePage =
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

      logFirebaseEvent('recipeResearchingList_update_app_state');
      FFAppState().receipeReserchResponse =
          (_model.requestReceipePage?.jsonBody ?? '');
      FFAppState().receipes = SupabaseGroup.updatedRecipeResearchCall
          .receipes(
            (_model.requestReceipePage?.jsonBody ?? ''),
          )!
          .toList()
          .cast<dynamic>();
      FFAppState().filter = SupabaseGroup.updatedRecipeResearchCall
          .filters(
            (_model.requestReceipePage?.jsonBody ?? ''),
          )!
          .toList()
          .cast<dynamic>();
      safeSetState(() {});
    });

    _model.nameTextController ??= TextEditingController();
    _model.nameFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          automaticallyImplyLeading: false,
          title: Text(
            FFLocalizations.of(context).getText(
              '2que1tta' /* Recette */,
            ),
            style: FlutterFlowTheme.of(context).headlineLarge.override(
                  font: GoogleFonts.outfit(
                    fontWeight:
                        FlutterFlowTheme.of(context).headlineLarge.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).headlineLarge.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).primary,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).headlineLarge.fontWeight,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineLarge.fontStyle,
                ),
          ),
          actions: [],
          centerTitle: true,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(10.0, 10.0, 10.0, 0.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        decoration: BoxDecoration(),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: Container(
                                width: 200.0,
                                child: TextFormField(
                                  controller: _model.nameTextController,
                                  focusNode: _model.nameFocusNode,
                                  onChanged: (_) => EasyDebounce.debounce(
                                    '_model.nameTextController',
                                    Duration(milliseconds: 2000),
                                    () async {
                                      logFirebaseEvent(
                                          'RECIPE_RESEARCHING_LIST_name_ON_TEXTFIEL');
                                      logFirebaseEvent('name_update_app_state');
                                      FFAppState().name =
                                          _model.nameTextController.text;
                                      safeSetState(() {});
                                      logFirebaseEvent('name_backend_call');
                                      _model.requestReceipeName =
                                          await SupabaseGroup
                                              .updatedRecipeResearchCall
                                              .call(
                                        bodyJson:
                                            functions.buildResearchRequestCopy(
                                                FFAppState().name,
                                                FFAppState().calMin,
                                                FFAppState().calMax,
                                                FFAppState().type.toList(),
                                                FFAppState().typeLogic,
                                                FFAppState().tags.toList(),
                                                FFAppState().tagLogic,
                                                FFAppState()
                                                    .foodRegion
                                                    .toList(),
                                                FFAppState().dificulty.toList(),
                                                FFAppState().cookingTIme,
                                                FFAppState().orderBy,
                                                FFAppState().orderAscend,
                                                FFAppState().sansPorc),
                                      );

                                      logFirebaseEvent('name_update_app_state');
                                      FFAppState().receipeReserchResponse =
                                          (_model.requestReceipeName
                                                  ?.jsonBody ??
                                              '');
                                      FFAppState().receipes = SupabaseGroup
                                          .updatedRecipeResearchCall
                                          .receipes(
                                            (_model.requestReceipeName
                                                    ?.jsonBody ??
                                                ''),
                                          )!
                                          .toList()
                                          .cast<dynamic>();
                                      FFAppState().filter = SupabaseGroup
                                          .updatedRecipeResearchCall
                                          .filters(
                                            (_model.requestReceipeName
                                                    ?.jsonBody ??
                                                ''),
                                          )!
                                          .toList()
                                          .cast<dynamic>();
                                      FFAppState().filtering = SupabaseGroup
                                          .updatedRecipeResearchCall
                                          .hasFilters(
                                        (_model.requestReceipeName?.jsonBody ??
                                            ''),
                                      )!;
                                      safeSetState(() {});

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
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                        ),
                                    hintText:
                                        FFLocalizations.of(context).getText(
                                      'zncpa31e' /* Rechercher votre recette */,
                                    ),
                                    hintStyle: FlutterFlowTheme.of(context)
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
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                        ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0x00000000),
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(50.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0x00000000),
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(50.0),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(50.0),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(50.0),
                                    ),
                                    filled: true,
                                    fillColor: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                    suffixIcon: Icon(
                                      Icons.search_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: 24.0,
                                    ),
                                  ),
                                  style: FlutterFlowTheme.of(context)
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
                                  cursorColor:
                                      FlutterFlowTheme.of(context).primaryText,
                                  enableInteractiveSelection: true,
                                  validator: _model.nameTextControllerValidator
                                      .asValidator(context),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                FlutterFlowIconButton(
                                  borderRadius: 8.0,
                                  buttonSize: 40.0,
                                  fillColor: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                  icon: Icon(
                                    Icons.filter_alt,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    size: 24.0,
                                  ),
                                  onPressed: () async {
                                    logFirebaseEvent(
                                        'RECIPE_RESEARCHING_LIST_filter_alt_ICN_O');
                                    logFirebaseEvent('IconButton_bottom_sheet');
                                    await showModalBottomSheet(
                                      isScrollControlled: true,
                                      backgroundColor:
                                          FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                      enableDrag: false,
                                      context: context,
                                      builder: (context) {
                                        return WebViewAware(
                                          child: GestureDetector(
                                            onTap: () {
                                              FocusScope.of(context).unfocus();
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                            },
                                            child: Padding(
                                              padding: MediaQuery.viewInsetsOf(
                                                  context),
                                              child: Container(
                                                height: 600.0,
                                                child:
                                                    RecipeFiltersCopyWidget(),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ).then((value) => safeSetState(() {}));
                                  },
                                ),
                              ].divide(SizedBox(width: 5.0)),
                            ),
                            if (FFAppState().ordering)
                              FlutterFlowIconButton(
                                borderRadius: 8.0,
                                buttonSize: 40.0,
                                fillColor: FlutterFlowTheme.of(context).primary,
                                icon: Icon(
                                  Icons.filter_list,
                                  color: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                  size: 24.0,
                                ),
                                onPressed: () async {
                                  logFirebaseEvent(
                                      'RECIPE_RESEARCHING_LIST_filter_list_ICN_');
                                  logFirebaseEvent(
                                      'IconButton_update_app_state');
                                  FFAppState().orderMenu =
                                      !(FFAppState().orderMenu ?? true);
                                  safeSetState(() {});
                                },
                              ),
                            if (!FFAppState().ordering)
                              FlutterFlowIconButton(
                                borderRadius: 8.0,
                                buttonSize: 40.0,
                                fillColor: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                                icon: Icon(
                                  Icons.filter_list,
                                  color: FlutterFlowTheme.of(context).primary,
                                  size: 24.0,
                                ),
                                onPressed: () async {
                                  logFirebaseEvent(
                                      'RECIPE_RESEARCHING_LIST_filter_list_ICN_');
                                  logFirebaseEvent(
                                      'IconButton_update_app_state');
                                  FFAppState().orderMenu =
                                      !(FFAppState().orderMenu ?? true);
                                  safeSetState(() {});
                                },
                              ),
                          ].divide(SizedBox(width: 10.0)),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (FFAppState().orderMenu)
                            wrapWithModel(
                              model: _model.orederingSelectorModel,
                              updateCallback: () => safeSetState(() {}),
                              child: OrederingSelectorWidget(),
                            ),
                        ],
                      ),
                    ].divide(SizedBox(height: 5.0)),
                  ),
                ),
                if (FFAppState().filtering)
                  Divider(
                    thickness: 2.0,
                    color: FlutterFlowTheme.of(context).alternate,
                  ),
                if (FFAppState().filtering)
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(10.0, 0.0, 10.0, 0.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Builder(
                          builder: (context) {
                            final filter = FFAppState().filter.toList();

                            return Wrap(
                              spacing: 10.0,
                              runSpacing: 10.0,
                              alignment: WrapAlignment.start,
                              crossAxisAlignment: WrapCrossAlignment.start,
                              direction: Axis.horizontal,
                              runAlignment: WrapAlignment.start,
                              verticalDirection: VerticalDirection.down,
                              clipBehavior: Clip.none,
                              children:
                                  List.generate(filter.length, (filterIndex) {
                                final filterItem = filter[filterIndex];
                                return Container(
                                  decoration: BoxDecoration(
                                    color:
                                        FlutterFlowTheme.of(context).alternate,
                                    borderRadius: BorderRadius.circular(15.0),
                                    border: Border.all(
                                      color: FlutterFlowTheme.of(context)
                                          .alternate,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        10.0, 5.0, 10.0, 5.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          valueOrDefault<String>(
                                            FilterStruct.maybeFromMap(
                                                    filterItem)
                                                ?.value,
                                            'value',
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .labelSmall
                                              .override(
                                                font: GoogleFonts.poppins(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelSmall
                                                          .fontStyle,
                                                ),
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .labelSmall
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelSmall
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
                                                'RECIPE_RESEARCHING_LIST_Icon_gfcg1ble_ON');
                                            if (FilterStruct.maybeFromMap(
                                                        filterItem)
                                                    ?.key ==
                                                'calorie_gte') {
                                              logFirebaseEvent(
                                                  'Icon_update_app_state');
                                              FFAppState().calMin = 0;
                                              safeSetState(() {});
                                            } else if (FilterStruct
                                                        .maybeFromMap(
                                                            filterItem)
                                                    ?.key ==
                                                'calorie_lte') {
                                              logFirebaseEvent(
                                                  'Icon_update_app_state');
                                              FFAppState().calMax = 6000000;
                                              safeSetState(() {});
                                            } else if (FilterStruct
                                                        .maybeFromMap(
                                                            filterItem)
                                                    ?.key ==
                                                'sans porc') {
                                              logFirebaseEvent(
                                                  'Icon_update_app_state');
                                              FFAppState().sansPorc = false;
                                              safeSetState(() {});
                                            } else if (FilterStruct
                                                        .maybeFromMap(
                                                            filterItem)
                                                    ?.key ==
                                                'Food Region') {
                                              logFirebaseEvent(
                                                  'Icon_update_app_state');
                                              FFAppState().removeFromFoodRegion(
                                                  FilterStruct.maybeFromMap(
                                                          filterItem)!
                                                      .value);
                                              safeSetState(() {});
                                            } else if (FilterStruct
                                                        .maybeFromMap(
                                                            filterItem)
                                                    ?.key ==
                                                'difficulty_levels') {
                                              logFirebaseEvent(
                                                  'Icon_update_app_state');
                                              FFAppState().removeFromDificulty(
                                                  FilterStruct.maybeFromMap(
                                                          filterItem)!
                                                      .value);
                                              safeSetState(() {});
                                            } else if (FilterStruct
                                                        .maybeFromMap(
                                                            filterItem)
                                                    ?.key ==
                                                'total_cooking_time_minutes_lte') {
                                              logFirebaseEvent(
                                                  'Icon_update_app_state');
                                              FFAppState().cookingTIme = 600000;
                                              safeSetState(() {});
                                            } else if (FilterStruct
                                                        .maybeFromMap(
                                                            filterItem)
                                                    ?.key ==
                                                'tags') {
                                              logFirebaseEvent(
                                                  'Icon_update_app_state');
                                              FFAppState().removeFromTags(
                                                  FilterStruct.maybeFromMap(
                                                          filterItem)!
                                                      .value);
                                              safeSetState(() {});
                                            } else {
                                              logFirebaseEvent(
                                                  'Icon_update_app_state');
                                              FFAppState().removeFromType(
                                                  FilterStruct.maybeFromMap(
                                                          filterItem)!
                                                      .value);
                                              safeSetState(() {});
                                            }

                                            logFirebaseEvent(
                                                'Icon_update_app_state');
                                            FFAppState()
                                                .removeFromFilter(filterItem);
                                            safeSetState(() {});
                                            logFirebaseEvent(
                                                'Icon_backend_call');
                                            _model.requestReceipeClearTag =
                                                await SupabaseGroup
                                                    .updatedRecipeResearchCall
                                                    .call(
                                              bodyJson: functions
                                                  .buildResearchRequestCopy(
                                                      FFAppState().name,
                                                      FFAppState().calMin,
                                                      FFAppState().calMax,
                                                      FFAppState()
                                                          .type
                                                          .toList(),
                                                      FFAppState().typeLogic,
                                                      FFAppState()
                                                          .tags
                                                          .toList(),
                                                      FFAppState().tagLogic,
                                                      FFAppState()
                                                          .foodRegion
                                                          .toList(),
                                                      FFAppState()
                                                          .dificulty
                                                          .toList(),
                                                      FFAppState().cookingTIme,
                                                      FFAppState().orderBy,
                                                      FFAppState().orderAscend,
                                                      FFAppState().sansPorc),
                                            );

                                            logFirebaseEvent(
                                                'Icon_backend_call');
                                            _model.bodyClearTag =
                                                await SupabaseGroup
                                                    .requestBodyCall
                                                    .call(
                                              testJson: functions
                                                  .buildResearchRequestCopy(
                                                      FFAppState().name,
                                                      FFAppState().calMin,
                                                      FFAppState().calMax,
                                                      FFAppState()
                                                          .type
                                                          .toList(),
                                                      FFAppState().typeLogic,
                                                      FFAppState()
                                                          .tags
                                                          .toList(),
                                                      FFAppState().tagLogic,
                                                      FFAppState()
                                                          .foodRegion
                                                          .toList(),
                                                      FFAppState()
                                                          .dificulty
                                                          .toList(),
                                                      FFAppState().cookingTIme,
                                                      FFAppState().orderBy,
                                                      FFAppState().orderAscend,
                                                      FFAppState().sansPorc),
                                            );

                                            logFirebaseEvent(
                                                'Icon_update_app_state');
                                            FFAppState()
                                                    .receipeReserchResponse =
                                                (_model.requestReceipeClearTag
                                                        ?.jsonBody ??
                                                    '');
                                            FFAppState().receipes =
                                                SupabaseGroup
                                                    .updatedRecipeResearchCall
                                                    .receipes(
                                                      (_model.requestReceipeClearTag
                                                              ?.jsonBody ??
                                                          ''),
                                                    )!
                                                    .toList()
                                                    .cast<dynamic>();
                                            FFAppState().filter = SupabaseGroup
                                                .updatedRecipeResearchCall
                                                .filters(
                                                  (_model.requestReceipeClearTag
                                                          ?.jsonBody ??
                                                      ''),
                                                )!
                                                .toList()
                                                .cast<dynamic>();
                                            FFAppState().filtering =
                                                SupabaseGroup
                                                    .updatedRecipeResearchCall
                                                    .hasFilters(
                                              (_model.requestReceipeClearTag
                                                      ?.jsonBody ??
                                                  ''),
                                            )!;
                                            safeSetState(() {});

                                            safeSetState(() {});
                                          },
                                          child: Icon(
                                            Icons.close,
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            size: 18.0,
                                          ),
                                        ),
                                      ].divide(SizedBox(width: 5.0)),
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                Divider(
                  thickness: 2.0,
                  color: FlutterFlowTheme.of(context).alternate,
                ),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    if (FFAppState().tags.isNotEmpty)
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          logFirebaseEvent(
                              'RECIPE_RESEARCHING_LIST_Container_ig1w0r');
                          logFirebaseEvent('TagAndOr_update_app_state');
                          FFAppState().tagLogic =
                              FFAppState().tagLogic == 'AND' ? 'OR' : 'AND';
                          safeSetState(() {});
                          logFirebaseEvent('TagAndOr_backend_call');
                          _model.requestReceipe = await SupabaseGroup
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

                          logFirebaseEvent('TagAndOr_update_app_state');
                          FFAppState().receipeReserchResponse =
                              (_model.requestReceipePage?.jsonBody ?? '');
                          FFAppState()
                              .receipes = ReceipeDataStruct.maybeFromMap(
                                  (_model.requestReceipePage?.jsonBody ?? ''))!
                              .recipes
                              .map((e) => e.toMap())
                              .toList()
                              .cast<dynamic>();
                          safeSetState(() {});

                          safeSetState(() {});
                        },
                        child: wrapWithModel(
                          model: _model.tagAndOrModel,
                          updateCallback: () => safeSetState(() {}),
                          child: TagAndOrWidget(),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.all(10.0),
                      child: FutureBuilder<List<TagsRow>>(
                        future: TagsTable().queryRows(
                          queryFn: (q) => q.eqOrNull(
                            'language',
                            'fr',
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
                          List<TagsRow> rowTagsRowList = snapshot.data!;

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: List.generate(rowTagsRowList.length,
                                  (rowIndex) {
                                final rowTagsRow = rowTagsRowList[rowIndex];
                                return Visibility(
                                  visible: rowTagsRow.receipeCreated! > 0,
                                  child: InkWell(
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () async {
                                      logFirebaseEvent(
                                          'RECIPE_RESEARCHING_LIST_Container_orp5h9');
                                      logFirebaseEvent(
                                          'Container_update_app_state');
                                      FFAppState().addToTags(rowTagsRow.name!);
                                      safeSetState(() {});
                                      logFirebaseEvent(
                                          'Container_backend_call');
                                      _model.requestReceipeTag =
                                          await SupabaseGroup
                                              .updatedRecipeResearchCall
                                              .call(
                                        bodyJson:
                                            functions.buildResearchRequestCopy(
                                                FFAppState().name,
                                                FFAppState().calMin,
                                                FFAppState().calMax,
                                                FFAppState().type.toList(),
                                                FFAppState().typeLogic,
                                                FFAppState().tags.toList(),
                                                FFAppState().tagLogic,
                                                FFAppState()
                                                    .foodRegion
                                                    .toList(),
                                                FFAppState().dificulty.toList(),
                                                FFAppState().cookingTIme,
                                                FFAppState().orderBy,
                                                FFAppState().orderAscend,
                                                FFAppState().sansPorc),
                                      );

                                      logFirebaseEvent(
                                          'Container_update_app_state');
                                      FFAppState().receipeReserchResponse =
                                          (_model.requestReceipeTag?.jsonBody ??
                                              '');
                                      FFAppState().receipes = SupabaseGroup
                                          .updatedRecipeResearchCall
                                          .receipes(
                                            (_model.requestReceipeTag
                                                    ?.jsonBody ??
                                                ''),
                                          )!
                                          .toList()
                                          .cast<dynamic>();
                                      FFAppState().filter = SupabaseGroup
                                          .updatedRecipeResearchCall
                                          .filters(
                                            (_model.requestReceipeTag
                                                    ?.jsonBody ??
                                                ''),
                                          )!
                                          .toList()
                                          .cast<dynamic>();
                                      FFAppState().filtering = SupabaseGroup
                                          .updatedRecipeResearchCall
                                          .hasFilters(
                                        (_model.requestReceipeTag?.jsonBody ??
                                            ''),
                                      )!;
                                      safeSetState(() {});

                                      safeSetState(() {});
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                        border: Border.all(
                                          color: FlutterFlowTheme.of(context)
                                              .alternate,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            10.0, 5.0, 10.0, 5.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Text(
                                              valueOrDefault<String>(
                                                rowTagsRow.name,
                                                'nom',
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .override(
                                                        font:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontStyle,
                                                        ),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelSmall
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelSmall
                                                                .fontStyle,
                                                      ),
                                            ),
                                            Text(
                                              valueOrDefault<String>(
                                                rowTagsRow.receipeCreated
                                                    ?.toString(),
                                                '0',
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .override(
                                                        font:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontStyle,
                                                        ),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelSmall
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelSmall
                                                                .fontStyle,
                                                      ),
                                            ),
                                          ].divide(SizedBox(width: 5.0)),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).divide(
                                SizedBox(width: 10.0),
                                filterFn: (rowIndex) {
                                  final rowTagsRow = rowTagsRowList[rowIndex];
                                  return rowTagsRow.receipeCreated! > 0;
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (FFAppState().mealID != null)
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primaryBackground,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Visibility(
                        visible: FFAppState().mealID != 0,
                        child: Padding(
                          padding: EdgeInsets.all(10.0),
                          child: FutureBuilder<List<MealRow>>(
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
                              List<MealRow> columnMealRowList = snapshot.data!;

                              final columnMealRow = columnMealRowList.isNotEmpty
                                  ? columnMealRowList.first
                                  : null;

                              return Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 5.0, 5.0, 0.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        InkWell(
                                          splashColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () async {
                                            logFirebaseEvent(
                                                'RECIPE_RESEARCHING_LIST_Icon_8vw18pp3_ON');
                                            logFirebaseEvent(
                                                'Icon_update_app_state');
                                            FFAppState().mealID = 0;
                                            safeSetState(() {});
                                          },
                                          child: Icon(
                                            Icons.close_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            size: 24.0,
                                          ),
                                        ),
                                      ].divide(SizedBox(width: 10.0)),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        12.0, 0.0, 12.0, 12.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        if (columnMealRow?.imageUrl != null &&
                                            columnMealRow?.imageUrl != '')
                                          FutureBuilder<List<ReceipeImageRow>>(
                                            future: ReceipeImageTable()
                                                .querySingleRow(
                                              queryFn: (q) => q
                                                  .eqOrNull(
                                                    'receipe_id',
                                                    columnMealRow?.receipeId,
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
                                                      color:
                                                          FlutterFlowTheme.of(
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 200.0,
                                              decoration: BoxDecoration(),
                                              child: Visibility(
                                                visible: columnMealRow?.name !=
                                                        null &&
                                                    columnMealRow?.name != '',
                                                child: FutureBuilder<
                                                    List<ReceipeRow>>(
                                                  future: ReceipeTable()
                                                      .querySingleRow(
                                                    queryFn: (q) => q.eqOrNull(
                                                      'id',
                                                      columnMealRow?.receipeId,
                                                    ),
                                                  ),
                                                  builder: (context, snapshot) {
                                                    // Customize what your widget looks like when it's loading.
                                                    if (!snapshot.hasData) {
                                                      return Center(
                                                        child: SizedBox(
                                                          width: 50.0,
                                                          height: 50.0,
                                                          child:
                                                              SpinKitDoubleBounce(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .tertiary,
                                                            size: 50.0,
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                    List<ReceipeRow>
                                                        textReceipeRowList =
                                                        snapshot.data!;

                                                    final textReceipeRow =
                                                        textReceipeRowList
                                                                .isNotEmpty
                                                            ? textReceipeRowList
                                                                .first
                                                            : null;

                                                    return Text(
                                                      valueOrDefault<String>(
                                                        textReceipeRow?.name,
                                                        'receipe name ',
                                                      ),
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleLarge
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleLarge
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleLarge
                                                                      .fontStyle,
                                                                ),
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleLarge
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleLarge
                                                                    .fontStyle,
                                                              ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            Text(
                                              () {
                                                if (columnMealRow?.mealType ==
                                                    'breakfast') {
                                                  return 'Petit-Déjeuner';
                                                } else if (columnMealRow
                                                        ?.mealType ==
                                                    'lunch') {
                                                  return 'Déjeuner';
                                                } else if (columnMealRow
                                                        ?.mealType ==
                                                    'dinner') {
                                                  return 'Dîner';
                                                } else {
                                                  return 'Collation';
                                                }
                                              }(),
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
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryText,
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
                                              dateTimeFormat(
                                                "MMMMEEEEd",
                                                columnMealRow!.mealDate!,
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
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                Divider(
                  thickness: 2.0,
                  color: FlutterFlowTheme.of(context).alternate,
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Builder(
                    builder: (context) {
                      final receipe = FFAppState().receipes.toList();

                      return ListView.separated(
                        padding: EdgeInsets.zero,
                        primary: false,
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        itemCount: receipe.length,
                        separatorBuilder: (_, __) => SizedBox(height: 10.0),
                        itemBuilder: (context, receipeIndex) {
                          final receipeItem = receipe[receipeIndex];
                          return wrapWithModel(
                            model: _model.recipeCardJSONCopyModels.getModel(
                              RecipesStruct.maybeFromMap(receipeItem)!
                                  .id
                                  .toString(),
                              receipeIndex,
                            ),
                            updateCallback: () => safeSetState(() {}),
                            child: RecipeCardJSONCopyWidget(
                              key: Key(
                                'Keyycm_${RecipesStruct.maybeFromMap(receipeItem)!.id.toString()}',
                              ),
                              receipe: receipeItem,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
