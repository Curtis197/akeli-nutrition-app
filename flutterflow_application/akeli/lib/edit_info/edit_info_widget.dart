import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/components/textfield_widget.dart';
import '/diet_plan/diet_plan_error/diet_plan_error_widget.dart';
import '/flutter_flow/flutter_flow_checkbox_group.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/backend/schema/structs/index.dart';
import '/index.dart';
import 'dart:async';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'edit_info_model.dart';
export 'edit_info_model.dart';

class EditInfoWidget extends StatefulWidget {
  const EditInfoWidget({super.key});

  static String routeName = 'EditInfo';
  static String routePath = '/editInfo';

  @override
  State<EditInfoWidget> createState() => _EditInfoWidgetState();
}

class _EditInfoWidgetState extends State<EditInfoWidget> {
  late EditInfoModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EditInfoModel());

    logFirebaseEvent('screen_view', parameters: {'screen_name': 'EditInfo'});
    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      logFirebaseEvent('EDIT_INFO_PAGE_EditInfo_ON_INIT_STATE');
      logFirebaseEvent('EditInfo_backend_call');
      _model.userGoal = await UserGoalTable().queryRows(
        queryFn: (q) => q.eqOrNull(
          'user_id',
          valueOrDefault(currentUserDocument?.id, 0),
        ),
      );
      if (_model.userGoal != null && (_model.userGoal)!.isNotEmpty) {
        logFirebaseEvent('EditInfo_update_page_state');
        _model.dailyCal = _model.userGoal?.firstOrNull?.targetCalorie;
        safeSetState(() {});
      } else {
        logFirebaseEvent('EditInfo_update_page_state');
        _model.dailyCal = 0.0;
        safeSetState(() {});
      }

      logFirebaseEvent('EditInfo_update_page_state');
      _model.totalCal = (_model.breakfastCalTextController.text != null &&
                  _model.breakfastCalTextController.text != ''
              ? double.parse(_model.breakfastCalTextController.text)
              : 0.0) +
          (_model.lunchCalTextController.text != null &&
                  _model.lunchCalTextController.text != ''
              ? double.parse(_model.lunchCalTextController.text)
              : 0.0) +
          (_model.dinerCalTextController.text != null &&
                  _model.dinerCalTextController.text != ''
              ? double.parse(_model.dinerCalTextController.text)
              : 0.0) +
          (_model.snackCalTextController.text != null &&
                  _model.snackCalTextController.text != ''
              ? double.parse(_model.snackCalTextController.text)
              : 0.0);
      safeSetState(() {});
    });

    _model.ageFocusNode1 ??= FocusNode();

    _model.ageFocusNode2 ??= FocusNode();

    _model.weightFocusNode1 ??= FocusNode();

    _model.weightFocusNode2 ??= FocusNode();

    _model.heightFocusNode1 ??= FocusNode();

    _model.heightFocusNode2 ??= FocusNode();

    _model.textController7 ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    _model.particularDietFocusNode ??= FocusNode();

    _model.targetWeightFocusNode1 ??= FocusNode();

    _model.targetWeightFocusNode2 ??= FocusNode();

    _model.objectifFocusNode1 ??= FocusNode();

    _model.objectifFocusNode2 ??= FocusNode();

    _model.dailyCalFocusNode ??= FocusNode();

    _model.breakfastCalFocusNode ??= FocusNode();

    _model.lunchCalFocusNode ??= FocusNode();

    _model.dinerCalFocusNode ??= FocusNode();

    _model.snackCalFocusNode ??= FocusNode();

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

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        automaticallyImplyLeading: false,
        leading: FlutterFlowIconButton(
          borderColor: Colors.transparent,
          borderRadius: 30.0,
          borderWidth: 1.0,
          buttonSize: 40.0,
          icon: Icon(
            Icons.arrow_back_rounded,
            color: FlutterFlowTheme.of(context).primary,
            size: 30.0,
          ),
          onPressed: () async {
            logFirebaseEvent('EDIT_INFO_arrow_back_rounded_ICN_ON_TAP');
            logFirebaseEvent('IconButton_navigate_back');
            context.pop();
          },
        ),
        actions: [],
        centerTitle: false,
        elevation: 0.0,
      ),
      body: SafeArea(
        top: true,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 50.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        FFLocalizations.of(context).getText(
                          '0nub1fzs' /* Modifier vos informations */,
                        ),
                        style:
                            FlutterFlowTheme.of(context).headlineLarge.override(
                                  font: GoogleFonts.outfit(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .headlineLarge
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .headlineLarge
                                        .fontStyle,
                                  ),
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .headlineLarge
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineLarge
                                      .fontStyle,
                                ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(25.0, 0.0, 25.0, 0.0),
                  child: AuthUserStreamWidget(
                    builder: (context) =>
                        FutureBuilder<List<UserHealthParameterRow>>(
                      future: (_model.requestCompleter2 ??=
                              Completer<List<UserHealthParameterRow>>()
                                ..complete(
                                    UserHealthParameterTable().querySingleRow(
                                  queryFn: (q) => q.eqOrNull(
                                    'user_id',
                                    valueOrDefault(currentUserDocument?.id, 0),
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
                                color: FlutterFlowTheme.of(context).tertiary,
                                size: 50.0,
                              ),
                            ),
                          );
                        }
                        List<UserHealthParameterRow>
                            healthParameterUserHealthParameterRowList =
                            snapshot.data!;

                        final healthParameterUserHealthParameterRow =
                            healthParameterUserHealthParameterRowList.isNotEmpty
                                ? healthParameterUserHealthParameterRowList
                                    .first
                                : null;

                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color:
                                FlutterFlowTheme.of(context).primaryBackground,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      FFLocalizations.of(context).getText(
                                        'iehln0m4' /* Vos paramètre */,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .titleLarge
                                          .override(
                                            font: GoogleFonts.outfit(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .titleLarge
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleLarge
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleLarge
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleLarge
                                                    .fontStyle,
                                          ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.face_sharp,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      size: 24.0,
                                    ),
                                    Text(
                                      FFLocalizations.of(context).getText(
                                        'couux0mt' /* Votre Âge */,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            font: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ].divide(SizedBox(width: 5.0)),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    if (FFAppState()
                                        .missingField
                                        .contains(FFAppState().age))
                                      Container(
                                        width: 250.0,
                                        child: TextFormField(
                                          controller:
                                              _model.ageTextController1 ??=
                                                  TextEditingController(
                                            text: healthParameterUserHealthParameterRow
                                                        ?.age !=
                                                    null
                                                ? healthParameterUserHealthParameterRow
                                                    ?.age
                                                    ?.toString()
                                                : '',
                                          ),
                                          focusNode: _model.ageFocusNode1,
                                          autofocus: false,
                                          obscureText: false,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            labelStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.poppins(
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
                                            hintText:
                                                healthParameterUserHealthParameterRow
                                                            ?.age !=
                                                        null
                                                    ? ''
                                                    : 'Quel âge avez vous ? ',
                                            hintStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.poppins(
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
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .error,
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
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            filled: true,
                                            fillColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.poppins(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                          cursorColor:
                                              FlutterFlowTheme.of(context)
                                                  .primaryText,
                                          enableInteractiveSelection: true,
                                          validator: _model
                                              .ageTextController1Validator
                                              .asValidator(context),
                                        ),
                                      ),
                                    if (!FFAppState()
                                        .missingField
                                        .contains(FFAppState().age))
                                      Container(
                                        width: 250.0,
                                        child: TextFormField(
                                          controller:
                                              _model.ageTextController2 ??=
                                                  TextEditingController(
                                            text: healthParameterUserHealthParameterRow
                                                        ?.age !=
                                                    null
                                                ? healthParameterUserHealthParameterRow
                                                    ?.age
                                                    ?.toString()
                                                : '',
                                          ),
                                          focusNode: _model.ageFocusNode2,
                                          autofocus: false,
                                          obscureText: false,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            labelStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.poppins(
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
                                            hintText:
                                                healthParameterUserHealthParameterRow
                                                            ?.age !=
                                                        null
                                                    ? ''
                                                    : 'Quel âge avez vous ? ',
                                            hintStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.poppins(
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
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            filled: true,
                                            fillColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.poppins(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                          cursorColor:
                                              FlutterFlowTheme.of(context)
                                                  .primaryText,
                                          enableInteractiveSelection: true,
                                          validator: _model
                                              .ageTextController2Validator
                                              .asValidator(context),
                                        ),
                                      ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.monitor_weight_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      size: 24.0,
                                    ),
                                    Text(
                                      FFLocalizations.of(context).getText(
                                        'noixpe8m' /* Votre poids */,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            font: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ].divide(SizedBox(width: 5.0)),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    if (!FFAppState()
                                        .missingField
                                        .contains(FFAppState().weight))
                                      Container(
                                        decoration: BoxDecoration(),
                                        child: Container(
                                          width: 250.0,
                                          child: TextFormField(
                                            controller:
                                                _model.weightTextController1 ??=
                                                    TextEditingController(
                                              text: healthParameterUserHealthParameterRow
                                                          ?.weight !=
                                                      null
                                                  ? healthParameterUserHealthParameterRow
                                                      ?.weight
                                                      ?.toString()
                                                  : '',
                                            ),
                                            focusNode: _model.weightFocusNode1,
                                            autofocus: false,
                                            obscureText: false,
                                            decoration: InputDecoration(
                                              isDense: true,
                                              labelStyle:
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
                                              hintText:
                                                  healthParameterUserHealthParameterRow
                                                              ?.weight !=
                                                          null
                                                      ? ''
                                                      : 'Quel est votre poids ? ',
                                              hintStyle:
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
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Color(0x00000000),
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Color(0x00000000),
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error,
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              focusedErrorBorder:
                                                  OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error,
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              filled: true,
                                              fillColor:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                            cursorColor:
                                                FlutterFlowTheme.of(context)
                                                    .primaryText,
                                            enableInteractiveSelection: true,
                                            validator: _model
                                                .weightTextController1Validator
                                                .asValidator(context),
                                          ),
                                        ),
                                      ),
                                    if (FFAppState()
                                        .missingField
                                        .contains(FFAppState().weight))
                                      Container(
                                        decoration: BoxDecoration(),
                                        child: Container(
                                          width: 250.0,
                                          child: TextFormField(
                                            controller:
                                                _model.weightTextController2 ??=
                                                    TextEditingController(
                                              text: healthParameterUserHealthParameterRow
                                                          ?.weight !=
                                                      null
                                                  ? healthParameterUserHealthParameterRow
                                                      ?.weight
                                                      ?.toString()
                                                  : '',
                                            ),
                                            focusNode: _model.weightFocusNode2,
                                            autofocus: false,
                                            obscureText: false,
                                            decoration: InputDecoration(
                                              isDense: true,
                                              labelStyle:
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
                                              hintText:
                                                  healthParameterUserHealthParameterRow
                                                              ?.weight !=
                                                          null
                                                      ? ''
                                                      : 'Quel est votre poids ? ',
                                              hintStyle: FlutterFlowTheme.of(
                                                      context)
                                                  .labelMedium
                                                  .override(
                                                    font: GoogleFonts.poppins(
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
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .error,
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
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error,
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Color(0x00000000),
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error,
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              focusedErrorBorder:
                                                  OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error,
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              filled: true,
                                              fillColor:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                            cursorColor:
                                                FlutterFlowTheme.of(context)
                                                    .primaryText,
                                            enableInteractiveSelection: true,
                                            validator: _model
                                                .weightTextController2Validator
                                                .asValidator(context),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.height_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      size: 24.0,
                                    ),
                                    Text(
                                      FFLocalizations.of(context).getText(
                                        'wc2srh20' /* Votre taile */,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            font: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ],
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    if (FFAppState()
                                        .missingField
                                        .contains(FFAppState().height))
                                      Container(
                                        width: 250.0,
                                        child: TextFormField(
                                          controller:
                                              _model.heightTextController1 ??=
                                                  TextEditingController(
                                            text: healthParameterUserHealthParameterRow
                                                        ?.height !=
                                                    null
                                                ? healthParameterUserHealthParameterRow
                                                    ?.height
                                                    ?.toString()
                                                : ' ',
                                          ),
                                          focusNode: _model.heightFocusNode1,
                                          autofocus: false,
                                          obscureText: false,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            labelStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.poppins(
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
                                            hintText:
                                                healthParameterUserHealthParameterRow
                                                            ?.height !=
                                                        null
                                                    ? ''
                                                    : 'Quel est votre taille ? ',
                                            hintStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.poppins(
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
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .error,
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
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            filled: true,
                                            fillColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.poppins(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                          cursorColor:
                                              FlutterFlowTheme.of(context)
                                                  .primaryText,
                                          enableInteractiveSelection: true,
                                          validator: _model
                                              .heightTextController1Validator
                                              .asValidator(context),
                                        ),
                                      ),
                                    if (FFAppState()
                                            .missingField
                                            .contains(FFAppState().height) ==
                                        false)
                                      Container(
                                        width: 250.0,
                                        child: TextFormField(
                                          controller:
                                              _model.heightTextController2 ??=
                                                  TextEditingController(
                                            text: healthParameterUserHealthParameterRow
                                                        ?.height !=
                                                    null
                                                ? healthParameterUserHealthParameterRow
                                                    ?.height
                                                    ?.toString()
                                                : ' ',
                                          ),
                                          focusNode: _model.heightFocusNode2,
                                          autofocus: false,
                                          obscureText: false,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            labelStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.poppins(
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
                                            hintText:
                                                healthParameterUserHealthParameterRow
                                                            ?.height !=
                                                        null
                                                    ? ''
                                                    : 'Quel est votre taille ? ',
                                            hintStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.poppins(
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
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            filled: true,
                                            fillColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.poppins(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                          cursorColor:
                                              FlutterFlowTheme.of(context)
                                                  .primaryText,
                                          enableInteractiveSelection: true,
                                          validator: _model
                                              .heightTextController2Validator
                                              .asValidator(context),
                                        ),
                                      ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.female_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      size: 24.0,
                                    ),
                                    Text(
                                      FFLocalizations.of(context).getText(
                                        'waez8trg' /* Votre sexe */,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            font: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ],
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    if (FFAppState()
                                        .missingField
                                        .contains(FFAppState().sex))
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 10.0, 0.0, 0.0),
                                        child: FlutterFlowDropDown<String>(
                                          controller:
                                              _model.genderValueController1 ??=
                                                  FormFieldController<String>(
                                            _model.genderValue1 ??=
                                                healthParameterUserHealthParameterRow
                                                                ?.sex !=
                                                            null &&
                                                        healthParameterUserHealthParameterRow
                                                                ?.sex !=
                                                            ''
                                                    ? healthParameterUserHealthParameterRow
                                                        ?.sex
                                                    : '',
                                          ),
                                          options: [
                                            FFLocalizations.of(context).getText(
                                              'zk7t3fx4' /* Masculin */,
                                            ),
                                            FFLocalizations.of(context).getText(
                                              'cs2ldnss' /* Feminin */,
                                            )
                                          ],
                                          onChanged: (val) => safeSetState(
                                              () => _model.genderValue1 = val),
                                          width: 250.0,
                                          height: 40.0,
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.poppins(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                          hintText: FFLocalizations.of(context)
                                              .getText(
                                            'tkhpg57o' /* Quel est votre sexe ? */,
                                          ),
                                          icon: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .error,
                                            size: 24.0,
                                          ),
                                          fillColor:
                                              FlutterFlowTheme.of(context)
                                                  .secondaryBackground,
                                          elevation: 2.0,
                                          borderColor:
                                              FlutterFlowTheme.of(context)
                                                  .error,
                                          borderWidth: 0.0,
                                          borderRadius: 8.0,
                                          margin:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  12.0, 0.0, 12.0, 0.0),
                                          hidesUnderline: true,
                                          isOverButton: false,
                                          isSearchable: false,
                                          isMultiSelect: false,
                                        ),
                                      ),
                                    if (!FFAppState()
                                        .missingField
                                        .contains(FFAppState().sex))
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 10.0, 0.0, 0.0),
                                        child: FlutterFlowDropDown<String>(
                                          controller:
                                              _model.genderValueController2 ??=
                                                  FormFieldController<String>(
                                            _model.genderValue2 ??=
                                                healthParameterUserHealthParameterRow
                                                                ?.sex !=
                                                            null &&
                                                        healthParameterUserHealthParameterRow
                                                                ?.sex !=
                                                            ''
                                                    ? healthParameterUserHealthParameterRow
                                                        ?.sex
                                                    : '',
                                          ),
                                          options: [
                                            FFLocalizations.of(context).getText(
                                              'jzpawh2w' /* Masculin */,
                                            ),
                                            FFLocalizations.of(context).getText(
                                              'ud66f5p7' /* Feminin */,
                                            )
                                          ],
                                          onChanged: (val) => safeSetState(
                                              () => _model.genderValue2 = val),
                                          width: 250.0,
                                          height: 40.0,
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.poppins(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                          hintText: FFLocalizations.of(context)
                                              .getText(
                                            'kl4n7ywt' /* Quel est votre sexe ? */,
                                          ),
                                          icon: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            size: 24.0,
                                          ),
                                          fillColor:
                                              FlutterFlowTheme.of(context)
                                                  .secondaryBackground,
                                          elevation: 2.0,
                                          borderColor: Colors.transparent,
                                          borderWidth: 0.0,
                                          borderRadius: 8.0,
                                          margin:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  12.0, 0.0, 12.0, 0.0),
                                          hidesUnderline: true,
                                          isOverButton: false,
                                          isSearchable: false,
                                          isMultiSelect: false,
                                        ),
                                      ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.fitness_center_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      size: 24.0,
                                    ),
                                    Text(
                                      FFLocalizations.of(context).getText(
                                        't5qc6nkv' /* Votre activité */,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            font: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ],
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    if (FFAppState()
                                        .missingField
                                        .contains(FFAppState().activityLevels))
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 10.0, 0.0, 0.0),
                                        child: FlutterFlowDropDown<String>(
                                          controller: _model
                                                  .activityLevelValueController1 ??=
                                              FormFieldController<String>(
                                            _model.activityLevelValue1 ??=
                                                healthParameterUserHealthParameterRow
                                                                ?.activityLevel !=
                                                            null &&
                                                        healthParameterUserHealthParameterRow
                                                                ?.activityLevel !=
                                                            ''
                                                    ? healthParameterUserHealthParameterRow
                                                        ?.activityLevel
                                                    : '',
                                          ),
                                          options: [
                                            FFLocalizations.of(context).getText(
                                              'kdx4xn61' /* Faible */,
                                            ),
                                            FFLocalizations.of(context).getText(
                                              '7do46t8z' /* Moderé */,
                                            ),
                                            FFLocalizations.of(context).getText(
                                              '63ao1gst' /* Elevé */,
                                            )
                                          ],
                                          onChanged: (val) => safeSetState(() =>
                                              _model.activityLevelValue1 = val),
                                          width: 250.0,
                                          height: 60.0,
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.poppins(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                          hintText: FFLocalizations.of(context)
                                              .getText(
                                            '78h8vdpz' /* Quelle est votre niveau d'acti... */,
                                          ),
                                          icon: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .error,
                                            size: 24.0,
                                          ),
                                          fillColor:
                                              FlutterFlowTheme.of(context)
                                                  .secondaryBackground,
                                          elevation: 2.0,
                                          borderColor:
                                              FlutterFlowTheme.of(context)
                                                  .error,
                                          borderWidth: 0.0,
                                          borderRadius: 8.0,
                                          margin:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  12.0, 0.0, 12.0, 0.0),
                                          hidesUnderline: true,
                                          isOverButton: false,
                                          isSearchable: false,
                                          isMultiSelect: false,
                                        ),
                                      ),
                                    if (!FFAppState()
                                        .missingField
                                        .contains(FFAppState().activityLevels))
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 10.0, 0.0, 0.0),
                                        child: FlutterFlowDropDown<String>(
                                          controller: _model
                                                  .activityLevelValueController2 ??=
                                              FormFieldController<String>(
                                            _model.activityLevelValue2 ??=
                                                healthParameterUserHealthParameterRow
                                                                ?.activityLevel !=
                                                            null &&
                                                        healthParameterUserHealthParameterRow
                                                                ?.activityLevel !=
                                                            ''
                                                    ? healthParameterUserHealthParameterRow
                                                        ?.activityLevel
                                                    : '',
                                          ),
                                          options: [
                                            FFLocalizations.of(context).getText(
                                              'bjwtrglp' /* Faible */,
                                            ),
                                            FFLocalizations.of(context).getText(
                                              '1parq5ox' /* Moderé */,
                                            ),
                                            FFLocalizations.of(context).getText(
                                              '0g0iri6x' /* Elevé */,
                                            )
                                          ],
                                          onChanged: (val) => safeSetState(() =>
                                              _model.activityLevelValue2 = val),
                                          width: 250.0,
                                          height: 60.0,
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.poppins(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                          hintText: FFLocalizations.of(context)
                                              .getText(
                                            'ulam7zoo' /* Quelle est votre niveau d'acti... */,
                                          ),
                                          icon: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            size: 24.0,
                                          ),
                                          fillColor:
                                              FlutterFlowTheme.of(context)
                                                  .secondaryBackground,
                                          elevation: 2.0,
                                          borderColor: Colors.transparent,
                                          borderWidth: 0.0,
                                          borderRadius: 8.0,
                                          margin:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  12.0, 0.0, 12.0, 0.0),
                                          hidesUnderline: true,
                                          isOverButton: false,
                                          isSearchable: false,
                                          isMultiSelect: false,
                                        ),
                                      ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 30.0, 0.0, 0.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      if (FFAppState()
                                          .missingTable
                                          .contains(FFAppState().userParameter))
                                        FFButtonWidget(
                                          onPressed: () async {
                                            logFirebaseEvent(
                                                'EDIT_INFO_PAGE_METTRE__JOUR_BTN_ON_TAP');
                                            if (healthParameterUserHealthParameterRow
                                                        ?.id !=
                                                    null &&
                                                healthParameterUserHealthParameterRow
                                                        ?.id !=
                                                    '') {
                                              logFirebaseEvent(
                                                  'Button_backend_call');
                                              _model.updateHealthParameterError =
                                                  await UserHealthParameterTable()
                                                      .update(
                                                data: {
                                                  'weight': _model.weightTextController1
                                                                  .text !=
                                                              null &&
                                                          _model.weightTextController1
                                                                  .text !=
                                                              ''
                                                      ? int.tryParse(_model
                                                          .weightTextController1
                                                          .text)
                                                      : int.tryParse(_model
                                                          .weightTextController2
                                                          .text),
                                                  'height': _model.heightTextController1
                                                                  .text !=
                                                              null &&
                                                          _model.heightTextController1
                                                                  .text !=
                                                              ''
                                                      ? double.tryParse(_model
                                                          .heightTextController1
                                                          .text)
                                                      : double.tryParse(_model
                                                          .heightTextController2
                                                          .text),
                                                  'sex': _model.genderValue1 !=
                                                              null &&
                                                          _model.genderValue1 !=
                                                              ''
                                                      ? _model.genderValue1
                                                      : _model.genderValue2,
                                                  'age': _model.ageTextController1
                                                                  .text !=
                                                              null &&
                                                          _model.ageTextController1
                                                                  .text !=
                                                              ''
                                                      ? int.tryParse(_model
                                                          .ageTextController1
                                                          .text)
                                                      : int.tryParse(_model
                                                          .ageTextController2
                                                          .text),
                                                  'activity_level': _model
                                                                  .activityLevelValue1 !=
                                                              null &&
                                                          _model.activityLevelValue1 !=
                                                              ''
                                                      ? _model
                                                          .activityLevelValue1
                                                      : _model
                                                          .activityLevelValue2,
                                                },
                                                matchingRows: (rows) =>
                                                    rows.eqOrNull(
                                                  'id',
                                                  healthParameterUserHealthParameterRow
                                                      ?.id,
                                                ),
                                                returnRows: true,
                                              );
                                            } else {
                                              logFirebaseEvent(
                                                  'Button_backend_call');
                                              _model.newHealthParameterError =
                                                  await UserHealthParameterTable()
                                                      .insert({
                                                'user_id': valueOrDefault(
                                                    currentUserDocument?.id, 0),
                                                'weight': _model.weightTextController1
                                                                .text !=
                                                            null &&
                                                        _model.weightTextController1
                                                                .text !=
                                                            ''
                                                    ? int.tryParse(_model
                                                        .weightTextController1
                                                        .text)
                                                    : int.tryParse(_model
                                                        .weightTextController2
                                                        .text),
                                                'height': _model.heightTextController1
                                                                .text !=
                                                            null &&
                                                        _model.heightTextController1
                                                                .text !=
                                                            ''
                                                    ? double.tryParse(_model
                                                        .heightTextController1
                                                        .text)
                                                    : double.tryParse(_model
                                                        .heightTextController2
                                                        .text),
                                                'sex': _model.genderValue1 !=
                                                            null &&
                                                        _model.genderValue1 !=
                                                            ''
                                                    ? _model.genderValue1
                                                    : _model.genderValue2,
                                                'activity_level':
                                                    _model.activityLevelValue1 !=
                                                                null &&
                                                            _model.activityLevelValue1 !=
                                                                ''
                                                        ? _model
                                                            .activityLevelValue1
                                                        : _model
                                                            .activityLevelValue2,
                                                'age': /* NOT RECOMMENDED */ _model
                                                            .ageTextController1
                                                            .text ==
                                                        'true'
                                                    ? int.tryParse(_model
                                                        .ageTextController1
                                                        .text)
                                                    : int.tryParse(_model
                                                        .ageTextController2
                                                        .text),
                                              });
                                            }

                                            logFirebaseEvent(
                                                'Button_refresh_database_request');
                                            safeSetState(() => _model
                                                .requestCompleter2 = null);
                                            await _model
                                                .waitForRequestCompleted2();

                                            safeSetState(() {});
                                          },
                                          text: FFLocalizations.of(context)
                                              .getText(
                                            '5tyzamjm' /* Mettre à jour */,
                                          ),
                                          options: FFButtonOptions(
                                            height: 40.0,
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 0.0, 16.0, 0.0),
                                            iconPadding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 0.0, 0.0, 0.0),
                                            color: FlutterFlowTheme.of(context)
                                                .error,
                                            textStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .override(
                                                      font: GoogleFonts.poppins(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleSmall
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleSmall
                                                                .fontStyle,
                                                      ),
                                                      color: Colors.white,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleSmall
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleSmall
                                                              .fontStyle,
                                                    ),
                                            elevation: 0.0,
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                        ),
                                      if (!FFAppState()
                                          .missingTable
                                          .contains(FFAppState().userParameter))
                                        FFButtonWidget(
                                          onPressed: () async {
                                            logFirebaseEvent(
                                                'EDIT_INFO_PAGE_METTRE__JOUR_BTN_ON_TAP');
                                            if (healthParameterUserHealthParameterRow
                                                        ?.id !=
                                                    null &&
                                                healthParameterUserHealthParameterRow
                                                        ?.id !=
                                                    '') {
                                              logFirebaseEvent(
                                                  'Button_backend_call');
                                              _model.updateHealthParameter =
                                                  await UserHealthParameterTable()
                                                      .update(
                                                data: {
                                                  'weight': _model.weightTextController1
                                                                  .text !=
                                                              null &&
                                                          _model.weightTextController1
                                                                  .text !=
                                                              ''
                                                      ? int.tryParse(_model
                                                          .weightTextController1
                                                          .text)
                                                      : int.tryParse(_model
                                                          .weightTextController2
                                                          .text),
                                                  'height': _model.heightTextController1
                                                                  .text !=
                                                              null &&
                                                          _model.heightTextController1
                                                                  .text !=
                                                              ''
                                                      ? double.tryParse(_model
                                                          .heightTextController1
                                                          .text)
                                                      : double.tryParse(_model
                                                          .heightTextController2
                                                          .text),
                                                  'sex': _model.genderValue1 !=
                                                              null &&
                                                          _model.genderValue1 !=
                                                              ''
                                                      ? _model.genderValue1
                                                      : _model.genderValue2,
                                                  'age': _model.ageTextController1
                                                                  .text !=
                                                              null &&
                                                          _model.ageTextController1
                                                                  .text !=
                                                              ''
                                                      ? int.tryParse(_model
                                                          .ageTextController1
                                                          .text)
                                                      : int.tryParse(_model
                                                          .ageTextController2
                                                          .text),
                                                  'activity_level': _model
                                                                  .activityLevelValue1 !=
                                                              null &&
                                                          _model.activityLevelValue1 !=
                                                              ''
                                                      ? _model
                                                          .activityLevelValue1
                                                      : _model
                                                          .activityLevelValue2,
                                                },
                                                matchingRows: (rows) =>
                                                    rows.eqOrNull(
                                                  'id',
                                                  healthParameterUserHealthParameterRow
                                                      ?.id,
                                                ),
                                                returnRows: true,
                                              );
                                            } else {
                                              logFirebaseEvent(
                                                  'Button_backend_call');
                                              _model.newHealthParameter =
                                                  await UserHealthParameterTable()
                                                      .insert({
                                                'user_id': valueOrDefault(
                                                    currentUserDocument?.id, 0),
                                                'weight': _model.weightTextController1
                                                                .text !=
                                                            null &&
                                                        _model.weightTextController1
                                                                .text !=
                                                            ''
                                                    ? int.tryParse(_model
                                                        .weightTextController1
                                                        .text)
                                                    : int.tryParse(_model
                                                        .weightTextController2
                                                        .text),
                                                'height': _model.heightTextController1
                                                                .text !=
                                                            null &&
                                                        _model.heightTextController1
                                                                .text !=
                                                            ''
                                                    ? double.tryParse(_model
                                                        .heightTextController1
                                                        .text)
                                                    : double.tryParse(_model
                                                        .heightTextController2
                                                        .text),
                                                'sex': _model.genderValue1 !=
                                                            null &&
                                                        _model.genderValue1 !=
                                                            ''
                                                    ? _model.genderValue1
                                                    : _model.genderValue2,
                                                'activity_level':
                                                    _model.activityLevelValue1 !=
                                                                null &&
                                                            _model.activityLevelValue1 !=
                                                                ''
                                                        ? _model
                                                            .activityLevelValue1
                                                        : _model
                                                            .activityLevelValue2,
                                                'age': /* NOT RECOMMENDED */ _model
                                                            .ageTextController1
                                                            .text ==
                                                        'true'
                                                    ? int.tryParse(_model
                                                        .ageTextController1
                                                        .text)
                                                    : int.tryParse(_model
                                                        .ageTextController2
                                                        .text),
                                              });
                                            }

                                            logFirebaseEvent(
                                                'Button_refresh_database_request');
                                            safeSetState(() => _model
                                                .requestCompleter2 = null);
                                            await _model
                                                .waitForRequestCompleted2();

                                            safeSetState(() {});
                                          },
                                          text: FFLocalizations.of(context)
                                              .getText(
                                            '1qhdrd6x' /* Mettre à jour */,
                                          ),
                                          options: FFButtonOptions(
                                            height: 40.0,
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 0.0, 16.0, 0.0),
                                            iconPadding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 0.0, 0.0, 0.0),
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            textStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .override(
                                                      font: GoogleFonts.poppins(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleSmall
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleSmall
                                                                .fontStyle,
                                                      ),
                                                      color: Colors.white,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleSmall
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleSmall
                                                              .fontStyle,
                                                    ),
                                            elevation: 0.0,
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ]
                                  .divide(SizedBox(height: 10.0))
                                  .addToStart(SizedBox(height: 15.0))
                                  .addToEnd(SizedBox(height: 15.0)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(25.0, 0.0, 25.0, 0.0),
                  child: AuthUserStreamWidget(
                    builder: (context) =>
                        FutureBuilder<List<UserPreferencesRow>>(
                      future: (_model.requestCompleter1 ??= Completer<
                              List<UserPreferencesRow>>()
                            ..complete(UserPreferencesTable().querySingleRow(
                              queryFn: (q) => q.eqOrNull(
                                'user_id',
                                valueOrDefault(currentUserDocument?.id, 0),
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
                                color: FlutterFlowTheme.of(context).tertiary,
                                size: 50.0,
                              ),
                            ),
                          );
                        }
                        List<UserPreferencesRow>
                            preferencesUserPreferencesRowList = snapshot.data!;

                        final preferencesUserPreferencesRow =
                            preferencesUserPreferencesRowList.isNotEmpty
                                ? preferencesUserPreferencesRowList.first
                                : null;

                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color:
                                FlutterFlowTheme.of(context).primaryBackground,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'p4qjl98r' /* Préférences alimentaire */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .titleLarge
                                      .override(
                                        font: GoogleFonts.outfit(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .titleLarge
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleLarge
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .titleLarge
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleLarge
                                            .fontStyle,
                                      ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.not_interested,
                                      color:
                                          FlutterFlowTheme.of(context).accent2,
                                      size: 24.0,
                                    ),
                                    Text(
                                      FFLocalizations.of(context).getText(
                                        '8lv5lu8j' /* Régime */,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            font: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ].divide(SizedBox(width: 5.0)),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: Theme(
                                    data: ThemeData(
                                      checkboxTheme: CheckboxThemeData(
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      unselectedWidgetColor:
                                          FlutterFlowTheme.of(context)
                                              .alternate,
                                    ),
                                    child: CheckboxListTile(
                                      value: _model.sansViandeValue ??=
                                          preferencesUserPreferencesRow
                                                      ?.sansViande !=
                                                  null
                                              ? preferencesUserPreferencesRow!
                                                  .sansViande!
                                              : false,
                                      onChanged: (newValue) async {
                                        safeSetState(() =>
                                            _model.sansViandeValue = newValue!);
                                      },
                                      title: Text(
                                        FFLocalizations.of(context).getText(
                                          'ythun1y1' /* Sans Viande */,
                                        ),
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
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
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
                                      activeColor:
                                          FlutterFlowTheme.of(context).primary,
                                      checkColor:
                                          FlutterFlowTheme.of(context).info,
                                      dense: false,
                                      controlAffinity:
                                          ListTileControlAffinity.trailing,
                                      contentPadding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              12.0, 0.0, 12.0, 0.0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: Theme(
                                    data: ThemeData(
                                      checkboxTheme: CheckboxThemeData(
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      unselectedWidgetColor:
                                          FlutterFlowTheme.of(context)
                                              .alternate,
                                    ),
                                    child: CheckboxListTile(
                                      value: _model.sansPorcValue ??=
                                          preferencesUserPreferencesRow
                                                      ?.halal !=
                                                  null
                                              ? preferencesUserPreferencesRow!
                                                  .halal!
                                              : false,
                                      onChanged: (newValue) async {
                                        safeSetState(() =>
                                            _model.sansPorcValue = newValue!);
                                      },
                                      title: Text(
                                        FFLocalizations.of(context).getText(
                                          'derhi30t' /* Sans Porc */,
                                        ),
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
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
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
                                      activeColor:
                                          FlutterFlowTheme.of(context).primary,
                                      checkColor:
                                          FlutterFlowTheme.of(context).info,
                                      dense: false,
                                      controlAffinity:
                                          ListTileControlAffinity.trailing,
                                      contentPadding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              12.0, 0.0, 12.0, 0.0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.warning_rounded,
                                      color: FlutterFlowTheme.of(context).error,
                                      size: 24.0,
                                    ),
                                    Text(
                                      FFLocalizations.of(context).getText(
                                        '7bs8lcvb' /* Allergie */,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            font: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ].divide(SizedBox(width: 5.0)),
                                ),
                                FutureBuilder<List<UserAllergiesRow>>(
                                  future: (_model.requestCompleter4 ??=
                                          Completer<List<UserAllergiesRow>>()
                                            ..complete(
                                                UserAllergiesTable().queryRows(
                                              queryFn: (q) => q.eqOrNull(
                                                'user_id',
                                                valueOrDefault(
                                                    currentUserDocument?.id, 0),
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
                                            color: FlutterFlowTheme.of(context)
                                                .tertiary,
                                            size: 50.0,
                                          ),
                                        ),
                                      );
                                    }
                                    List<UserAllergiesRow>
                                        listViewUserAllergiesRowList =
                                        snapshot.data!;

                                    return ListView.builder(
                                      padding: EdgeInsets.zero,
                                      primary: false,
                                      shrinkWrap: true,
                                      scrollDirection: Axis.vertical,
                                      itemCount:
                                          listViewUserAllergiesRowList.length,
                                      itemBuilder: (context, listViewIndex) {
                                        final listViewUserAllergiesRow =
                                            listViewUserAllergiesRowList[
                                                listViewIndex];
                                        return Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            if (!_model.edit)
                                              Expanded(
                                                child: Text(
                                                  valueOrDefault<String>(
                                                    listViewUserAllergiesRow
                                                        .name,
                                                    'allergie name',
                                                  ),
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .titleSmall
                                                      .override(
                                                        font:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleSmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleSmall
                                                                  .fontStyle,
                                                        ),
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondaryText,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleSmall
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleSmall
                                                                .fontStyle,
                                                      ),
                                                ),
                                              ),
                                            if (_model.edit)
                                              Expanded(
                                                child: wrapWithModel(
                                                  model: _model.textfieldModels
                                                      .getModel(
                                                    listViewUserAllergiesRow
                                                        .id!,
                                                    listViewIndex,
                                                  ),
                                                  updateCallback: () =>
                                                      safeSetState(() {}),
                                                  child: TextfieldWidget(
                                                    key: Key(
                                                      'Keyxrj_${listViewUserAllergiesRow.id!}',
                                                    ),
                                                    allergieName:
                                                        listViewUserAllergiesRow
                                                            .name!,
                                                  ),
                                                ),
                                              ),
                                            if (_model.edit)
                                              InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor:
                                                    Colors.transparent,
                                                onTap: () async {
                                                  logFirebaseEvent(
                                                      'EDIT_INFO_PAGE_Icon_byhmdjta_ON_TAP');
                                                  logFirebaseEvent(
                                                      'Icon_backend_call');
                                                  await UserAllergiesTable()
                                                      .update(
                                                    data: {
                                                      'name': _model
                                                          .textfieldModels
                                                          .getValueForKey(
                                                        listViewUserAllergiesRow
                                                            .id!,
                                                        (m) => m.textController
                                                            .text,
                                                      ),
                                                    },
                                                    matchingRows: (rows) =>
                                                        rows.eqOrNull(
                                                      'id',
                                                      listViewUserAllergiesRow
                                                          .id,
                                                    ),
                                                  );
                                                  logFirebaseEvent(
                                                      'Icon_refresh_database_request');
                                                  safeSetState(() =>
                                                      _model.requestCompleter4 =
                                                          null);
                                                  await _model
                                                      .waitForRequestCompleted4();
                                                  logFirebaseEvent(
                                                      'Icon_update_page_state');
                                                  _model.edit = false;
                                                  safeSetState(() {});
                                                },
                                                child: Icon(
                                                  Icons.check_rounded,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                  size: 24.0,
                                                ),
                                              ),
                                            if (!_model.edit)
                                              InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor:
                                                    Colors.transparent,
                                                onTap: () async {
                                                  logFirebaseEvent(
                                                      'EDIT_INFO_PAGE_Icon_ea2oz38z_ON_TAP');
                                                  logFirebaseEvent(
                                                      'Icon_update_page_state');
                                                  _model.edit = true;
                                                  safeSetState(() {});
                                                },
                                                child: Icon(
                                                  Icons.edit,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                  size: 24.0,
                                                ),
                                              ),
                                            InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                logFirebaseEvent(
                                                    'EDIT_INFO_PAGE_Icon_h9b9bhsz_ON_TAP');
                                                logFirebaseEvent(
                                                    'Icon_backend_call');
                                                await UserAllergiesTable()
                                                    .delete(
                                                  matchingRows: (rows) =>
                                                      rows.eqOrNull(
                                                    'id',
                                                    listViewUserAllergiesRow.id,
                                                  ),
                                                );
                                                logFirebaseEvent(
                                                    'Icon_refresh_database_request');
                                                safeSetState(() => _model
                                                    .requestCompleter4 = null);
                                                await _model
                                                    .waitForRequestCompleted4();
                                              },
                                              child: Icon(
                                                Icons.delete_rounded,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                                size: 24.0,
                                              ),
                                            ),
                                          ].divide(SizedBox(width: 10.0)),
                                        );
                                      },
                                    );
                                  },
                                ),
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'wa0qtmok' /* Ajouter une allergie */,
                                  ),
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
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      10.0, 0.0, 10.0, 0.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Container(
                                        width: 250.0,
                                        child: TextFormField(
                                          controller: _model.textController7,
                                          focusNode: _model.textFieldFocusNode,
                                          autofocus: false,
                                          obscureText: false,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            labelStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.poppins(
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
                                            hintText:
                                                FFLocalizations.of(context)
                                                    .getText(
                                              'c5j5vybi' /* Autres Allergies */,
                                            ),
                                            hintStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.poppins(
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
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            filled: true,
                                            fillColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.poppins(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                          maxLines: null,
                                          cursorColor:
                                              FlutterFlowTheme.of(context)
                                                  .primaryText,
                                          validator: _model
                                              .textController7Validator
                                              .asValidator(context),
                                        ),
                                      ),
                                      InkWell(
                                        splashColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () async {
                                          logFirebaseEvent(
                                              'EDIT_INFO_PAGE_Icon_xabio1md_ON_TAP');
                                          logFirebaseEvent('Icon_backend_call');
                                          await UserAllergiesTable().insert({
                                            'user_id': valueOrDefault(
                                                currentUserDocument?.id, 0),
                                            'name': _model.textController7.text,
                                          });
                                          logFirebaseEvent(
                                              'Icon_refresh_database_request');
                                          safeSetState(() =>
                                              _model.requestCompleter4 = null);
                                          await _model
                                              .waitForRequestCompleted4();
                                        },
                                        child: Icon(
                                          Icons.add_circle_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          size: 32.0,
                                        ),
                                      ),
                                    ].divide(SizedBox(width: 10.0)),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.favorite_outlined,
                                      color:
                                          FlutterFlowTheme.of(context).accent2,
                                      size: 24.0,
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 10.0, 0.0, 0.0),
                                      child: Text(
                                        FFLocalizations.of(context).getText(
                                          '5imae4ru' /* Région favorite */,
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .override(
                                              font: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .fontStyle,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                  ].divide(SizedBox(width: 5.0)),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 0.0, 16.0, 0.0),
                                  child: FlutterFlowCheckboxGroup(
                                    options: [
                                      FFLocalizations.of(context).getText(
                                        '4m55f60x' /* Afrique du nord */,
                                      ),
                                      FFLocalizations.of(context).getText(
                                        'iz1sgvxc' /* Afrique de l'ouest */,
                                      ),
                                      FFLocalizations.of(context).getText(
                                        'w4ih59zy' /* Afrique de l'est */,
                                      ),
                                      FFLocalizations.of(context).getText(
                                        'qfeubxzj' /* Afrique centrale */,
                                      ),
                                      FFLocalizations.of(context).getText(
                                        'xg8zkvy0' /* Afrique du sud */,
                                      ),
                                      FFLocalizations.of(context).getText(
                                        'soq654ah' /* Carraïbes */,
                                      ),
                                      FFLocalizations.of(context).getText(
                                        'wucepnci' /* Occidentale */,
                                      ),
                                      FFLocalizations.of(context).getText(
                                        'e3pf1lek' /* Autres */,
                                      )
                                    ],
                                    onChanged: (val) => safeSetState(() =>
                                        _model.favoriteRegionValues = val),
                                    controller:
                                        _model.favoriteRegionValueController ??=
                                            FormFieldController<List<String>>(
                                      List.from([
                                            preferencesUserPreferencesRow
                                                            ?.favoriteFoodRegion !=
                                                        null &&
                                                    preferencesUserPreferencesRow
                                                            ?.favoriteFoodRegion !=
                                                        ''
                                                ? preferencesUserPreferencesRow!
                                                    .favoriteFoodRegion!
                                                : ''
                                          ] ??
                                          []),
                                    ),
                                    activeColor:
                                        FlutterFlowTheme.of(context).primary,
                                    checkColor:
                                        FlutterFlowTheme.of(context).info,
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
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                    checkboxBorderRadius:
                                        BorderRadius.circular(4.0),
                                    initialized:
                                        _model.favoriteRegionValues != null,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 10.0, 0.0, 0.0),
                                  child: Text(
                                    FFLocalizations.of(context).getText(
                                      'yi00vg5j' /* Regime particulier */,
                                    ),
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
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
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
                                ),
                                Container(
                                  width: 200.0,
                                  child: TextFormField(
                                    controller:
                                        _model.particularDietTextController ??=
                                            TextEditingController(
                                      text: preferencesUserPreferencesRow
                                                      ?.particularDiet !=
                                                  null &&
                                              preferencesUserPreferencesRow
                                                      ?.particularDiet !=
                                                  ''
                                          ? preferencesUserPreferencesRow
                                              ?.particularDiet
                                          : '',
                                    ),
                                    focusNode: _model.particularDietFocusNode,
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
                                      hintText: preferencesUserPreferencesRow
                                                      ?.particularDiet !=
                                                  null &&
                                              preferencesUserPreferencesRow
                                                      ?.particularDiet !=
                                                  ''
                                          ? ''
                                          : 'Avez vous un régime particulier ?',
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
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0x00000000),
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .error,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .error,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      filled: true,
                                      fillColor: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
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
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                    cursorColor: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    enableInteractiveSelection: true,
                                    validator: _model
                                        .particularDietTextControllerValidator
                                        .asValidator(context),
                                  ),
                                ),
                                FFButtonWidget(
                                  onPressed: () async {
                                    logFirebaseEvent(
                                        'EDIT_INFO_PAGE_METTRE__JOUR_BTN_ON_TAP');
                                    if (preferencesUserPreferencesRow?.id !=
                                            null &&
                                        preferencesUserPreferencesRow?.id !=
                                            '') {
                                      logFirebaseEvent('Button_backend_call');
                                      _model.updatePreferences =
                                          await UserPreferencesTable().update(
                                        data: {
                                          'favorite_food_region': _model
                                              .favoriteRegionValues?.lastOrNull,
                                          'particular diet': _model
                                              .particularDietTextController
                                              .text,
                                          'halal': _model.sansPorcValue,
                                          'sans viande': _model.sansViandeValue,
                                        },
                                        matchingRows: (rows) => rows.eqOrNull(
                                          'id',
                                          preferencesUserPreferencesRow?.id,
                                        ),
                                        returnRows: true,
                                      );
                                    } else {
                                      logFirebaseEvent('Button_backend_call');
                                      _model.newPreferences =
                                          await UserPreferencesTable().insert({
                                        'user_id': valueOrDefault(
                                            currentUserDocument?.id, 0),
                                        'favorite_food_region': _model
                                            .favoriteRegionValues?.lastOrNull,
                                        'halal': _model.sansPorcValue,
                                        'sans viande': _model.sansViandeValue,
                                        'particular diet': _model
                                            .particularDietTextController.text,
                                      });
                                    }

                                    logFirebaseEvent(
                                        'Button_refresh_database_request');
                                    safeSetState(
                                        () => _model.requestCompleter1 = null);
                                    await _model.waitForRequestCompleted1();

                                    safeSetState(() {});
                                  },
                                  text: FFLocalizations.of(context).getText(
                                    '1qzuwb4q' /* Mettre à jour */,
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
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: Colors.white,
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
                                    elevation: 0.0,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ]
                                  .divide(SizedBox(height: 10.0))
                                  .addToStart(SizedBox(height: 15.0))
                                  .addToEnd(SizedBox(height: 15.0)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(25.0, 0.0, 25.0, 0.0),
                  child: AuthUserStreamWidget(
                    builder: (context) => FutureBuilder<List<UserGoalRow>>(
                      future: (_model.requestCompleter3 ??=
                              Completer<List<UserGoalRow>>()
                                ..complete(UserGoalTable().querySingleRow(
                                  queryFn: (q) => q.eqOrNull(
                                    'user_id',
                                    valueOrDefault(currentUserDocument?.id, 0),
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
                                color: FlutterFlowTheme.of(context).tertiary,
                                size: 50.0,
                              ),
                            ),
                          );
                        }
                        List<UserGoalRow> goalUserGoalRowList = snapshot.data!;

                        final goalUserGoalRow = goalUserGoalRowList.isNotEmpty
                            ? goalUserGoalRowList.first
                            : null;

                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color:
                                FlutterFlowTheme.of(context).primaryBackground,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.track_changes_rounded,
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      size: 24.0,
                                    ),
                                    Text(
                                      FFLocalizations.of(context).getText(
                                        '32rm9j8n' /* Vos Objectifs */,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .titleLarge
                                          .override(
                                            font: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleLarge
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleLarge
                                                    .fontStyle,
                                          ),
                                    ),
                                  ].divide(SizedBox(width: 5.0)),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      FFLocalizations.of(context).getText(
                                        'qwetd1jm' /* Votre objectif de poids */,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            font: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ].divide(SizedBox(width: 5.0)),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    if (FFAppState()
                                        .missingField
                                        .contains(FFAppState().targetWeight))
                                      Container(
                                        width: 250.0,
                                        child: TextFormField(
                                          controller: _model
                                                  .targetWeightTextController1 ??=
                                              TextEditingController(
                                            text: goalUserGoalRow
                                                        ?.targetWeight !=
                                                    null
                                                ? goalUserGoalRow?.targetWeight
                                                    ?.toString()
                                                : '',
                                          ),
                                          focusNode:
                                              _model.targetWeightFocusNode1,
                                          autofocus: false,
                                          obscureText: false,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            labelStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.poppins(
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
                                            hintText: goalUserGoalRow
                                                        ?.targetWeight !=
                                                    null
                                                ? ''
                                                : 'Quel poids voulez vous atteindre  ? ',
                                            hintStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.poppins(
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
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .error,
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
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            filled: true,
                                            fillColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.poppins(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                          cursorColor:
                                              FlutterFlowTheme.of(context)
                                                  .primaryText,
                                          enableInteractiveSelection: true,
                                          validator: _model
                                              .targetWeightTextController1Validator
                                              .asValidator(context),
                                        ),
                                      ),
                                    if (!FFAppState()
                                        .missingField
                                        .contains(FFAppState().targetWeight))
                                      Container(
                                        width: 250.0,
                                        child: TextFormField(
                                          controller: _model
                                                  .targetWeightTextController2 ??=
                                              TextEditingController(
                                            text: goalUserGoalRow
                                                        ?.targetWeight !=
                                                    null
                                                ? goalUserGoalRow?.targetWeight
                                                    ?.toString()
                                                : '',
                                          ),
                                          focusNode:
                                              _model.targetWeightFocusNode2,
                                          autofocus: false,
                                          obscureText: false,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            labelStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.poppins(
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
                                            hintText: goalUserGoalRow
                                                        ?.targetWeight !=
                                                    null
                                                ? ''
                                                : 'Quel poids voulez vous atteindre  ? ',
                                            hintStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.poppins(
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
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            filled: true,
                                            fillColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.poppins(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                          cursorColor:
                                              FlutterFlowTheme.of(context)
                                                  .primaryText,
                                          enableInteractiveSelection: true,
                                          validator: _model
                                              .targetWeightTextController2Validator
                                              .asValidator(context),
                                        ),
                                      ),
                                  ],
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Text(
                                      FFLocalizations.of(context).getText(
                                        '2qdz3dis' /* Temps de Régime */,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            font: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                    Text(
                                      FFLocalizations.of(context).getText(
                                        'afyjip4q' /* en mois  */,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .override(
                                            font: GoogleFonts.poppins(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
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
                                  ].divide(SizedBox(height: 5.0)),
                                ),
                                Slider(
                                  activeColor:
                                      FlutterFlowTheme.of(context).primary,
                                  inactiveColor:
                                      FlutterFlowTheme.of(context).alternate,
                                  min: 0.0,
                                  max: 12.0,
                                  value: _model.targetTimeValue ??=
                                      goalUserGoalRow?.targetTime != null
                                          ? valueOrDefault<double>(
                                              goalUserGoalRow?.targetTime,
                                              0.0,
                                            )
                                          : 0.0,
                                  label: _model.targetTimeValue
                                      ?.toStringAsFixed(0),
                                  divisions: 12,
                                  onChanged: (newValue) {
                                    newValue = double.parse(
                                        newValue.toStringAsFixed(0));
                                    safeSetState(() =>
                                        _model.targetTimeValue = newValue);
                                  },
                                ),
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'dq6500vq' /* Vos Objectifs */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .fontStyle,
                                      ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    if (FFAppState()
                                        .missingField
                                        .contains(FFAppState().objectif))
                                      Container(
                                        width: 250.0,
                                        child: TextFormField(
                                          controller:
                                              _model.objectifTextController1 ??=
                                                  TextEditingController(
                                            text: goalUserGoalRow?.objectif !=
                                                        null &&
                                                    goalUserGoalRow?.objectif !=
                                                        ''
                                                ? goalUserGoalRow?.objectif
                                                : '',
                                          ),
                                          focusNode: _model.objectifFocusNode1,
                                          autofocus: false,
                                          obscureText: false,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            labelStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.poppins(
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
                                            hintText: goalUserGoalRow
                                                            ?.objectif !=
                                                        null &&
                                                    goalUserGoalRow?.objectif !=
                                                        ''
                                                ? ''
                                                : 'Décrivez vos objectifs',
                                            hintStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.poppins(
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
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .error,
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
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            filled: true,
                                            fillColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.poppins(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                          maxLines: 5,
                                          cursorColor:
                                              FlutterFlowTheme.of(context)
                                                  .primaryText,
                                          validator: _model
                                              .objectifTextController1Validator
                                              .asValidator(context),
                                        ),
                                      ),
                                    if (!FFAppState()
                                        .missingField
                                        .contains(FFAppState().objectif))
                                      Container(
                                        width: 250.0,
                                        child: TextFormField(
                                          controller:
                                              _model.objectifTextController2 ??=
                                                  TextEditingController(
                                            text: goalUserGoalRow?.objectif !=
                                                        null &&
                                                    goalUserGoalRow?.objectif !=
                                                        ''
                                                ? goalUserGoalRow?.objectif
                                                : '',
                                          ),
                                          focusNode: _model.objectifFocusNode2,
                                          autofocus: false,
                                          obscureText: false,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            labelStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.poppins(
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
                                            hintText: goalUserGoalRow
                                                            ?.objectif !=
                                                        null &&
                                                    goalUserGoalRow?.objectif !=
                                                        ''
                                                ? ''
                                                : 'Décrivez vos objectifs',
                                            hintStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.poppins(
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
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            filled: true,
                                            fillColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.poppins(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                          maxLines: 5,
                                          cursorColor:
                                              FlutterFlowTheme.of(context)
                                                  .primaryText,
                                          validator: _model
                                              .objectifTextController2Validator
                                              .asValidator(context),
                                        ),
                                      ),
                                  ],
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    if (FFAppState()
                                        .missingTable
                                        .contains(FFAppState().userGoal))
                                      FFButtonWidget(
                                        onPressed: () async {
                                          logFirebaseEvent(
                                              'EDIT_INFO_PAGE_METTRE__JOUR_BTN_ON_TAP');
                                          if (goalUserGoalRow?.id != null &&
                                              goalUserGoalRow?.id != '') {
                                            logFirebaseEvent(
                                                'Button_backend_call');
                                            await UserGoalTable().update(
                                              data: {
                                                'target_weight': _model
                                                                .targetWeightTextController1
                                                                .text !=
                                                            null &&
                                                        _model.targetWeightTextController1
                                                                .text !=
                                                            ''
                                                    ? int.tryParse(_model
                                                        .targetWeightTextController1
                                                        .text)
                                                    : int.tryParse(_model
                                                        .targetWeightTextController2
                                                        .text),
                                                'objectif': _model
                                                                .objectifTextController1
                                                                .text !=
                                                            null &&
                                                        _model.objectifTextController1
                                                                .text !=
                                                            ''
                                                    ? _model
                                                        .objectifTextController1
                                                        .text
                                                    : _model
                                                        .objectifTextController2
                                                        .text,
                                                'target_time':
                                                    _model.targetTimeValue,
                                              },
                                              matchingRows: (rows) =>
                                                  rows.eqOrNull(
                                                'id',
                                                goalUserGoalRow?.id,
                                              ),
                                            );
                                          } else {
                                            logFirebaseEvent(
                                                'Button_backend_call');
                                            await UserGoalTable().insert({
                                              'user_id': valueOrDefault(
                                                  currentUserDocument?.id, 0),
                                              'target_weight': _model
                                                              .targetWeightTextController1
                                                              .text !=
                                                          null &&
                                                      _model.targetWeightTextController1
                                                              .text !=
                                                          ''
                                                  ? int.tryParse(_model
                                                      .targetWeightTextController1
                                                      .text)
                                                  : int.tryParse(_model
                                                      .targetWeightTextController2
                                                      .text),
                                              'objectif': _model
                                                              .objectifTextController1
                                                              .text !=
                                                          null &&
                                                      _model.objectifTextController1
                                                              .text !=
                                                          ''
                                                  ? _model
                                                      .objectifTextController1
                                                      .text
                                                  : _model
                                                      .objectifTextController2
                                                      .text,
                                              'target_time':
                                                  _model.targetTimeValue,
                                            });
                                          }

                                          logFirebaseEvent(
                                              'Button_refresh_database_request');
                                          safeSetState(() =>
                                              _model.requestCompleter3 = null);
                                          await _model
                                              .waitForRequestCompleted3();
                                          logFirebaseEvent(
                                              'Button_reset_form_fields');
                                          safeSetState(() {
                                            _model.targetWeightTextController1
                                                ?.text = goalUserGoalRow
                                                        ?.targetWeight !=
                                                    null
                                                ? goalUserGoalRow!.targetWeight!
                                                    .toString()
                                                : '';

                                            _model.targetWeightTextController2
                                                ?.text = goalUserGoalRow
                                                        ?.targetWeight !=
                                                    null
                                                ? goalUserGoalRow!.targetWeight!
                                                    .toString()
                                                : '';

                                            _model.objectifTextController1
                                                ?.text = goalUserGoalRow
                                                            ?.objectif !=
                                                        null &&
                                                    goalUserGoalRow?.objectif !=
                                                        ''
                                                ? goalUserGoalRow!.objectif!
                                                : '';

                                            _model.objectifTextController2
                                                ?.text = goalUserGoalRow
                                                            ?.objectif !=
                                                        null &&
                                                    goalUserGoalRow?.objectif !=
                                                        ''
                                                ? goalUserGoalRow!.objectif!
                                                : '';
                                          });

                                          safeSetState(() {});
                                        },
                                        text:
                                            FFLocalizations.of(context).getText(
                                          'a54lhc47' /* Mettre à jour */,
                                        ),
                                        options: FFButtonOptions(
                                          height: 40.0,
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 0.0, 16.0, 0.0),
                                          iconPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 0.0, 0.0),
                                          color: FlutterFlowTheme.of(context)
                                              .accent2,
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .titleSmall
                                              .override(
                                                font: GoogleFonts.poppins(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                                color: Colors.white,
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
                                          elevation: 0.0,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                    if (!FFAppState()
                                        .missingTable
                                        .contains(FFAppState().userGoal))
                                      FFButtonWidget(
                                        onPressed: () async {
                                          logFirebaseEvent(
                                              'EDIT_INFO_PAGE_METTRE__JOUR_BTN_ON_TAP');
                                          if (goalUserGoalRow?.id != null &&
                                              goalUserGoalRow?.id != '') {
                                            logFirebaseEvent(
                                                'Button_backend_call');
                                            _model.updateGoal =
                                                await UserGoalTable().update(
                                              data: {
                                                'target_weight': _model
                                                                .targetWeightTextController1
                                                                .text !=
                                                            null &&
                                                        _model.targetWeightTextController1
                                                                .text !=
                                                            ''
                                                    ? int.tryParse(_model
                                                        .targetWeightTextController1
                                                        .text)
                                                    : int.tryParse(_model
                                                        .targetWeightTextController2
                                                        .text),
                                                'objectif': _model
                                                                .objectifTextController1
                                                                .text !=
                                                            null &&
                                                        _model.objectifTextController1
                                                                .text !=
                                                            ''
                                                    ? _model
                                                        .objectifTextController1
                                                        .text
                                                    : _model
                                                        .objectifTextController2
                                                        .text,
                                                'target_time':
                                                    _model.targetTimeValue,
                                              },
                                              matchingRows: (rows) =>
                                                  rows.eqOrNull(
                                                'id',
                                                goalUserGoalRow?.id,
                                              ),
                                              returnRows: true,
                                            );
                                          } else {
                                            logFirebaseEvent(
                                                'Button_backend_call');
                                            _model.insertGoal =
                                                await UserGoalTable().insert({
                                              'user_id': valueOrDefault(
                                                  currentUserDocument?.id, 0),
                                              'target_weight': _model
                                                              .targetWeightTextController1
                                                              .text !=
                                                          null &&
                                                      _model.targetWeightTextController1
                                                              .text !=
                                                          ''
                                                  ? int.tryParse(_model
                                                      .targetWeightTextController1
                                                      .text)
                                                  : int.tryParse(_model
                                                      .targetWeightTextController2
                                                      .text),
                                              'objectif': _model
                                                              .objectifTextController1
                                                              .text !=
                                                          null &&
                                                      _model.objectifTextController1
                                                              .text !=
                                                          ''
                                                  ? _model
                                                      .objectifTextController1
                                                      .text
                                                  : _model
                                                      .objectifTextController2
                                                      .text,
                                              'target_time':
                                                  _model.targetTimeValue,
                                            });
                                          }

                                          logFirebaseEvent(
                                              'Button_refresh_database_request');
                                          safeSetState(() =>
                                              _model.requestCompleter3 = null);
                                          await _model
                                              .waitForRequestCompleted3();

                                          safeSetState(() {});
                                        },
                                        text:
                                            FFLocalizations.of(context).getText(
                                          'fqp0xa4o' /* Mettre à jour */,
                                        ),
                                        options: FFButtonOptions(
                                          height: 40.0,
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 0.0, 16.0, 0.0),
                                          iconPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 0.0, 0.0),
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .titleSmall
                                              .override(
                                                font: GoogleFonts.poppins(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                                color: Colors.white,
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
                                          elevation: 0.0,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                  ],
                                ),
                                Divider(
                                  thickness: 2.0,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.restaurant_menu_rounded,
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      size: 24.0,
                                    ),
                                    Text(
                                      FFLocalizations.of(context).getText(
                                        'jfujxarf' /* Votre plan */,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .titleLarge
                                          .override(
                                            font: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleLarge
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleLarge
                                                    .fontStyle,
                                          ),
                                    ),
                                  ].divide(SizedBox(width: 5.0)),
                                ),
                                Text(
                                  FFLocalizations.of(context).getText(
                                    't4axudq6' /* Vous pouvez personnaliser votr... */,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: FlutterFlowTheme.of(context)
                                      .labelSmall
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelSmall
                                                  .fontStyle,
                                        ),
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .fontStyle,
                                      ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.wb_sunny_sharp,
                                          color: FlutterFlowTheme.of(context)
                                              .secondary,
                                          size: 24.0,
                                        ),
                                        Text(
                                          FFLocalizations.of(context).getText(
                                            'dqseh8xo' /* Vos calorie de la journéee */,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .titleMedium
                                              .override(
                                                font: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleMedium
                                                          .fontStyle,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondary,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .fontStyle,
                                              ),
                                        ),
                                      ].divide(SizedBox(width: 5.0)),
                                    ),
                                    Container(
                                      width: 200.0,
                                      child: TextFormField(
                                        controller:
                                            _model.dailyCalTextController ??=
                                                TextEditingController(
                                          text: goalUserGoalRow
                                                      ?.targetCalorie !=
                                                  null
                                              ? goalUserGoalRow?.targetCalorie
                                                  ?.toString()
                                              : '',
                                        ),
                                        focusNode: _model.dailyCalFocusNode,
                                        onChanged: (_) => EasyDebounce.debounce(
                                          '_model.dailyCalTextController',
                                          Duration(milliseconds: 2000),
                                          () async {
                                            logFirebaseEvent(
                                                'EDIT_INFO_DailyCal_ON_TEXTFIELD_CHANGE');
                                            logFirebaseEvent(
                                                'DailyCal_update_page_state');
                                            _model.dailyCal = double.tryParse(
                                                _model.dailyCalTextController
                                                    .text);
                                            _model.modification = true;
                                            safeSetState(() {});
                                          },
                                        ),
                                        autofocus: false,
                                        obscureText: false,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          labelStyle: FlutterFlowTheme.of(
                                                  context)
                                              .labelMedium
                                              .override(
                                                font: GoogleFonts.poppins(
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
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .fontStyle,
                                              ),
                                          hintText: goalUserGoalRow
                                                      ?.targetCalorie !=
                                                  null
                                              ? ''
                                              : 'Combien de calorie voulez vous manger par jour ?',
                                          hintStyle: FlutterFlowTheme.of(
                                                  context)
                                              .labelMedium
                                              .override(
                                                font: GoogleFonts.poppins(
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
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0x00000000),
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .error,
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .error,
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          filled: true,
                                          fillColor:
                                              FlutterFlowTheme.of(context)
                                                  .secondaryBackground,
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
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                        keyboardType: TextInputType.number,
                                        cursorColor:
                                            FlutterFlowTheme.of(context)
                                                .primaryText,
                                        enableInteractiveSelection: true,
                                        validator: _model
                                            .dailyCalTextControllerValidator
                                            .asValidator(context),
                                      ),
                                    ),
                                  ].divide(SizedBox(height: 5.0)),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.free_breakfast_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          size: 24.0,
                                        ),
                                        Text(
                                          FFLocalizations.of(context).getText(
                                            'ngm49cco' /* Vos calorie du petit-déjeuner */,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .titleMedium
                                              .override(
                                                font: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleMedium
                                                          .fontStyle,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .fontStyle,
                                              ),
                                        ),
                                      ].divide(SizedBox(width: 5.0)),
                                    ),
                                    Container(
                                      width: 200.0,
                                      child: TextFormField(
                                        controller: _model
                                                .breakfastCalTextController ??=
                                            TextEditingController(
                                          text: goalUserGoalRow
                                                      ?.breakfastCalorie !=
                                                  null
                                              ? goalUserGoalRow
                                                  ?.breakfastCalorie
                                                  ?.toString()
                                              : '',
                                        ),
                                        focusNode: _model.breakfastCalFocusNode,
                                        onChanged: (_) => EasyDebounce.debounce(
                                          '_model.breakfastCalTextController',
                                          Duration(milliseconds: 2000),
                                          () async {
                                            logFirebaseEvent(
                                                'EDIT_INFO_BreakfastCal_ON_TEXTFIELD_CHAN');
                                            logFirebaseEvent(
                                                'BreakfastCal_update_page_state');
                                            _model.totalCal = (_model.breakfastCalTextController.text != null && _model.breakfastCalTextController.text != ''
                                                    ? double.parse(_model
                                                        .breakfastCalTextController
                                                        .text)
                                                    : 0.0) +
                                                (_model.lunchCalTextController.text != null &&
                                                        _model.lunchCalTextController.text !=
                                                            ''
                                                    ? double.parse(_model
                                                        .lunchCalTextController
                                                        .text)
                                                    : 0.0) +
                                                (_model.dinerCalTextController.text !=
                                                            null &&
                                                        _model.dinerCalTextController.text != ''
                                                    ? double.parse(_model.dinerCalTextController.text)
                                                    : 0.0) +
                                                (_model.snackCalTextController.text != null && _model.snackCalTextController.text != '' ? double.parse(_model.snackCalTextController.text) : 0.0);
                                            _model.modification = true;
                                            safeSetState(() {});
                                          },
                                        ),
                                        autofocus: false,
                                        obscureText: false,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          labelStyle: FlutterFlowTheme.of(
                                                  context)
                                              .labelMedium
                                              .override(
                                                font: GoogleFonts.poppins(
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
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .fontStyle,
                                              ),
                                          hintText: goalUserGoalRow
                                                      ?.breakfastCalorie !=
                                                  null
                                              ? ''
                                              : 'Combien de calorie voulez vous manger par jour ?',
                                          hintStyle: FlutterFlowTheme.of(
                                                  context)
                                              .labelMedium
                                              .override(
                                                font: GoogleFonts.poppins(
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
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0x00000000),
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .error,
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .error,
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          filled: true,
                                          fillColor:
                                              FlutterFlowTheme.of(context)
                                                  .secondaryBackground,
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
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                        keyboardType: TextInputType.number,
                                        cursorColor:
                                            FlutterFlowTheme.of(context)
                                                .primaryText,
                                        enableInteractiveSelection: true,
                                        validator: _model
                                            .breakfastCalTextControllerValidator
                                            .asValidator(context),
                                      ),
                                    ),
                                  ].divide(SizedBox(height: 5.0)),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.lunch_dining_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .secondary,
                                          size: 24.0,
                                        ),
                                        Text(
                                          FFLocalizations.of(context).getText(
                                            '3cdofq0f' /* Vos calorie du déjenuer */,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .titleMedium
                                              .override(
                                                font: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleMedium
                                                          .fontStyle,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .fontStyle,
                                              ),
                                        ),
                                      ].divide(SizedBox(width: 5.0)),
                                    ),
                                    Container(
                                      width: 200.0,
                                      child: TextFormField(
                                        controller:
                                            _model.lunchCalTextController ??=
                                                TextEditingController(
                                          text: goalUserGoalRow?.lunchCalorie !=
                                                  null
                                              ? goalUserGoalRow?.lunchCalorie
                                                  ?.toString()
                                              : '',
                                        ),
                                        focusNode: _model.lunchCalFocusNode,
                                        onChanged: (_) => EasyDebounce.debounce(
                                          '_model.lunchCalTextController',
                                          Duration(milliseconds: 2000),
                                          () async {
                                            logFirebaseEvent(
                                                'EDIT_INFO_LunchCal_ON_TEXTFIELD_CHANGE');
                                            logFirebaseEvent(
                                                'LunchCal_update_page_state');
                                            _model.totalCal = (_model.breakfastCalTextController.text != null && _model.breakfastCalTextController.text != ''
                                                    ? double.parse(_model
                                                        .breakfastCalTextController
                                                        .text)
                                                    : 0.0) +
                                                (_model.lunchCalTextController.text != null &&
                                                        _model.lunchCalTextController.text !=
                                                            ''
                                                    ? double.parse(_model
                                                        .lunchCalTextController
                                                        .text)
                                                    : 0.0) +
                                                (_model.dinerCalTextController.text !=
                                                            null &&
                                                        _model.dinerCalTextController.text != ''
                                                    ? double.parse(_model.dinerCalTextController.text)
                                                    : 0.0) +
                                                (_model.snackCalTextController.text != null && _model.snackCalTextController.text != '' ? double.parse(_model.snackCalTextController.text) : 0.0);
                                            _model.modification = true;
                                            safeSetState(() {});
                                          },
                                        ),
                                        autofocus: false,
                                        obscureText: false,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          labelStyle: FlutterFlowTheme.of(
                                                  context)
                                              .labelMedium
                                              .override(
                                                font: GoogleFonts.poppins(
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
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .fontStyle,
                                              ),
                                          hintText: goalUserGoalRow
                                                      ?.lunchCalorie !=
                                                  null
                                              ? ''
                                              : 'Combien de calorie voulez vous manger par jour ?',
                                          hintStyle: FlutterFlowTheme.of(
                                                  context)
                                              .labelMedium
                                              .override(
                                                font: GoogleFonts.poppins(
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
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0x00000000),
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .error,
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .error,
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          filled: true,
                                          fillColor:
                                              FlutterFlowTheme.of(context)
                                                  .secondaryBackground,
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
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                        keyboardType: TextInputType.number,
                                        cursorColor:
                                            FlutterFlowTheme.of(context)
                                                .primaryText,
                                        enableInteractiveSelection: true,
                                        validator: _model
                                            .lunchCalTextControllerValidator
                                            .asValidator(context),
                                      ),
                                    ),
                                  ].divide(SizedBox(height: 5.0)),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.dinner_dining_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .tertiary,
                                          size: 24.0,
                                        ),
                                        Text(
                                          FFLocalizations.of(context).getText(
                                            'e5bpov0e' /* Vos calorie du dîner */,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .titleMedium
                                              .override(
                                                font: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleMedium
                                                          .fontStyle,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .fontStyle,
                                              ),
                                        ),
                                      ].divide(SizedBox(width: 5.0)),
                                    ),
                                    Container(
                                      width: 200.0,
                                      child: TextFormField(
                                        controller:
                                            _model.dinerCalTextController ??=
                                                TextEditingController(
                                          text: goalUserGoalRow
                                                      ?.dinnerCalorie !=
                                                  null
                                              ? goalUserGoalRow?.dinnerCalorie
                                                  ?.toString()
                                              : '',
                                        ),
                                        focusNode: _model.dinerCalFocusNode,
                                        onChanged: (_) => EasyDebounce.debounce(
                                          '_model.dinerCalTextController',
                                          Duration(milliseconds: 2000),
                                          () async {
                                            logFirebaseEvent(
                                                'EDIT_INFO_DinerCal_ON_TEXTFIELD_CHANGE');
                                            logFirebaseEvent(
                                                'DinerCal_update_page_state');
                                            _model.totalCal = (_model.breakfastCalTextController.text != null && _model.breakfastCalTextController.text != ''
                                                    ? double.parse(_model
                                                        .breakfastCalTextController
                                                        .text)
                                                    : 0.0) +
                                                (_model.lunchCalTextController.text != null &&
                                                        _model.lunchCalTextController.text !=
                                                            ''
                                                    ? double.parse(_model
                                                        .lunchCalTextController
                                                        .text)
                                                    : 0.0) +
                                                (_model.dinerCalTextController.text !=
                                                            null &&
                                                        _model.dinerCalTextController.text != ''
                                                    ? double.parse(_model.dinerCalTextController.text)
                                                    : 0.0) +
                                                (_model.snackCalTextController.text != null && _model.snackCalTextController.text != '' ? double.parse(_model.snackCalTextController.text) : 0.0);
                                            _model.modification = true;
                                            safeSetState(() {});
                                          },
                                        ),
                                        autofocus: false,
                                        obscureText: false,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          labelStyle: FlutterFlowTheme.of(
                                                  context)
                                              .labelMedium
                                              .override(
                                                font: GoogleFonts.poppins(
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
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .fontStyle,
                                              ),
                                          hintText: goalUserGoalRow
                                                      ?.dinnerCalorie !=
                                                  null
                                              ? ''
                                              : 'Combien de calorie voulez vous manger par jour ?',
                                          hintStyle: FlutterFlowTheme.of(
                                                  context)
                                              .labelMedium
                                              .override(
                                                font: GoogleFonts.poppins(
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
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0x00000000),
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .error,
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .error,
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          filled: true,
                                          fillColor:
                                              FlutterFlowTheme.of(context)
                                                  .secondaryBackground,
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
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                        keyboardType: TextInputType.number,
                                        cursorColor:
                                            FlutterFlowTheme.of(context)
                                                .primaryText,
                                        enableInteractiveSelection: true,
                                        validator: _model
                                            .dinerCalTextControllerValidator
                                            .asValidator(context),
                                      ),
                                    ),
                                  ].divide(SizedBox(height: 5.0)),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.cookie_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .accent1,
                                          size: 24.0,
                                        ),
                                        Text(
                                          FFLocalizations.of(context).getText(
                                            'di5zt0mo' /* Vos calorie de la collation */,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .titleMedium
                                              .override(
                                                font: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleMedium
                                                          .fontStyle,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .fontStyle,
                                              ),
                                        ),
                                      ].divide(SizedBox(width: 5.0)),
                                    ),
                                  ].divide(SizedBox(height: 5.0)),
                                ),
                                Container(
                                  width: 200.0,
                                  child: TextFormField(
                                    controller:
                                        _model.snackCalTextController ??=
                                            TextEditingController(
                                      text:
                                          goalUserGoalRow?.snackCalorie != null
                                              ? goalUserGoalRow?.snackCalorie
                                                  ?.toString()
                                              : '',
                                    ),
                                    focusNode: _model.snackCalFocusNode,
                                    onChanged: (_) => EasyDebounce.debounce(
                                      '_model.snackCalTextController',
                                      Duration(milliseconds: 2000),
                                      () async {
                                        logFirebaseEvent(
                                            'EDIT_INFO_SnackCal_ON_TEXTFIELD_CHANGE');
                                        logFirebaseEvent(
                                            'SnackCal_update_page_state');
                                        _model.totalCal = (_model.breakfastCalTextController.text != null && _model.breakfastCalTextController.text != ''
                                                ? double.parse(_model
                                                    .breakfastCalTextController
                                                    .text)
                                                : 0.0) +
                                            (_model.lunchCalTextController.text != null &&
                                                    _model.lunchCalTextController.text !=
                                                        ''
                                                ? double.parse(_model
                                                    .lunchCalTextController
                                                    .text)
                                                : 0.0) +
                                            (_model.dinerCalTextController.text != null &&
                                                    _model.dinerCalTextController.text != ''
                                                ? double.parse(_model.dinerCalTextController.text)
                                                : 0.0) +
                                            (_model.snackCalTextController.text != null && _model.snackCalTextController.text != '' ? double.parse(_model.snackCalTextController.text) : 0.0);
                                        _model.modification = true;
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
                                      hintText: goalUserGoalRow?.snackCalorie !=
                                              null
                                          ? ''
                                          : 'Combien de calorie voulez vous manger par jour ?',
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
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0x00000000),
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .error,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .error,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      filled: true,
                                      fillColor: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
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
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                    keyboardType: TextInputType.number,
                                    cursorColor: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    enableInteractiveSelection: true,
                                    validator: _model
                                        .snackCalTextControllerValidator
                                        .asValidator(context),
                                  ),
                                ),
                                if (_model.modification)
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            FFLocalizations.of(context).getText(
                                              'jzifkgfs' /* Calorie prevue pour la journée */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .titleSmall
                                                .override(
                                                  font: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmall
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmall
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondary,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                          ),
                                          Text(
                                            FFLocalizations.of(context).getText(
                                              '4pfupvos' /* Total des calories de vos repa... */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .titleSmall
                                                .override(
                                                  font: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmall
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmall
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .accent1,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Text(
                                            valueOrDefault<String>(
                                              _model.dailyCal?.toString(),
                                              '0',
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .titleSmall
                                                .override(
                                                  font: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmall
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmall
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondary,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                          ),
                                          Text(
                                            valueOrDefault<String>(
                                              _model.totalCal?.toString(),
                                              '0',
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .titleSmall
                                                .override(
                                                  font: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmall
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmall
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .accent1,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ].divide(SizedBox(width: 5.0)),
                                  ),
                                if (_model.error == true)
                                  Text(
                                    FFLocalizations.of(context).getText(
                                      'd0454uz4' /* Veuillez accorder les calories... */,
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .override(
                                          font: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .error,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                if (_model.error == true)
                                  Text(
                                    FFLocalizations.of(context).getText(
                                      'eav4ua34' /* le total des calorie de la jou... */,
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
                                          color: FlutterFlowTheme.of(context)
                                              .error,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    FFButtonWidget(
                                      onPressed: () async {
                                        logFirebaseEvent(
                                            'EDIT_INFO_PAGE_METTRE__JOUR_BTN_ON_TAP');
                                        if (((_model.breakfastCalTextController.text != null && _model.breakfastCalTextController.text != ''
                                                    ? double.parse(_model
                                                        .breakfastCalTextController
                                                        .text)
                                                    : 0.0) +
                                                (_model.lunchCalTextController.text != null && _model.lunchCalTextController.text != ''
                                                    ? double.parse(_model
                                                        .lunchCalTextController
                                                        .text)
                                                    : 0.0) +
                                                (_model.dinerCalTextController.text != null && _model.dinerCalTextController.text != ''
                                                    ? double.parse(_model
                                                        .dinerCalTextController
                                                        .text)
                                                    : 0.0) +
                                                (_model.snackCalTextController.text !=
                                                            null &&
                                                        _model.snackCalTextController.text != ''
                                                    ? double.parse(_model.snackCalTextController.text)
                                                    : 0.0)) ==
                                            _model.dailyCal) {
                                          if (goalUserGoalRow?.id != null &&
                                              goalUserGoalRow?.id != '') {
                                            logFirebaseEvent(
                                                'Button_backend_call');
                                            _model.updateCalGoal =
                                                await UserGoalTable().update(
                                              data: {
                                                'lunch_calorie':
                                                    double.tryParse(_model
                                                        .lunchCalTextController
                                                        .text),
                                                'dinner_calorie':
                                                    double.tryParse(_model
                                                        .dinerCalTextController
                                                        .text),
                                                'snack_calorie':
                                                    double.tryParse(_model
                                                        .snackCalTextController
                                                        .text),
                                                'breakfast_calorie':
                                                    double.tryParse(_model
                                                        .breakfastCalTextController
                                                        .text),
                                                'target_calorie':
                                                    goalUserGoalRow
                                                        ?.targetCalorie,
                                              },
                                              matchingRows: (rows) =>
                                                  rows.eqOrNull(
                                                'id',
                                                goalUserGoalRow?.id,
                                              ),
                                              returnRows: true,
                                            );
                                          } else {
                                            logFirebaseEvent(
                                                'Button_backend_call');
                                            _model.newCalGoal =
                                                await UserGoalTable().insert({
                                              'breakfast_calorie':
                                                  double.tryParse(_model
                                                      .breakfastCalTextController
                                                      .text),
                                              'lunch_calorie': double.tryParse(
                                                  _model.lunchCalTextController
                                                      .text),
                                              'dinner_calorie': double.tryParse(
                                                  _model.dinerCalTextController
                                                      .text),
                                              'snack_calorie':
                                                  goalUserGoalRow?.snackCalorie,
                                              'user_id': valueOrDefault(
                                                  currentUserDocument?.id, 0),
                                              'target_calorie': double.tryParse(
                                                  _model.dailyCalTextController
                                                      .text),
                                            });
                                          }

                                          logFirebaseEvent(
                                              'Button_refresh_database_request');
                                          safeSetState(() =>
                                              _model.requestCompleter3 = null);
                                          await _model
                                              .waitForRequestCompleted3();
                                          logFirebaseEvent(
                                              'Button_update_page_state');
                                          _model.modification = false;
                                          safeSetState(() {});
                                        } else {
                                          logFirebaseEvent(
                                              'Button_update_page_state');
                                          _model.error = true;
                                          safeSetState(() {});
                                        }

                                        safeSetState(() {});
                                      },
                                      text: FFLocalizations.of(context).getText(
                                        '5hfpn4hp' /* Mettre à jour */,
                                      ),
                                      options: FFButtonOptions(
                                        height: 40.0,
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            16.0, 0.0, 16.0, 0.0),
                                        iconPadding:
                                            EdgeInsetsDirectional.fromSTEB(
                                                0.0, 0.0, 0.0, 0.0),
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        textStyle: FlutterFlowTheme.of(context)
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
                                              color: Colors.white,
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
                                        elevation: 0.0,
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                  ],
                                ),
                              ]
                                  .divide(SizedBox(height: 15.0))
                                  .addToStart(SizedBox(height: 15.0))
                                  .addToEnd(SizedBox(height: 15.0)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional(0.0, 0.05),
                  child: AuthUserStreamWidget(
                    builder: (context) => FutureBuilder<List<MealPlanRow>>(
                      future: MealPlanTable().queryRows(
                        queryFn: (q) => q
                            .lteOrNull(
                              'start_date',
                              supaSerialize<DateTime>(getCurrentTimestamp),
                            )
                            .gteOrNull(
                              'end_date',
                              supaSerialize<DateTime>(getCurrentTimestamp),
                            )
                            .eqOrNull(
                              'user_id',
                              valueOrDefault(currentUserDocument?.id, 0),
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
                        List<MealPlanRow> containerMealPlanRowList =
                            snapshot.data!;

                        return Container(
                          decoration: BoxDecoration(),
                        );
                      },
                    ),
                  ),
                ),
                Text(
                  FFLocalizations.of(context).getText(
                    'd5abiyun' /* Voulez vous générer un plan ? */,
                  ),
                  style: FlutterFlowTheme.of(context).titleLarge.override(
                        font: GoogleFonts.outfit(
                          fontWeight: FlutterFlowTheme.of(context)
                              .titleLarge
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).titleLarge.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).titleLarge.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleLarge.fontStyle,
                      ),
                ),
                Align(
                  alignment: AlignmentDirectional(0.0, 0.05),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 0.0),
                    child: FFButtonWidget(
                      onPressed: () async {
                        logFirebaseEvent('EDIT_INFO_PAGE_GNRER_BTN_ON_TAP');
                        logFirebaseEvent('Button_backend_call');
                        _model.dietPlan = await SupabaseGroup.dietPlanCall.call(
                          userId: valueOrDefault(currentUserDocument?.id, 0),
                        );

                        if (DietPlanDataStruct.maybeFromMap(
                                (_model.dietPlan?.jsonBody ?? ''))!
                            .success) {
                          logFirebaseEvent('Button_navigate_to');

                          context.pushNamed(DietPlanWidget.routeName);
                        } else {
                          logFirebaseEvent('Button_bottom_sheet');
                          await showModalBottomSheet(
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            enableDrag: false,
                            context: context,
                            builder: (context) {
                              return WebViewAware(
                                child: Padding(
                                  padding: MediaQuery.viewInsetsOf(context),
                                  child: Container(
                                    height: 400.0,
                                    child: DietPlanErrorWidget(),
                                  ),
                                ),
                              );
                            },
                          ).then((value) => safeSetState(() {}));

                          logFirebaseEvent('Button_update_app_state');
                          FFAppState().missingField = SupabaseGroup.dietPlanCall
                              .missingField(
                                (_model.dietPlan?.jsonBody ?? ''),
                              )!
                              .toList()
                              .cast<String>();
                          FFAppState().missingTable = SupabaseGroup.dietPlanCall
                              .tables(
                                (_model.dietPlan?.jsonBody ?? ''),
                              )!
                              .toList()
                              .cast<String>();
                          safeSetState(() {});
                        }

                        safeSetState(() {});
                      },
                      text: FFLocalizations.of(context).getText(
                        'rszmdag7' /* Générer */,
                      ),
                      options: FFButtonOptions(
                        width: 150.0,
                        height: 50.0,
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        iconPadding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle:
                            FlutterFlowTheme.of(context).titleMedium.override(
                                  font: GoogleFonts.poppins(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                                  color: Colors.white,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontStyle,
                                ),
                        elevation: 2.0,
                        borderSide: BorderSide(
                          color: Colors.transparent,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
              ].divide(SizedBox(height: 15.0)),
            ),
          ),
        ),
      ),
    );
  }
}
