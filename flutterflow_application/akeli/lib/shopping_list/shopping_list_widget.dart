import '/auth/firebase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_radio_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'shopping_list_model.dart';
export 'shopping_list_model.dart';

class ShoppingListWidget extends StatefulWidget {
  const ShoppingListWidget({
    super.key,
    required this.shoppingList,
  });

  final ShoppingListRow? shoppingList;

  static String routeName = 'ShoppingList';
  static String routePath = '/shoppingList';

  @override
  State<ShoppingListWidget> createState() => _ShoppingListWidgetState();
}

class _ShoppingListWidgetState extends State<ShoppingListWidget> {
  late ShoppingListModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ShoppingListModel());

    logFirebaseEvent('screen_view',
        parameters: {'screen_name': 'ShoppingList'});
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UsersRow>>(
      future: (_model.requestCompleter4 ??= Completer<List<UsersRow>>()
            ..complete(UsersTable().querySingleRow(
              queryFn: (q) => q.eqOrNull(
                'user_id',
                currentUserUid,
              ),
            )))
          .future,
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: SpinKitDoubleBounce(
                  color: FlutterFlowTheme.of(context).tertiary,
                  size: 50.0,
                ),
              ),
            ),
          );
        }
        List<UsersRow> shoppingListUsersRowList = snapshot.data!;

        final shoppingListUsersRow = shoppingListUsersRowList.isNotEmpty
            ? shoppingListUsersRowList.first
            : null;

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
            appBar: AppBar(
              backgroundColor: FlutterFlowTheme.of(context).primary,
              automaticallyImplyLeading: false,
              leading: FlutterFlowIconButton(
                borderColor: Colors.transparent,
                borderRadius: 30.0,
                borderWidth: 1.0,
                buttonSize: 60.0,
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  size: 30.0,
                ),
                onPressed: () async {
                  logFirebaseEvent('SHOPPING_LIST_arrow_back_ios_rounded_ICN');
                  logFirebaseEvent('IconButton_navigate_back');
                  context.pop();
                },
              ),
              title: Text(
                FFLocalizations.of(context).getText(
                  '3w014cf2' /* Liste de Course */,
                ),
                style: FlutterFlowTheme.of(context).headlineMedium.override(
                      font: GoogleFonts.outfit(
                        fontWeight: FlutterFlowTheme.of(context)
                            .headlineMedium
                            .fontWeight,
                        fontStyle: FlutterFlowTheme.of(context)
                            .headlineMedium
                            .fontStyle,
                      ),
                      color: Colors.white,
                      fontSize: 22.0,
                      letterSpacing: 0.0,
                      fontWeight: FlutterFlowTheme.of(context)
                          .headlineMedium
                          .fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                    ),
              ),
              actions: [],
              centerTitle: true,
              elevation: 2.0,
            ),
            body: SafeArea(
              top: true,
              child: FutureBuilder<List<MealPlanRow>>(
                future: MealPlanTable().querySingleRow(
                  queryFn: (q) => q
                      .eqOrNull(
                        'user_id',
                        shoppingListUsersRow?.id,
                      )
                      .lteOrNull(
                        'start_date',
                        supaSerialize<DateTime>(getCurrentTimestamp),
                      )
                      .gteOrNull(
                        'end_date',
                        supaSerialize<DateTime>(getCurrentTimestamp),
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
                  List<MealPlanRow> columnMealPlanRowList = snapshot.data!;

                  // Return an empty Container when the item does not exist.
                  if (snapshot.data!.isEmpty) {
                    return Container();
                  }
                  final columnMealPlanRow = columnMealPlanRowList.isNotEmpty
                      ? columnMealPlanRowList.first
                      : null;

                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Align(
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: FlutterFlowRadioButton(
                            options: [
                              FFLocalizations.of(context).getText(
                                'iqpr359j' /* Tous */,
                              ),
                              FFLocalizations.of(context).getText(
                                '1tp8i2rp' /* Déjà acheté */,
                              ),
                              FFLocalizations.of(context).getText(
                                'ypqzad28' /* Reste à acheter */,
                              )
                            ].toList(),
                            onChanged: (val) async {
                              safeSetState(() {});
                              logFirebaseEvent(
                                  'SHOPPING_LIST_RadioButton_vee5whpq_ON_FO');
                              await Future.wait([
                                Future(() async {
                                  logFirebaseEvent(
                                      'RadioButton_refresh_database_request');
                                  safeSetState(
                                      () => _model.requestCompleter3 = null);
                                  await _model.waitForRequestCompleted3();
                                }),
                                Future(() async {
                                  logFirebaseEvent(
                                      'RadioButton_refresh_database_request');
                                  safeSetState(
                                      () => _model.requestCompleter1 = null);
                                  await _model.waitForRequestCompleted1();
                                }),
                                Future(() async {
                                  logFirebaseEvent(
                                      'RadioButton_refresh_database_request');
                                  safeSetState(
                                      () => _model.requestCompleter2 = null);
                                  await _model.waitForRequestCompleted2();
                                }),
                              ]);
                              logFirebaseEvent(
                                  'RadioButton_refresh_database_request');
                              safeSetState(
                                  () => _model.requestCompleter4 = null);
                              await _model.waitForRequestCompleted4();
                            },
                            controller: _model.radioButtonValueController ??=
                                FormFieldController<String>(
                                    FFLocalizations.of(context).getText(
                              'q99p94rw' /* Tous */,
                            )),
                            optionHeight: 32.0,
                            textStyle: FlutterFlowTheme.of(context)
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
                            selectedTextStyle:
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
                            buttonPosition: RadioButtonPosition.left,
                            direction: Axis.horizontal,
                            radioButtonColor:
                                FlutterFlowTheme.of(context).primary,
                            inactiveRadioButtonColor:
                                FlutterFlowTheme.of(context).secondaryText,
                            toggleable: false,
                            horizontalAlignment: WrapAlignment.start,
                            verticalAlignment: WrapCrossAlignment.start,
                          ),
                        ),
                        FutureBuilder<List<ShoppingListRow>>(
                          future: ShoppingListTable().querySingleRow(
                            queryFn: (q) => q.eqOrNull(
                              'meal_plan_id',
                              columnMealPlanRow?.id,
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
                            List<ShoppingListRow> containerShoppingListRowList =
                                snapshot.data!;

                            // Return an empty Container when the item does not exist.
                            if (snapshot.data!.isEmpty) {
                              return Container();
                            }
                            final containerShoppingListRow =
                                containerShoppingListRowList.isNotEmpty
                                    ? containerShoppingListRowList.first
                                    : null;

                            return Container(
                              decoration: BoxDecoration(),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  if (_model.radioButtonValue == 'Tous')
                                    FutureBuilder<List<ShoppingIngredientRow>>(
                                      future: (_model.requestCompleter3 ??=
                                              Completer<
                                                  List<ShoppingIngredientRow>>()
                                                ..complete(
                                                    ShoppingIngredientTable()
                                                        .queryRows(
                                                  queryFn: (q) => q.eqOrNull(
                                                    'shopping_list_id',
                                                    containerShoppingListRow
                                                        ?.id,
                                                  ),
                                                )))
                                          .future,
                                      builder: (context, snapshot) {
                                        // Customize what your widget looks like when it's loading.
                                        if (!snapshot.hasData) {
                                          return Center(
                                            child: SizedBox(
                                              width: 50.0,
                                              height: 50.0,
                                              child: SpinKitDoubleBounce(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .tertiary,
                                                size: 50.0,
                                              ),
                                            ),
                                          );
                                        }
                                        List<ShoppingIngredientRow>
                                            tousContainerShoppingIngredientRowList =
                                            snapshot.data!;

                                        return Container(
                                          decoration: BoxDecoration(),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                      'qvp74ehc' /* Nombre d'ingredient total */,
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .headlineSmall
                                                        .override(
                                                          font: GoogleFonts
                                                              .outfit(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .headlineSmall
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .headlineSmall
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondary,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .headlineSmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .headlineSmall
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                  Text(
                                                    valueOrDefault<String>(
                                                      tousContainerShoppingIngredientRowList
                                                          .length
                                                          .toString(),
                                                      '0',
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .headlineSmall
                                                        .override(
                                                          font: GoogleFonts
                                                              .outfit(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .headlineSmall
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .headlineSmall
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondary,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .headlineSmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .headlineSmall
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ].divide(SizedBox(width: 5.0)),
                                              ),
                                              if (_model.radioButtonValue ==
                                                  'Tous')
                                                Builder(
                                                  builder: (context) {
                                                    final tousContainerVar =
                                                        tousContainerShoppingIngredientRowList
                                                            .toList();

                                                    return ListView.separated(
                                                      padding: EdgeInsets.zero,
                                                      primary: false,
                                                      shrinkWrap: true,
                                                      scrollDirection:
                                                          Axis.vertical,
                                                      itemCount:
                                                          tousContainerVar
                                                              .length,
                                                      separatorBuilder: (_,
                                                              __) =>
                                                          SizedBox(height: 5.0),
                                                      itemBuilder: (context,
                                                          tousContainerVarIndex) {
                                                        final tousContainerVarItem =
                                                            tousContainerVar[
                                                                tousContainerVarIndex];
                                                        return Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      5.0,
                                                                      0.0,
                                                                      5.0,
                                                                      0.0),
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .secondaryBackground,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12.0),
                                                              border:
                                                                  Border.all(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .alternate,
                                                              ),
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          5.0,
                                                                          0.0,
                                                                          5.0),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Expanded(
                                                                    child:
                                                                        Container(
                                                                      width:
                                                                          200.0,
                                                                      decoration:
                                                                          BoxDecoration(),
                                                                      child:
                                                                          Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        children:
                                                                            [
                                                                          if ((tousContainerVarItem.quantity != null) &&
                                                                              (tousContainerVarItem.quantity != 0.0))
                                                                            Text(
                                                                              valueOrDefault<String>(
                                                                                functions.formatIngredientQuantity(tousContainerVarItem.quantity, tousContainerVarItem.unit),
                                                                                '1 g',
                                                                              ),
                                                                              style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                    font: GoogleFonts.poppins(
                                                                                      fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                      fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                    ),
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                    fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                  ),
                                                                            ),
                                                                          Text(
                                                                            valueOrDefault<String>(
                                                                              tousContainerVarItem.name,
                                                                              'name',
                                                                            ),
                                                                            style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                  font: GoogleFonts.poppins(
                                                                                    fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                    fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                  ),
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                ),
                                                                          ),
                                                                        ].divide(SizedBox(width: 5.0)),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    children: [
                                                                      if (tousContainerVarItem
                                                                              .bought ==
                                                                          true)
                                                                        InkWell(
                                                                          splashColor:
                                                                              Colors.transparent,
                                                                          focusColor:
                                                                              Colors.transparent,
                                                                          hoverColor:
                                                                              Colors.transparent,
                                                                          highlightColor:
                                                                              Colors.transparent,
                                                                          onTap:
                                                                              () async {
                                                                            logFirebaseEvent('SHOPPING_LIST_PAGE_Icon_sys6rlkw_ON_TAP');
                                                                            logFirebaseEvent('Icon_backend_call');
                                                                            await ShoppingIngredientTable().update(
                                                                              data: {
                                                                                'bought': false,
                                                                              },
                                                                              matchingRows: (rows) => rows.eqOrNull(
                                                                                'id',
                                                                                tousContainerVarItem.id,
                                                                              ),
                                                                            );
                                                                            logFirebaseEvent('Icon_refresh_database_request');
                                                                            safeSetState(() =>
                                                                                _model.requestCompleter3 = null);
                                                                            await _model.waitForRequestCompleted3();
                                                                            logFirebaseEvent('Icon_refresh_database_request');
                                                                            safeSetState(() =>
                                                                                _model.requestCompleter4 = null);
                                                                            await _model.waitForRequestCompleted4();
                                                                          },
                                                                          child:
                                                                              Icon(
                                                                            Icons.check_box,
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primary,
                                                                            size:
                                                                                24.0,
                                                                          ),
                                                                        ),
                                                                      if (tousContainerVarItem
                                                                              .bought ==
                                                                          false)
                                                                        InkWell(
                                                                          splashColor:
                                                                              Colors.transparent,
                                                                          focusColor:
                                                                              Colors.transparent,
                                                                          hoverColor:
                                                                              Colors.transparent,
                                                                          highlightColor:
                                                                              Colors.transparent,
                                                                          onTap:
                                                                              () async {
                                                                            logFirebaseEvent('SHOPPING_LIST_PAGE_Icon_fgm7cul3_ON_TAP');
                                                                            logFirebaseEvent('Icon_backend_call');
                                                                            await ShoppingIngredientTable().update(
                                                                              data: {
                                                                                'bought': true,
                                                                              },
                                                                              matchingRows: (rows) => rows.eqOrNull(
                                                                                'id',
                                                                                tousContainerVarItem.id,
                                                                              ),
                                                                            );
                                                                            logFirebaseEvent('Icon_refresh_database_request');
                                                                            safeSetState(() =>
                                                                                _model.requestCompleter3 = null);
                                                                            await _model.waitForRequestCompleted3();
                                                                            logFirebaseEvent('Icon_refresh_database_request');
                                                                            safeSetState(() =>
                                                                                _model.requestCompleter4 = null);
                                                                            await _model.waitForRequestCompleted4();
                                                                          },
                                                                          child:
                                                                              Icon(
                                                                            Icons.check_box_outline_blank,
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primary,
                                                                            size:
                                                                                24.0,
                                                                          ),
                                                                        ),
                                                                    ],
                                                                  ),
                                                                ]
                                                                    .divide(SizedBox(
                                                                        width:
                                                                            10.0))
                                                                    .addToStart(
                                                                        SizedBox(
                                                                            width:
                                                                                5.0))
                                                                    .addToEnd(
                                                                        SizedBox(
                                                                            width:
                                                                                5.0)),
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                ),
                                            ].divide(SizedBox(height: 30.0)),
                                          ),
                                        );
                                      },
                                    ),
                                  if (_model.radioButtonValue == 'Déjà acheté')
                                    FutureBuilder<List<ShoppingIngredientRow>>(
                                      future: (_model.requestCompleter1 ??=
                                              Completer<
                                                  List<ShoppingIngredientRow>>()
                                                ..complete(
                                                    ShoppingIngredientTable()
                                                        .queryRows(
                                                  queryFn: (q) => q
                                                      .eqOrNull(
                                                        'shopping_list_id',
                                                        containerShoppingListRow
                                                            ?.id,
                                                      )
                                                      .eqOrNull(
                                                        'bought',
                                                        true,
                                                      ),
                                                )))
                                          .future,
                                      builder: (context, snapshot) {
                                        // Customize what your widget looks like when it's loading.
                                        if (!snapshot.hasData) {
                                          return Center(
                                            child: SizedBox(
                                              width: 50.0,
                                              height: 50.0,
                                              child: SpinKitDoubleBounce(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .tertiary,
                                                size: 50.0,
                                              ),
                                            ),
                                          );
                                        }
                                        List<ShoppingIngredientRow>
                                            acheteContainerShoppingIngredientRowList =
                                            snapshot.data!;

                                        return Container(
                                          decoration: BoxDecoration(),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        0.0, 0.0, 0.0, 30.0),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    if (_model
                                                            .radioButtonValue ==
                                                        'Déjà acheté')
                                                      Text(
                                                        FFLocalizations.of(
                                                                context)
                                                            .getText(
                                                          'lk9n5hwd' /* Nombre d'ingredient acheté */,
                                                        ),
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .headlineSmall
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .outfit(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .headlineSmall
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .headlineSmall
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondary,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .headlineSmall
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .headlineSmall
                                                                      .fontStyle,
                                                                ),
                                                      ),
                                                    Text(
                                                      valueOrDefault<String>(
                                                        acheteContainerShoppingIngredientRowList
                                                            .length
                                                            .toString(),
                                                        '0',
                                                      ),
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .headlineSmall
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .headlineSmall
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .headlineSmall
                                                                      .fontStyle,
                                                                ),
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondary,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .headlineSmall
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .headlineSmall
                                                                    .fontStyle,
                                                              ),
                                                    ),
                                                  ].divide(
                                                      SizedBox(width: 5.0)),
                                                ),
                                              ),
                                              Builder(
                                                builder: (context) {
                                                  final acheteContainerVar =
                                                      acheteContainerShoppingIngredientRowList
                                                          .toList();

                                                  return ListView.separated(
                                                    padding: EdgeInsets.zero,
                                                    primary: false,
                                                    shrinkWrap: true,
                                                    scrollDirection:
                                                        Axis.vertical,
                                                    itemCount:
                                                        acheteContainerVar
                                                            .length,
                                                    separatorBuilder: (_, __) =>
                                                        SizedBox(height: 5.0),
                                                    itemBuilder: (context,
                                                        acheteContainerVarIndex) {
                                                      final acheteContainerVarItem =
                                                          acheteContainerVar[
                                                              acheteContainerVarIndex];
                                                      return Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    5.0,
                                                                    0.0,
                                                                    5.0,
                                                                    0.0),
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .secondaryBackground,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                            border: Border.all(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .alternate,
                                                            ),
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        5.0,
                                                                        0.0,
                                                                        5.0),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Expanded(
                                                                  child:
                                                                      Container(
                                                                    width:
                                                                        200.0,
                                                                    decoration:
                                                                        BoxDecoration(),
                                                                    child: Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      children:
                                                                          [
                                                                        if ((acheteContainerVarItem.quantity !=
                                                                                null) &&
                                                                            (acheteContainerVarItem.quantity !=
                                                                                0.0))
                                                                          Text(
                                                                            valueOrDefault<String>(
                                                                              functions.formatIngredientQuantity(acheteContainerVarItem.quantity, acheteContainerVarItem.unit),
                                                                              '1 g',
                                                                            ),
                                                                            style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                  font: GoogleFonts.poppins(
                                                                                    fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                    fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                  ),
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                ),
                                                                          ),
                                                                        Text(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            acheteContainerVarItem.name,
                                                                            'name',
                                                                          ),
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .labelMedium
                                                                              .override(
                                                                                font: GoogleFonts.poppins(
                                                                                  fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                ),
                                                                                letterSpacing: 0.0,
                                                                                fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                              ),
                                                                        ),
                                                                      ].divide(SizedBox(
                                                                              width: 5.0)),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    if (acheteContainerVarItem
                                                                            .bought ==
                                                                        true)
                                                                      InkWell(
                                                                        splashColor:
                                                                            Colors.transparent,
                                                                        focusColor:
                                                                            Colors.transparent,
                                                                        hoverColor:
                                                                            Colors.transparent,
                                                                        highlightColor:
                                                                            Colors.transparent,
                                                                        onTap:
                                                                            () async {
                                                                          logFirebaseEvent(
                                                                              'SHOPPING_LIST_PAGE_Icon_gmnco8az_ON_TAP');
                                                                          logFirebaseEvent(
                                                                              'Icon_backend_call');
                                                                          await ShoppingIngredientTable()
                                                                              .update(
                                                                            data: {
                                                                              'bought': false,
                                                                            },
                                                                            matchingRows: (rows) =>
                                                                                rows.eqOrNull(
                                                                              'id',
                                                                              acheteContainerVarItem.id,
                                                                            ),
                                                                          );
                                                                          logFirebaseEvent(
                                                                              'Icon_refresh_database_request');
                                                                          safeSetState(() =>
                                                                              _model.requestCompleter1 = null);
                                                                          await _model
                                                                              .waitForRequestCompleted1();
                                                                          logFirebaseEvent(
                                                                              'Icon_refresh_database_request');
                                                                          safeSetState(() =>
                                                                              _model.requestCompleter4 = null);
                                                                          await _model
                                                                              .waitForRequestCompleted4();
                                                                        },
                                                                        child:
                                                                            Icon(
                                                                          Icons
                                                                              .check_box,
                                                                          color:
                                                                              FlutterFlowTheme.of(context).primary,
                                                                          size:
                                                                              24.0,
                                                                        ),
                                                                      ),
                                                                    if (acheteContainerVarItem
                                                                            .bought ==
                                                                        false)
                                                                      InkWell(
                                                                        splashColor:
                                                                            Colors.transparent,
                                                                        focusColor:
                                                                            Colors.transparent,
                                                                        hoverColor:
                                                                            Colors.transparent,
                                                                        highlightColor:
                                                                            Colors.transparent,
                                                                        onTap:
                                                                            () async {
                                                                          logFirebaseEvent(
                                                                              'SHOPPING_LIST_PAGE_Icon_421xwcjq_ON_TAP');
                                                                          logFirebaseEvent(
                                                                              'Icon_backend_call');
                                                                          await ShoppingIngredientTable()
                                                                              .update(
                                                                            data: {
                                                                              'bought': true,
                                                                            },
                                                                            matchingRows: (rows) =>
                                                                                rows.eqOrNull(
                                                                              'id',
                                                                              acheteContainerVarItem.id,
                                                                            ),
                                                                          );
                                                                          logFirebaseEvent(
                                                                              'Icon_refresh_database_request');
                                                                          safeSetState(() =>
                                                                              _model.requestCompleter3 = null);
                                                                          await _model
                                                                              .waitForRequestCompleted3();
                                                                          logFirebaseEvent(
                                                                              'Icon_refresh_database_request');
                                                                          safeSetState(() =>
                                                                              _model.requestCompleter4 = null);
                                                                          await _model
                                                                              .waitForRequestCompleted4();
                                                                        },
                                                                        child:
                                                                            Icon(
                                                                          Icons
                                                                              .check_box_outline_blank,
                                                                          color:
                                                                              FlutterFlowTheme.of(context).primary,
                                                                          size:
                                                                              24.0,
                                                                        ),
                                                                      ),
                                                                  ],
                                                                ),
                                                              ]
                                                                  .divide(SizedBox(
                                                                      width:
                                                                          10.0))
                                                                  .addToStart(
                                                                      SizedBox(
                                                                          width:
                                                                              5.0))
                                                                  .addToEnd(
                                                                      SizedBox(
                                                                          width:
                                                                              5.0)),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  if (_model.radioButtonValue ==
                                      'Reste à acheter')
                                    FutureBuilder<List<ShoppingIngredientRow>>(
                                      future: (_model.requestCompleter2 ??=
                                              Completer<
                                                  List<ShoppingIngredientRow>>()
                                                ..complete(
                                                    ShoppingIngredientTable()
                                                        .queryRows(
                                                  queryFn: (q) => q
                                                      .eqOrNull(
                                                        'shopping_list_id',
                                                        containerShoppingListRow
                                                            ?.id,
                                                      )
                                                      .eqOrNull(
                                                        'bought',
                                                        false,
                                                      ),
                                                )))
                                          .future,
                                      builder: (context, snapshot) {
                                        // Customize what your widget looks like when it's loading.
                                        if (!snapshot.hasData) {
                                          return Center(
                                            child: SizedBox(
                                              width: 50.0,
                                              height: 50.0,
                                              child: SpinKitDoubleBounce(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .tertiary,
                                                size: 50.0,
                                              ),
                                            ),
                                          );
                                        }
                                        List<ShoppingIngredientRow>
                                            restantContainerShoppingIngredientRowList =
                                            snapshot.data!;

                                        return Container(
                                          decoration: BoxDecoration(),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        0.0, 0.0, 0.0, 30.0),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'f5leufvi' /* Nombre d'ingredient restant */,
                                                      ),
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .headlineSmall
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .headlineSmall
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .headlineSmall
                                                                      .fontStyle,
                                                                ),
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondary,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .headlineSmall
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .headlineSmall
                                                                    .fontStyle,
                                                              ),
                                                    ),
                                                    Text(
                                                      valueOrDefault<String>(
                                                        restantContainerShoppingIngredientRowList
                                                            .length
                                                            .toString(),
                                                        '0',
                                                      ),
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .headlineSmall
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .headlineSmall
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .headlineSmall
                                                                      .fontStyle,
                                                                ),
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondary,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .headlineSmall
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .headlineSmall
                                                                    .fontStyle,
                                                              ),
                                                    ),
                                                  ].divide(
                                                      SizedBox(width: 5.0)),
                                                ),
                                              ),
                                              Builder(
                                                builder: (context) {
                                                  final restantContainerVar =
                                                      restantContainerShoppingIngredientRowList
                                                          .toList();

                                                  return ListView.separated(
                                                    padding: EdgeInsets.zero,
                                                    primary: false,
                                                    shrinkWrap: true,
                                                    scrollDirection:
                                                        Axis.vertical,
                                                    itemCount:
                                                        restantContainerVar
                                                            .length,
                                                    separatorBuilder: (_, __) =>
                                                        SizedBox(height: 5.0),
                                                    itemBuilder: (context,
                                                        restantContainerVarIndex) {
                                                      final restantContainerVarItem =
                                                          restantContainerVar[
                                                              restantContainerVarIndex];
                                                      return Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    5.0,
                                                                    0.0,
                                                                    5.0,
                                                                    0.0),
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .secondaryBackground,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                            border: Border.all(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .alternate,
                                                            ),
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        5.0,
                                                                        0.0,
                                                                        5.0),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Expanded(
                                                                  child:
                                                                      Container(
                                                                    width:
                                                                        200.0,
                                                                    decoration:
                                                                        BoxDecoration(),
                                                                    child: Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      children:
                                                                          [
                                                                        if ((restantContainerVarItem.quantity !=
                                                                                null) &&
                                                                            (restantContainerVarItem.quantity !=
                                                                                0.0))
                                                                          Text(
                                                                            valueOrDefault<String>(
                                                                              functions.formatIngredientQuantity(restantContainerVarItem.quantity, restantContainerVarItem.unit),
                                                                              '1 g',
                                                                            ),
                                                                            style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                  font: GoogleFonts.poppins(
                                                                                    fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                    fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                  ),
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                ),
                                                                          ),
                                                                        Text(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            restantContainerVarItem.name,
                                                                            'name',
                                                                          ),
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .labelMedium
                                                                              .override(
                                                                                font: GoogleFonts.poppins(
                                                                                  fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                ),
                                                                                letterSpacing: 0.0,
                                                                                fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                              ),
                                                                        ),
                                                                      ].divide(SizedBox(
                                                                              width: 5.0)),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    if (restantContainerVarItem
                                                                            .bought ==
                                                                        true)
                                                                      InkWell(
                                                                        splashColor:
                                                                            Colors.transparent,
                                                                        focusColor:
                                                                            Colors.transparent,
                                                                        hoverColor:
                                                                            Colors.transparent,
                                                                        highlightColor:
                                                                            Colors.transparent,
                                                                        onTap:
                                                                            () async {
                                                                          logFirebaseEvent(
                                                                              'SHOPPING_LIST_PAGE_Icon_kmy2ysby_ON_TAP');
                                                                          logFirebaseEvent(
                                                                              'Icon_backend_call');
                                                                          await ShoppingIngredientTable()
                                                                              .update(
                                                                            data: {
                                                                              'bought': false,
                                                                            },
                                                                            matchingRows: (rows) =>
                                                                                rows.eqOrNull(
                                                                              'id',
                                                                              restantContainerVarItem.id,
                                                                            ),
                                                                          );
                                                                          logFirebaseEvent(
                                                                              'Icon_refresh_database_request');
                                                                          safeSetState(() =>
                                                                              _model.requestCompleter2 = null);
                                                                          await _model
                                                                              .waitForRequestCompleted2();
                                                                          logFirebaseEvent(
                                                                              'Icon_refresh_database_request');
                                                                          safeSetState(() =>
                                                                              _model.requestCompleter4 = null);
                                                                          await _model
                                                                              .waitForRequestCompleted4();
                                                                        },
                                                                        child:
                                                                            Icon(
                                                                          Icons
                                                                              .check_box,
                                                                          color:
                                                                              FlutterFlowTheme.of(context).primary,
                                                                          size:
                                                                              24.0,
                                                                        ),
                                                                      ),
                                                                    if (restantContainerVarItem
                                                                            .bought ==
                                                                        false)
                                                                      InkWell(
                                                                        splashColor:
                                                                            Colors.transparent,
                                                                        focusColor:
                                                                            Colors.transparent,
                                                                        hoverColor:
                                                                            Colors.transparent,
                                                                        highlightColor:
                                                                            Colors.transparent,
                                                                        onTap:
                                                                            () async {
                                                                          logFirebaseEvent(
                                                                              'SHOPPING_LIST_PAGE_Icon_dungdnm6_ON_TAP');
                                                                          logFirebaseEvent(
                                                                              'Icon_backend_call');
                                                                          await ShoppingIngredientTable()
                                                                              .update(
                                                                            data: {
                                                                              'bought': true,
                                                                            },
                                                                            matchingRows: (rows) =>
                                                                                rows.eqOrNull(
                                                                              'id',
                                                                              restantContainerVarItem.id,
                                                                            ),
                                                                          );
                                                                          logFirebaseEvent(
                                                                              'Icon_refresh_database_request');
                                                                          safeSetState(() =>
                                                                              _model.requestCompleter2 = null);
                                                                          await _model
                                                                              .waitForRequestCompleted2();
                                                                          logFirebaseEvent(
                                                                              'Icon_refresh_database_request');
                                                                          safeSetState(() =>
                                                                              _model.requestCompleter4 = null);
                                                                          await _model
                                                                              .waitForRequestCompleted4();
                                                                        },
                                                                        child:
                                                                            Icon(
                                                                          Icons
                                                                              .check_box_outline_blank,
                                                                          color:
                                                                              FlutterFlowTheme.of(context).primary,
                                                                          size:
                                                                              24.0,
                                                                        ),
                                                                      ),
                                                                  ],
                                                                ),
                                                              ]
                                                                  .divide(SizedBox(
                                                                      width:
                                                                          10.0))
                                                                  .addToStart(
                                                                      SizedBox(
                                                                          width:
                                                                              5.0))
                                                                  .addToEnd(
                                                                      SizedBox(
                                                                          width:
                                                                              5.0)),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ]
                          .divide(SizedBox(height: 30.0))
                          .addToStart(SizedBox(height: 40.0))
                          .addToEnd(SizedBox(height: 20.0)),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
