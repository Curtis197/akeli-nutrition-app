import '/a_i_assistant/ai_thread/ai_thread_widget.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_count_controller.dart';
import '/flutter_flow/flutter_flow_radio_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/home_page/weight_graph/weight_graph_widget.dart';
import '/recipe_management/recipe_card_mini/recipe_card_mini_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'package:badges/badges.dart' as badges;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'home_page_model.dart';
export 'home_page_model.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget>
    with TickerProviderStateMixin {
  late HomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());

    logFirebaseEvent('screen_view', parameters: {'screen_name': 'HomePage'});
    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      logFirebaseEvent('HOME_PAGE_PAGE_HomePage_ON_INIT_STATE');
      logFirebaseEvent('HomePage_wait__delay');
      await Future.delayed(
        Duration(
          milliseconds: 1000,
        ),
      );
      logFirebaseEvent('HomePage_backend_call');
      _model.userContext = await SupabaseGroup.userContextCall.call(
        userId: valueOrDefault(currentUserDocument?.id, 0),
      );

      logFirebaseEvent('HomePage_backend_call');
      _model.querriedMealPlan = await MealPlanTable().queryRows(
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
      logFirebaseEvent('HomePage_update_app_state');
      FFAppState().mealPlan = _model.querriedMealPlan!.firstOrNull!.id;
      safeSetState(() {});
      logFirebaseEvent('HomePage_backend_call');
      _model.lastConnection = await UserSubscriptionTable().update(
        data: {
          'last_connection': supaSerialize<DateTime>(getCurrentTimestamp),
        },
        matchingRows: (rows) => rows.eqOrNull(
          'user_id',
          valueOrDefault(currentUserDocument?.id, 0),
        ),
        returnRows: true,
      );
      if ((_model.userContext?.succeeded ?? true)) {
        logFirebaseEvent('HomePage_update_app_state');
        FFAppState().userContext = SupabaseGroup.userContextCall.userContext(
          (_model.userContext?.jsonBody ?? ''),
        );
        safeSetState(() {});
      }
    });

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
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return FutureBuilder<List<UsersRow>>(
      future: UsersTable().querySingleRow(
        queryFn: (q) => q.eqOrNull(
          'user_id',
          currentUserUid,
        ),
      ),
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
        List<UsersRow> homePageUsersRowList = snapshot.data!;

        final homePageUsersRow =
            homePageUsersRowList.isNotEmpty ? homePageUsersRowList.first : null;

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
            floatingActionButton: Visibility(
              visible: homePageUsersRow?.paidPlan ?? true,
              child: FloatingActionButton(
                onPressed: () async {
                  logFirebaseEvent('HOME_FloatingActionButton_g5b3enwv_ON_TA');
                  if (_model.aiChat) {
                    logFirebaseEvent('FloatingActionButton_update_page_state');
                    _model.aiChat = false;
                    safeSetState(() {});
                  } else {
                    logFirebaseEvent('FloatingActionButton_update_page_state');
                    _model.aiChat = true;
                    safeSetState(() {});
                  }
                },
                backgroundColor: FlutterFlowTheme.of(context).primary,
                elevation: 8.0,
                child: Icon(
                  Icons.auto_awesome,
                  color: FlutterFlowTheme.of(context).info,
                  size: 24.0,
                ),
              ),
            ),
            body: NestedScrollView(
              floatHeaderSlivers: true,
              headerSliverBuilder: (context, _) => [
                SliverAppBar(
                  pinned: false,
                  floating: true,
                  snap: false,
                  backgroundColor:
                      FlutterFlowTheme.of(context).secondaryBackground,
                  automaticallyImplyLeading: false,
                  leading: Container(
                    decoration: BoxDecoration(),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            if (homePageUsersRow?.profilImageUrl == null ||
                                homePageUsersRow?.profilImageUrl == '')
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    10.0, 10.0, 0.0, 0.0),
                                child: InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    logFirebaseEvent(
                                        'HOME_CircleImage_pcfryidh_ON_TAP');
                                    logFirebaseEvent('CircleImage_navigate_to');

                                    context.pushNamed(
                                      UserprofileWidget.routeName,
                                      queryParameters: {
                                        'users': serializeParam(
                                          homePageUsersRow,
                                          ParamType.SupabaseRow,
                                        ),
                                      }.withoutNulls,
                                    );
                                  },
                                  child: Container(
                                    width: 40.0,
                                    height: 40.0,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: Image.network(
                                      'https://jfbfymiyqlyciapfloug.supabase.co/storage/v1/object/public/images/group_photo/360_F_65772719_A1UV5kLi5nCEWI0BNLLiFaBPEkUbv5Fv.jpg',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            if (homePageUsersRow?.profilImageUrl != null &&
                                homePageUsersRow?.profilImageUrl != '')
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    10.0, 10.0, 0.0, 0.0),
                                child: InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    logFirebaseEvent(
                                        'HOME_CircleImage_5vws1i8r_ON_TAP');
                                    logFirebaseEvent('CircleImage_navigate_to');

                                    context.pushNamed(
                                      UserprofileWidget.routeName,
                                      queryParameters: {
                                        'users': serializeParam(
                                          homePageUsersRow,
                                          ParamType.SupabaseRow,
                                        ),
                                      }.withoutNulls,
                                    );
                                  },
                                  child: Container(
                                    width: 40.0,
                                    height: 40.0,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: Image.network(
                                      homePageUsersRow!.profilImageUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    FutureBuilder<List<TotalNotificationsRow>>(
                      future: TotalNotificationsTable().querySingleRow(
                        queryFn: (q) => q.eqOrNull(
                          'user_id',
                          homePageUsersRow?.id,
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
                        List<TotalNotificationsRow>
                            containerTotalNotificationsRowList = snapshot.data!;

                        final containerTotalNotificationsRow =
                            containerTotalNotificationsRowList.isNotEmpty
                                ? containerTotalNotificationsRowList.first
                                : null;

                        return InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            logFirebaseEvent(
                                'HOME_PAGE_PAGE_Container_2ebw0gjm_ON_TAP');
                            logFirebaseEvent('Container_navigate_to');

                            context.pushNamed(NotificationsWidget.routeName);
                          },
                          child: Container(
                            width: 60.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (containerTotalNotificationsRow
                                        ?.totalNotification !=
                                    null)
                                  badges.Badge(
                                    badgeContent: Text(
                                      containerTotalNotificationsRow!
                                          .totalNotification!
                                          .toString(),
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
                                    showBadge: true,
                                    shape: badges.BadgeShape.circle,
                                    badgeColor:
                                        FlutterFlowTheme.of(context).secondary,
                                    elevation: 4.0,
                                    padding: EdgeInsets.all(5.0),
                                    position: badges.BadgePosition.topEnd(),
                                    animationType:
                                        badges.BadgeAnimationType.scale,
                                    toAnimate: true,
                                    child: Icon(
                                      Icons.notifications_sharp,
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      size: 32.0,
                                    ),
                                  ),
                                if (containerTotalNotificationsRow
                                        ?.totalNotification ==
                                    null)
                                  Icon(
                                    Icons.notifications_sharp,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 32.0,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 15.0, 0.0),
                      child: InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          logFirebaseEvent(
                              'HOME_PAGE_PAGE_Icon_0m8iyu5l_ON_TAP');
                          logFirebaseEvent('Icon_navigate_to');

                          context.pushNamed(ProfileSettingWidget.routeName);
                        },
                        child: Icon(
                          Icons.settings_sharp,
                          color: FlutterFlowTheme.of(context).secondary,
                          size: 32.0,
                        ),
                      ),
                    ),
                  ],
                  centerTitle: true,
                  elevation: 0.0,
                )
              ],
              body: Builder(
                builder: (context) {
                  return SafeArea(
                    top: false,
                    child: Stack(
                      children: [
                        Align(
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                if (homePageUsersRow?.userName != null &&
                                    homePageUsersRow?.userName != '')
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        20.0, 30.0, 20.0, 30.0),
                                    child: Text(
                                      '${valueOrDefault<String>(
                                        FFLocalizations.of(context)
                                            .getVariableText(
                                          frText: 'Bienvenue sur Akeli  ',
                                          enText: 'Welcome to Akeli  ',
                                          arText: '',
                                        ),
                                        'Bienvenue sur Akeli',
                                      )}${homePageUsersRow?.userName}',
                                      textAlign: TextAlign.center,
                                      style: FlutterFlowTheme.of(context)
                                          .headlineLarge
                                          .override(
                                            font: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w500,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .headlineLarge
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .tertiary,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w500,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .headlineLarge
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                if (homePageUsersRow?.userName == null ||
                                    homePageUsersRow?.userName == '')
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        20.0, 30.0, 20.0, 30.0),
                                    child: Text(
                                      FFLocalizations.of(context)
                                          .getVariableText(
                                        frText: 'Bienvenue sur Akeli',
                                        enText: 'Welcome to Akeli  ',
                                        arText: '',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: FlutterFlowTheme.of(context)
                                          .headlineLarge
                                          .override(
                                            font: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w500,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .headlineLarge
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .tertiary,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w500,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .headlineLarge
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    AuthUserStreamWidget(
                                      builder: (context) => FutureBuilder<
                                          List<WeightGraphDataRow>>(
                                        future: (_model.requestCompleter3 ??=
                                                Completer<
                                                    List<WeightGraphDataRow>>()
                                                  ..complete(
                                                      WeightGraphDataTable()
                                                          .querySingleRow(
                                                    queryFn: (q) => q.eqOrNull(
                                                      'user_id',
                                                      valueOrDefault(
                                                          currentUserDocument
                                                              ?.id,
                                                          0),
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
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .tertiary,
                                                  size: 50.0,
                                                ),
                                              ),
                                            );
                                          }
                                          List<WeightGraphDataRow>
                                              weightGraphWeightGraphDataRowList =
                                              snapshot.data!;

                                          // Return an empty Container when the item does not exist.
                                          if (snapshot.data!.isEmpty) {
                                            return Container();
                                          }
                                          final weightGraphWeightGraphDataRow =
                                              weightGraphWeightGraphDataRowList
                                                      .isNotEmpty
                                                  ? weightGraphWeightGraphDataRowList
                                                      .first
                                                  : null;

                                          return InkWell(
                                            splashColor: Colors.transparent,
                                            focusColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            onTap: () async {
                                              logFirebaseEvent(
                                                  'HOME_PAGE_PAGE_Container_7z5umidb_ON_TAP');
                                              logFirebaseEvent(
                                                  'WeightGraph_navigate_to');

                                              context.pushNamed(
                                                  DashWidget.routeName);
                                            },
                                            child: wrapWithModel(
                                              model: _model.weightGraphModel,
                                              updateCallback: () =>
                                                  safeSetState(() {}),
                                              updateOnChange: true,
                                              child: WeightGraphWidget(
                                                weightGraph:
                                                    weightGraphWeightGraphDataRow!,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                FutureBuilder<List<UserHealthParameterRow>>(
                                  future:
                                      (_model.requestCompleter1 ??= Completer<
                                              List<UserHealthParameterRow>>()
                                            ..complete(
                                                UserHealthParameterTable()
                                                    .querySingleRow(
                                              queryFn: (q) => q.eqOrNull(
                                                'user_id',
                                                homePageUsersRow?.id,
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
                                    List<UserHealthParameterRow>
                                        healthParameterUserHealthParameterRowList =
                                        snapshot.data!;

                                    // Return an empty Container when the item does not exist.
                                    if (snapshot.data!.isEmpty) {
                                      return Container();
                                    }
                                    final healthParameterUserHealthParameterRow =
                                        healthParameterUserHealthParameterRowList
                                                .isNotEmpty
                                            ? healthParameterUserHealthParameterRowList
                                                .first
                                            : null;

                                    return Column(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        if (healthParameterUserHealthParameterRow
                                                ?.weight !=
                                            null)
                                          Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'd9cj8ct8' /* Mettre à jour son poids */,
                                                ),
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .headlineSmall
                                                    .override(
                                                      font: GoogleFonts.outfit(
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
                                              FutureBuilder<
                                                  List<UpdatedWeightRow>>(
                                                future: (_model
                                                            .requestCompleter2 ??=
                                                        Completer<
                                                            List<
                                                                UpdatedWeightRow>>()
                                                          ..complete(
                                                              UpdatedWeightTable()
                                                                  .queryRows(
                                                            queryFn: (q) => q
                                                                .eqOrNull(
                                                                  'user_id',
                                                                  homePageUsersRow
                                                                      ?.id,
                                                                )
                                                                .order(
                                                                    'created_at',
                                                                    ascending:
                                                                        true),
                                                          )))
                                                    .future,
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
                                                  List<UpdatedWeightRow>
                                                      updatedWeightUpdatedWeightRowList =
                                                      snapshot.data!;

                                                  return Container(
                                                    decoration: BoxDecoration(),
                                                    child: Container(
                                                      width: 250.0,
                                                      height: 100.0,
                                                      decoration: BoxDecoration(
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .secondaryBackground,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                        shape:
                                                            BoxShape.rectangle,
                                                      ),
                                                      child:
                                                          FlutterFlowCountController(
                                                        decrementIconBuilder:
                                                            (enabled) => Icon(
                                                          Icons.remove_rounded,
                                                          color: enabled
                                                              ? FlutterFlowTheme
                                                                      .of(
                                                                          context)
                                                                  .secondaryText
                                                              : FlutterFlowTheme
                                                                      .of(context)
                                                                  .alternate,
                                                          size: 40.0,
                                                        ),
                                                        incrementIconBuilder:
                                                            (enabled) => Icon(
                                                          Icons.add_rounded,
                                                          color: enabled
                                                              ? FlutterFlowTheme
                                                                      .of(
                                                                          context)
                                                                  .primary
                                                              : FlutterFlowTheme
                                                                      .of(context)
                                                                  .alternate,
                                                          size: 40.0,
                                                        ),
                                                        countBuilder: (count) =>
                                                            Text(
                                                          count.toString(),
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .titleLarge
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleLarge
                                                                      .fontStyle,
                                                                ),
                                                                fontSize: 48.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleLarge
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                        count: _model
                                                                .countControllerValue ??=
                                                            updatedWeightUpdatedWeightRowList
                                                                    .isNotEmpty
                                                                ? updatedWeightUpdatedWeightRowList
                                                                    .lastOrNull!
                                                                    .weight!
                                                                : healthParameterUserHealthParameterRow!
                                                                    .weight!,
                                                        updateCount:
                                                            (count) async {
                                                          safeSetState(() =>
                                                              _model.countControllerValue =
                                                                  count);
                                                          logFirebaseEvent(
                                                              'HOME_CountController_9e5p9aut_ON_FORM_WI');
                                                          logFirebaseEvent(
                                                              'CountController_backend_call');
                                                          _model.currentWeightUpdate =
                                                              await UpdatedWeightTable()
                                                                  .queryRows(
                                                            queryFn: (q) => q
                                                                .eqOrNull(
                                                                  'date',
                                                                  supaSerialize<
                                                                          DateTime>(
                                                                      getCurrentTimestamp),
                                                                )
                                                                .inFilterOrNull(
                                                                  'id',
                                                                  updatedWeightUpdatedWeightRowList
                                                                      .map((e) =>
                                                                          e.id)
                                                                      .toList(),
                                                                ),
                                                          );
                                                          if (_model.currentWeightUpdate !=
                                                                  null &&
                                                              (_model.currentWeightUpdate)!
                                                                  .isNotEmpty) {
                                                            logFirebaseEvent(
                                                                'CountController_backend_call');
                                                            _model.updatedWeight2 =
                                                                await UpdatedWeightTable()
                                                                    .update(
                                                              data: {
                                                                'weight': _model
                                                                    .countControllerValue,
                                                              },
                                                              matchingRows:
                                                                  (rows) => rows
                                                                      .eqOrNull(
                                                                'id',
                                                                _model
                                                                    .currentWeightUpdate
                                                                    ?.firstOrNull
                                                                    ?.id,
                                                              ),
                                                              returnRows: true,
                                                            );
                                                          } else {
                                                            logFirebaseEvent(
                                                                'CountController_backend_call');
                                                            _model.insertWeight =
                                                                await UpdatedWeightTable()
                                                                    .insert({
                                                              'user_id':
                                                                  homePageUsersRow
                                                                      ?.id,
                                                              'date': supaSerialize<
                                                                      DateTime>(
                                                                  getCurrentTimestamp),
                                                              'weight': _model
                                                                  .countControllerValue,
                                                            });
                                                          }

                                                          logFirebaseEvent(
                                                              'CountController_refresh_database_request');
                                                          safeSetState(() =>
                                                              _model.requestCompleter2 =
                                                                  null);
                                                          logFirebaseEvent(
                                                              'CountController_refresh_database_request');
                                                          safeSetState(() =>
                                                              _model.requestCompleter3 =
                                                                  null);
                                                          logFirebaseEvent(
                                                              'CountController_refresh_database_request');
                                                          safeSetState(() =>
                                                              _model.requestCompleter1 =
                                                                  null);
                                                          await _model
                                                              .waitForRequestCompleted1();

                                                          safeSetState(() {});
                                                        },
                                                        stepSize: 1,
                                                        contentPadding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    12.0,
                                                                    0.0,
                                                                    12.0,
                                                                    0.0),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ].divide(SizedBox(height: 15.0)),
                                          ),
                                        if (healthParameterUserHealthParameterRow
                                                ?.weight ==
                                            null)
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    10.0, 0.0, 10.0, 0.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryBackground,
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Text(
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                      'h5sscsov' /* Votre poids n'est pas encore e... */,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .titleLarge
                                                        .override(
                                                          font: GoogleFonts
                                                              .outfit(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleLarge
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleLarge
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleLarge
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleLarge
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                  Text(
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                      '13jea5qn' /* Veuillez entrer vos paramètres */,
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .labelLarge
                                                        .override(
                                                          font: GoogleFonts
                                                              .poppins(
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
                                                  FFButtonWidget(
                                                    onPressed: () async {
                                                      logFirebaseEvent(
                                                          'HOME_PAGE_PAGE_COMMENCER_BTN_ON_TAP');
                                                      logFirebaseEvent(
                                                          'Button_navigate_to');

                                                      context.pushNamed(
                                                          EditInfoWidget
                                                              .routeName);
                                                    },
                                                    text: FFLocalizations.of(
                                                            context)
                                                        .getText(
                                                      'z1wbuu3i' /* Commencer */,
                                                    ),
                                                    options: FFButtonOptions(
                                                      height: 40.0,
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  16.0,
                                                                  0.0,
                                                                  16.0,
                                                                  0.0),
                                                      iconPadding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  0.0,
                                                                  0.0,
                                                                  0.0),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      textStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleSmall
                                                              .override(
                                                                font: GoogleFonts
                                                                    .poppins(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmall
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmall
                                                                      .fontStyle,
                                                                ),
                                                                color: Colors
                                                                    .white,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleSmall
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleSmall
                                                                    .fontStyle,
                                                              ),
                                                      elevation: 0.0,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                    ),
                                                  ),
                                                ].divide(
                                                    SizedBox(height: 10.0)),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                Divider(
                                  thickness: 2.0,
                                  color: FlutterFlowTheme.of(context).alternate,
                                ),
                                FutureBuilder<List<ConversationDemandRow>>(
                                  future:
                                      (_model.requestCompleter6 ??= Completer<
                                              List<ConversationDemandRow>>()
                                            ..complete(ConversationDemandTable()
                                                .queryRows(
                                              queryFn: (q) => q.eqOrNull(
                                                'destined_user',
                                                homePageUsersRow?.id,
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
                                    List<ConversationDemandRow>
                                        conversationDemandConversationDemandRowList =
                                        snapshot.data!;

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                        borderRadius:
                                            BorderRadius.circular(0.0),
                                      ),
                                      child: Visibility(
                                        visible:
                                            conversationDemandConversationDemandRowList
                                                .isNotEmpty,
                                        child: Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  '090sjsix' /* Demandes */,
                                                ),
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .titleLarge
                                                    .override(
                                                      font: GoogleFonts.outfit(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleLarge
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleLarge
                                                                .fontStyle,
                                                      ),
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleLarge
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleLarge
                                                              .fontStyle,
                                                    ),
                                              ),
                                              Builder(
                                                builder: (context) {
                                                  final containerVar =
                                                      conversationDemandConversationDemandRowList
                                                          .toList();

                                                  return ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    primary: false,
                                                    shrinkWrap: true,
                                                    scrollDirection:
                                                        Axis.vertical,
                                                    itemCount:
                                                        containerVar.length,
                                                    itemBuilder: (context,
                                                        containerVarIndex) {
                                                      final containerVarItem =
                                                          containerVar[
                                                              containerVarIndex];
                                                      return Padding(
                                                        padding:
                                                            EdgeInsets.all(8.0),
                                                        child: FutureBuilder<
                                                            List<UsersRow>>(
                                                          future: UsersTable()
                                                              .querySingleRow(
                                                            queryFn: (q) =>
                                                                q.eqOrNull(
                                                              'id',
                                                              containerVarItem
                                                                  .userId,
                                                            ),
                                                          ),
                                                          builder: (context,
                                                              snapshot) {
                                                            // Customize what your widget looks like when it's loading.
                                                            if (!snapshot
                                                                .hasData) {
                                                              return Center(
                                                                child: SizedBox(
                                                                  width: 50.0,
                                                                  height: 50.0,
                                                                  child:
                                                                      SpinKitDoubleBounce(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .tertiary,
                                                                    size: 50.0,
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                            List<UsersRow>
                                                                rowUsersRowList =
                                                                snapshot.data!;

                                                            final rowUsersRow =
                                                                rowUsersRowList
                                                                        .isNotEmpty
                                                                    ? rowUsersRowList
                                                                        .first
                                                                    : null;

                                                            return Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              children: [
                                                                Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    if (homePageUsersRow?.profilImageUrl !=
                                                                            null &&
                                                                        homePageUsersRow?.profilImageUrl !=
                                                                            '')
                                                                      ClipRRect(
                                                                        borderRadius:
                                                                            BorderRadius.circular(50.0),
                                                                        child: Image
                                                                            .network(
                                                                          homePageUsersRow!
                                                                              .profilImageUrl!,
                                                                          width:
                                                                              50.0,
                                                                          height:
                                                                              50.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                  ],
                                                                ),
                                                                Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    if (homePageUsersRow?.profilImageUrl ==
                                                                            null ||
                                                                        homePageUsersRow?.profilImageUrl ==
                                                                            '')
                                                                      ClipRRect(
                                                                        borderRadius:
                                                                            BorderRadius.circular(50.0),
                                                                        child: Image
                                                                            .network(
                                                                          'https://jfbfymiyqlyciapfloug.supabase.co/storage/v1/object/public/images/group_photo/360_F_65772719_A1UV5kLi5nCEWI0BNLLiFaBPEkUbv5Fv.jpg',
                                                                          width:
                                                                              50.0,
                                                                          height:
                                                                              50.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                  ],
                                                                ),
                                                                Expanded(
                                                                  child: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    children: [
                                                                      Text(
                                                                        valueOrDefault<
                                                                            String>(
                                                                          rowUsersRow
                                                                              ?.userName,
                                                                          'user name',
                                                                        ),
                                                                        style: FlutterFlowTheme.of(context)
                                                                            .bodyLarge
                                                                            .override(
                                                                              font: GoogleFonts.poppins(
                                                                                fontWeight: FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                                                                                fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                                                                              ),
                                                                              letterSpacing: 0.0,
                                                                              fontWeight: FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                                                                              fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                                                                            ),
                                                                      ),
                                                                      Text(
                                                                        valueOrDefault<
                                                                            String>(
                                                                          rowUsersRow
                                                                              ?.description,
                                                                          'user description',
                                                                        ),
                                                                        style: FlutterFlowTheme.of(context)
                                                                            .bodySmall
                                                                            .override(
                                                                              font: GoogleFonts.poppins(
                                                                                fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                              ),
                                                                              letterSpacing: 0.0,
                                                                              fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                              fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                            ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                InkWell(
                                                                  splashColor:
                                                                      Colors
                                                                          .transparent,
                                                                  focusColor: Colors
                                                                      .transparent,
                                                                  hoverColor: Colors
                                                                      .transparent,
                                                                  highlightColor:
                                                                      Colors
                                                                          .transparent,
                                                                  onTap:
                                                                      () async {
                                                                    logFirebaseEvent(
                                                                        'HOME_PAGE_PAGE_Icon_b4v1oqjd_ON_TAP');
                                                                    logFirebaseEvent(
                                                                        'Icon_backend_call');
                                                                    await ConversationDemandTable()
                                                                        .delete(
                                                                      matchingRows:
                                                                          (rows) =>
                                                                              rows.eqOrNull(
                                                                        'id',
                                                                        containerVarItem
                                                                            .id,
                                                                      ),
                                                                    );
                                                                    logFirebaseEvent(
                                                                        'Icon_refresh_database_request');
                                                                    safeSetState(() =>
                                                                        _model.requestCompleter6 =
                                                                            null);
                                                                    await _model
                                                                        .waitForRequestCompleted6();
                                                                    logFirebaseEvent(
                                                                        'Icon_backend_call');
                                                                    _model.apiResultxvc =
                                                                        await SupabaseGroup
                                                                            .conversationAcceptedCall
                                                                            .call(
                                                                      demandId: _model
                                                                          .deletedDemand
                                                                          ?.firstOrNull
                                                                          ?.id,
                                                                      responderUserId:
                                                                          valueOrDefault(
                                                                              currentUserDocument?.id,
                                                                              0),
                                                                      grouped:
                                                                          false,
                                                                      accepted:
                                                                          false,
                                                                      destinedUserId: _model
                                                                          .deletedDemand
                                                                          ?.firstOrNull
                                                                          ?.destinedUser,
                                                                      userId: valueOrDefault(
                                                                          currentUserDocument
                                                                              ?.id,
                                                                          0),
                                                                    );

                                                                    safeSetState(
                                                                        () {});
                                                                  },
                                                                  child: Icon(
                                                                    Icons
                                                                        .delete,
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondary,
                                                                    size: 24.0,
                                                                  ),
                                                                ),
                                                                FFButtonWidget(
                                                                  onPressed:
                                                                      () async {
                                                                    logFirebaseEvent(
                                                                        'HOME_PAGE_PAGE_ACCEPTER_BTN_ON_TAP');
                                                                    logFirebaseEvent(
                                                                        'Button_backend_call');
                                                                    _model.newConversation =
                                                                        await SupabaseGroup
                                                                            .findOrCreateTheConversationCall
                                                                            .call(
                                                                      destinedUserId:
                                                                          rowUsersRow
                                                                              ?.id,
                                                                      userId: valueOrDefault(
                                                                          currentUserDocument
                                                                              ?.id,
                                                                          0),
                                                                    );

                                                                    if ((_model
                                                                            .newConversation
                                                                            ?.succeeded ??
                                                                        true)) {
                                                                      logFirebaseEvent(
                                                                          'Button_backend_call');
                                                                      await ConversationDemandTable()
                                                                          .delete(
                                                                        matchingRows:
                                                                            (rows) =>
                                                                                rows.eqOrNull(
                                                                          'id',
                                                                          containerVarItem
                                                                              .id,
                                                                        ),
                                                                      );
                                                                      logFirebaseEvent(
                                                                          'Button_backend_call');
                                                                      _model.queriedChat =
                                                                          await ChatConversationTable()
                                                                              .queryRows(
                                                                        queryFn:
                                                                            (q) =>
                                                                                q.eqOrNull(
                                                                          'id',
                                                                          SupabaseGroup
                                                                              .findOrCreateTheConversationCall
                                                                              .conversationId(
                                                                            (_model.newConversation?.jsonBody ??
                                                                                ''),
                                                                          ),
                                                                        ),
                                                                      );
                                                                      logFirebaseEvent(
                                                                          'Button_navigate_to');

                                                                      context
                                                                          .pushNamed(
                                                                        ChatPageWidget
                                                                            .routeName,
                                                                        queryParameters:
                                                                            {
                                                                          'conversation':
                                                                              serializeParam(
                                                                            _model.queriedChat?.firstOrNull,
                                                                            ParamType.SupabaseRow,
                                                                          ),
                                                                          'destinedUserId':
                                                                              serializeParam(
                                                                            rowUsersRow?.id,
                                                                            ParamType.int,
                                                                          ),
                                                                        }.withoutNulls,
                                                                      );
                                                                    }
                                                                    logFirebaseEvent(
                                                                        'Button_refresh_database_request');
                                                                    safeSetState(() =>
                                                                        _model.requestCompleter6 =
                                                                            null);
                                                                    await _model
                                                                        .waitForRequestCompleted6();
                                                                    logFirebaseEvent(
                                                                        'Button_backend_call');
                                                                    _model.apiResultw69 =
                                                                        await SupabaseGroup
                                                                            .conversationAcceptedCall
                                                                            .call(
                                                                      demandId:
                                                                          containerVarItem
                                                                              .id,
                                                                      accepted:
                                                                          true,
                                                                      grouped:
                                                                          true,
                                                                      userId: valueOrDefault(
                                                                          currentUserDocument
                                                                              ?.id,
                                                                          0),
                                                                      destinedUserId:
                                                                          containerVarItem
                                                                              .destinedUser,
                                                                      responderUserId:
                                                                          valueOrDefault(
                                                                              currentUserDocument?.id,
                                                                              0),
                                                                    );

                                                                    safeSetState(
                                                                        () {});
                                                                  },
                                                                  text: FFLocalizations.of(
                                                                          context)
                                                                      .getText(
                                                                    'bzuxe2gd' /* Accepter */,
                                                                  ),
                                                                  options:
                                                                      FFButtonOptions(
                                                                    height:
                                                                        30.0,
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            16.0,
                                                                            0.0,
                                                                            16.0,
                                                                            0.0),
                                                                    iconPadding:
                                                                        EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            0.0,
                                                                            0.0),
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondaryBackground,
                                                                    textStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .titleSmall
                                                                        .override(
                                                                          font:
                                                                              GoogleFonts.poppins(
                                                                            fontWeight:
                                                                                FontWeight.normal,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                          ),
                                                                          color:
                                                                              FlutterFlowTheme.of(context).tertiary,
                                                                          fontSize:
                                                                              14.0,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          fontWeight:
                                                                              FontWeight.normal,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .titleSmall
                                                                              .fontStyle,
                                                                        ),
                                                                    elevation:
                                                                        0.0,
                                                                    borderSide:
                                                                        BorderSide(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .tertiary,
                                                                      width:
                                                                          1.0,
                                                                    ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            8.0),
                                                                  ),
                                                                ),
                                                              ]
                                                                  .divide(SizedBox(
                                                                      width:
                                                                          10.0))
                                                                  .around(SizedBox(
                                                                      width:
                                                                          10.0)),
                                                            );
                                                          },
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ].divide(SizedBox(height: 15.0)),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                FutureBuilder<List<MealPlanRow>>(
                                  future: MealPlanTable().querySingleRow(
                                    queryFn: (q) => q
                                        .eqOrNull(
                                          'user_id',
                                          homePageUsersRow?.id,
                                        )
                                        .gteOrNull(
                                          'end_date',
                                          supaSerialize<DateTime>(
                                              getCurrentTimestamp),
                                        )
                                        .lteOrNull(
                                          'start_date',
                                          supaSerialize<DateTime>(
                                              getCurrentTimestamp),
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
                                    List<MealPlanRow> containerMealPlanRowList =
                                        snapshot.data!;

                                    final containerMealPlanRow =
                                        containerMealPlanRowList.isNotEmpty
                                            ? containerMealPlanRowList.first
                                            : null;

                                    return Container(
                                      decoration: BoxDecoration(),
                                      child: Visibility(
                                        visible:
                                            containerMealPlanRow?.id == null,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                'pgoayffi' /* Vous n'avez pas de repas plann... */,
                                              ),
                                              textAlign: TextAlign.center,
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .titleLarge
                                                      .override(
                                                        font:
                                                            GoogleFonts.outfit(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleLarge
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleLarge
                                                                  .fontStyle,
                                                        ),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleLarge
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleLarge
                                                                .fontStyle,
                                                      ),
                                            ),
                                            Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                '7odrd5k3' /* Voulez vous generer vos repas ... */,
                                              ),
                                              textAlign: TextAlign.center,
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
                                            FFButtonWidget(
                                              onPressed: () async {
                                                logFirebaseEvent(
                                                    'HOME_GNRER_MES_REPAS_BTN_ON_TAP');
                                                logFirebaseEvent(
                                                    'Button_navigate_to');

                                                context.pushNamed(
                                                    EditInfoWidget.routeName);
                                              },
                                              text: FFLocalizations.of(context)
                                                  .getText(
                                                'g510diwv' /* Générer mes repas */,
                                              ),
                                              options: FFButtonOptions(
                                                height: 40.0,
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        16.0, 0.0, 16.0, 0.0),
                                                iconPadding:
                                                    EdgeInsetsDirectional
                                                        .fromSTEB(
                                                            0.0, 0.0, 0.0, 0.0),
                                                color:
                                                    FlutterFlowTheme.of(context)
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
                                          ].divide(SizedBox(height: 10.0)),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 25.0, 0.0, 0.0),
                                  child: FutureBuilder<List<MealPlanRow>>(
                                    future: MealPlanTable().querySingleRow(
                                      queryFn: (q) => q
                                          .eqOrNull(
                                            'user_id',
                                            homePageUsersRow?.id,
                                          )
                                          .gteOrNull(
                                            'end_date',
                                            supaSerialize<DateTime>(
                                                getCurrentTimestamp),
                                          )
                                          .lteOrNull(
                                            'start_date',
                                            supaSerialize<DateTime>(
                                                getCurrentTimestamp),
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
                                                  FlutterFlowTheme.of(context)
                                                      .tertiary,
                                              size: 50.0,
                                            ),
                                          ),
                                        );
                                      }
                                      List<MealPlanRow>
                                          myMealPlanMealPlanRowList =
                                          snapshot.data!;

                                      // Return an empty Container when the item does not exist.
                                      if (snapshot.data!.isEmpty) {
                                        return Container();
                                      }
                                      final myMealPlanMealPlanRow =
                                          myMealPlanMealPlanRowList.isNotEmpty
                                              ? myMealPlanMealPlanRowList.first
                                              : null;

                                      return Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Text(
                                            FFLocalizations.of(context).getText(
                                              '1bpa93ps' /* Mes Repas du jours */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .headlineSmall
                                                .override(
                                                  font: GoogleFonts.outfit(
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
                                          FutureBuilder<List<UserTrackRow>>(
                                            future:
                                                UserTrackTable().querySingleRow(
                                              queryFn: (q) => q
                                                  .eqOrNull(
                                                    'user_id',
                                                    homePageUsersRow?.id,
                                                  )
                                                  .eqOrNull(
                                                    'track_date',
                                                    supaSerialize<DateTime>(
                                                        getCurrentTimestamp),
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
                                              List<UserTrackRow>
                                                  containerUserTrackRowList =
                                                  snapshot.data!;

                                              final containerUserTrackRow =
                                                  containerUserTrackRowList
                                                          .isNotEmpty
                                                      ? containerUserTrackRowList
                                                          .first
                                                      : null;

                                              return Container(
                                                decoration: BoxDecoration(),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    FutureBuilder<
                                                        List<MealRow>>(
                                                      future: (_model
                                                                  .requestCompleter4 ??=
                                                              Completer<
                                                                  List<
                                                                      MealRow>>()
                                                                ..complete(
                                                                    MealTable()
                                                                        .queryRows(
                                                                  queryFn: (q) => q
                                                                      .eqOrNull(
                                                                        'meal_date',
                                                                        supaSerialize<DateTime>(
                                                                            getCurrentTimestamp),
                                                                      )
                                                                      .eqOrNull(
                                                                        'meal_plan_id',
                                                                        myMealPlanMealPlanRow
                                                                            ?.id,
                                                                      ),
                                                                )))
                                                          .future,
                                                      builder:
                                                          (context, snapshot) {
                                                        // Customize what your widget looks like when it's loading.
                                                        if (!snapshot.hasData) {
                                                          return Center(
                                                            child: SizedBox(
                                                              width: 50.0,
                                                              height: 50.0,
                                                              child:
                                                                  SpinKitDoubleBounce(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .tertiary,
                                                                size: 50.0,
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                        List<MealRow>
                                                            mealContainerMealRowList =
                                                            snapshot.data!;

                                                        return Container(
                                                          decoration:
                                                              BoxDecoration(),
                                                          child: Visibility(
                                                            visible:
                                                                mealContainerMealRowList
                                                                    .isNotEmpty,
                                                            child: Builder(
                                                              builder:
                                                                  (context) {
                                                                final containerVar =
                                                                    mealContainerMealRowList
                                                                        .toList();

                                                                return Container(
                                                                  width: double
                                                                      .infinity,
                                                                  height: 300.0,
                                                                  child: CarouselSlider
                                                                      .builder(
                                                                    itemCount:
                                                                        containerVar
                                                                            .length,
                                                                    itemBuilder:
                                                                        (context,
                                                                            containerVarIndex,
                                                                            _) {
                                                                      final containerVarItem =
                                                                          containerVar[
                                                                              containerVarIndex];
                                                                      return Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        children: [
                                                                          if (containerVarItem.generated ??
                                                                              true)
                                                                            Padding(
                                                                              padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 8.0),
                                                                              child: InkWell(
                                                                                splashColor: Colors.transparent,
                                                                                focusColor: Colors.transparent,
                                                                                hoverColor: Colors.transparent,
                                                                                highlightColor: Colors.transparent,
                                                                                onTap: () async {
                                                                                  logFirebaseEvent('HOME_PAGE_PAGE_Container_fh0vhhh6_ON_TAP');
                                                                                  logFirebaseEvent('Container_navigate_to');

                                                                                  context.pushNamed(
                                                                                    MealDetailWidget.routeName,
                                                                                    queryParameters: {
                                                                                      'mealID': serializeParam(
                                                                                        containerVarItem.id,
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
                                                                                                padding: EdgeInsetsDirectional.fromSTEB(10.0, 10.0, 10.0, 0.0),
                                                                                                child: FutureBuilder<List<ReceipeImageRow>>(
                                                                                                  future: ReceipeImageTable().querySingleRow(
                                                                                                    queryFn: (q) => q
                                                                                                        .eqOrNull(
                                                                                                          'receipe_id',
                                                                                                          containerVarItem.receipeId,
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
                                                                                                            color: FlutterFlowTheme.of(context).tertiary,
                                                                                                            size: 50.0,
                                                                                                          ),
                                                                                                        ),
                                                                                                      );
                                                                                                    }
                                                                                                    List<ReceipeImageRow> imageReceipeImageRowList = snapshot.data!;

                                                                                                    final imageReceipeImageRow = imageReceipeImageRowList.isNotEmpty ? imageReceipeImageRowList.first : null;

                                                                                                    return ClipRRect(
                                                                                                      borderRadius: BorderRadius.circular(8.0),
                                                                                                      child: Image.network(
                                                                                                        () {
                                                                                                          if ((containerVarItem.personal == true) && (containerVarItem.imageUrl != null && containerVarItem.imageUrl != '')) {
                                                                                                            return containerVarItem.imageUrl!;
                                                                                                          } else if ((containerVarItem.personal == true) && (containerVarItem.imageUrl == null || containerVarItem.imageUrl == '')) {
                                                                                                            return 'https://jfbfymiyqlyciapfloug.supabase.co/storage/v1/object/public/images/group_photo/pexels-picha-6210449%20(1).jpg';
                                                                                                          } else if (imageReceipeImageRow?.id == null || imageReceipeImageRow?.id == '') {
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
                                                                                                      child: Text(
                                                                                                        valueOrDefault<String>(
                                                                                                          containerVarItem.name,
                                                                                                          'meal name',
                                                                                                        ),
                                                                                                        maxLines: 1,
                                                                                                        style: FlutterFlowTheme.of(context).titleMedium.override(
                                                                                                              font: GoogleFonts.poppins(
                                                                                                                fontWeight: FlutterFlowTheme.of(context).titleMedium.fontWeight,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                                              ),
                                                                                                              color: () {
                                                                                                                if (containerVarItem.mealType == 'breakfast') {
                                                                                                                  return FlutterFlowTheme.of(context).secondary;
                                                                                                                } else if (containerVarItem.mealType == 'lunch') {
                                                                                                                  return FlutterFlowTheme.of(context).tertiary;
                                                                                                                } else if (containerVarItem.mealType == 'snack') {
                                                                                                                  return FlutterFlowTheme.of(context).accent1;
                                                                                                                } else {
                                                                                                                  return FlutterFlowTheme.of(context).primary;
                                                                                                                }
                                                                                                              }(),
                                                                                                              letterSpacing: 0.0,
                                                                                                              fontWeight: FlutterFlowTheme.of(context).titleMedium.fontWeight,
                                                                                                              fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                                            ),
                                                                                                      ),
                                                                                                    ),
                                                                                                    Text(
                                                                                                      '${functions.smartFormatNumber(containerVarItem.adjustedCalories)} kcal',
                                                                                                      style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                                            font: GoogleFonts.poppins(
                                                                                                              fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                                              fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                                            ),
                                                                                                            color: () {
                                                                                                              if (containerVarItem.mealType == 'breakfast') {
                                                                                                                return FlutterFlowTheme.of(context).secondary;
                                                                                                              } else if (containerVarItem.mealType == 'lunch') {
                                                                                                                return FlutterFlowTheme.of(context).tertiary;
                                                                                                              } else if (containerVarItem.mealType == 'snack') {
                                                                                                                return FlutterFlowTheme.of(context).accent1;
                                                                                                              } else {
                                                                                                                return FlutterFlowTheme.of(context).primary;
                                                                                                              }
                                                                                                            }(),
                                                                                                            letterSpacing: 0.0,
                                                                                                            fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                                            fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                                          ),
                                                                                                    ),
                                                                                                    Row(
                                                                                                      mainAxisSize: MainAxisSize.max,
                                                                                                      children: [
                                                                                                        if (containerVarItem.mealType == 'breakfast')
                                                                                                          Icon(
                                                                                                            Icons.wb_sunny_rounded,
                                                                                                            color: FlutterFlowTheme.of(context).secondary,
                                                                                                            size: 24.0,
                                                                                                          ),
                                                                                                        if (containerVarItem.mealType == 'lunch')
                                                                                                          Icon(
                                                                                                            Icons.lunch_dining_rounded,
                                                                                                            color: FlutterFlowTheme.of(context).tertiary,
                                                                                                            size: 24.0,
                                                                                                          ),
                                                                                                        if (containerVarItem.mealType == 'snack')
                                                                                                          Icon(
                                                                                                            Icons.cookie_rounded,
                                                                                                            color: FlutterFlowTheme.of(context).accent1,
                                                                                                            size: 24.0,
                                                                                                          ),
                                                                                                        if (containerVarItem.mealType == 'dinner')
                                                                                                          Icon(
                                                                                                            Icons.dinner_dining_rounded,
                                                                                                            color: FlutterFlowTheme.of(context).primary,
                                                                                                            size: 24.0,
                                                                                                          ),
                                                                                                        Text(
                                                                                                          () {
                                                                                                            if (containerVarItem.mealType == 'breakfast') {
                                                                                                              return 'Petit-Déjenuer';
                                                                                                            } else if (containerVarItem.mealType == 'lunch') {
                                                                                                              return 'Déjeuner';
                                                                                                            } else if (containerVarItem.mealType == 'lunch') {
                                                                                                              return 'Collation';
                                                                                                            } else {
                                                                                                              return 'Dîner';
                                                                                                            }
                                                                                                          }(),
                                                                                                          style: FlutterFlowTheme.of(context).titleSmall.override(
                                                                                                                font: GoogleFonts.poppins(
                                                                                                                  fontWeight: FlutterFlowTheme.of(context).titleSmall.fontWeight,
                                                                                                                  fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                                                ),
                                                                                                                color: () {
                                                                                                                  if (containerVarItem.mealType == 'breakfast') {
                                                                                                                    return FlutterFlowTheme.of(context).secondary;
                                                                                                                  } else if (containerVarItem.mealType == 'lunch') {
                                                                                                                    return FlutterFlowTheme.of(context).tertiary;
                                                                                                                  } else if (containerVarItem.mealType == 'snack') {
                                                                                                                    return FlutterFlowTheme.of(context).accent1;
                                                                                                                  } else {
                                                                                                                    return FlutterFlowTheme.of(context).primary;
                                                                                                                  }
                                                                                                                }(),
                                                                                                                letterSpacing: 0.0,
                                                                                                                fontWeight: FlutterFlowTheme.of(context).titleSmall.fontWeight,
                                                                                                                fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
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
                                                                                      if (containerUserTrackRow?.id != null && containerUserTrackRow?.id != '')
                                                                                        Row(
                                                                                          mainAxisSize: MainAxisSize.max,
                                                                                          children: [
                                                                                            if (myMealPlanMealPlanRow?.id != null)
                                                                                              Expanded(
                                                                                                child: Padding(
                                                                                                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 10.0, 0.0),
                                                                                                  child: Row(
                                                                                                    mainAxisSize: MainAxisSize.max,
                                                                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                                                                    children: [
                                                                                                      if (containerVarItem.consumed == true)
                                                                                                        InkWell(
                                                                                                          splashColor: Colors.transparent,
                                                                                                          focusColor: Colors.transparent,
                                                                                                          hoverColor: Colors.transparent,
                                                                                                          highlightColor: Colors.transparent,
                                                                                                          onTap: () async {
                                                                                                            logFirebaseEvent('HOME_PAGE_PAGE_Icon_cg29gxv2_ON_TAP');
                                                                                                            logFirebaseEvent('Icon_backend_call');
                                                                                                            await MealTable().update(
                                                                                                              data: {
                                                                                                                'consumed': false,
                                                                                                              },
                                                                                                              matchingRows: (rows) => rows.eqOrNull(
                                                                                                                'id',
                                                                                                                containerVarItem.id,
                                                                                                              ),
                                                                                                            );
                                                                                                            logFirebaseEvent('Icon_refresh_database_request');
                                                                                                            safeSetState(() => _model.requestCompleter4 = null);
                                                                                                            logFirebaseEvent('Icon_refresh_database_request');
                                                                                                            safeSetState(() => _model.requestCompleter3 = null);
                                                                                                          },
                                                                                                          child: Icon(
                                                                                                            Icons.check_box,
                                                                                                            color: FlutterFlowTheme.of(context).primary,
                                                                                                            size: 24.0,
                                                                                                          ),
                                                                                                        ),
                                                                                                      if (containerVarItem.consumed == false)
                                                                                                        InkWell(
                                                                                                          splashColor: Colors.transparent,
                                                                                                          focusColor: Colors.transparent,
                                                                                                          hoverColor: Colors.transparent,
                                                                                                          highlightColor: Colors.transparent,
                                                                                                          onTap: () async {
                                                                                                            logFirebaseEvent('HOME_PAGE_PAGE_Icon_gev0xiyp_ON_TAP');
                                                                                                            logFirebaseEvent('Icon_backend_call');
                                                                                                            await MealTable().update(
                                                                                                              data: {
                                                                                                                'consumed': true,
                                                                                                              },
                                                                                                              matchingRows: (rows) => rows.eqOrNull(
                                                                                                                'id',
                                                                                                                containerVarItem.id,
                                                                                                              ),
                                                                                                            );
                                                                                                            logFirebaseEvent('Icon_refresh_database_request');
                                                                                                            safeSetState(() => _model.requestCompleter4 = null);
                                                                                                            logFirebaseEvent('Icon_refresh_database_request');
                                                                                                            safeSetState(() => _model.requestCompleter3 = null);
                                                                                                          },
                                                                                                          child: Icon(
                                                                                                            Icons.check_box_outline_blank,
                                                                                                            color: FlutterFlowTheme.of(context).primary,
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
                                                                          if (!containerVarItem
                                                                              .generated!)
                                                                            Padding(
                                                                              padding: EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 8.0),
                                                                              child: InkWell(
                                                                                splashColor: Colors.transparent,
                                                                                focusColor: Colors.transparent,
                                                                                hoverColor: Colors.transparent,
                                                                                highlightColor: Colors.transparent,
                                                                                onTap: () async {
                                                                                  logFirebaseEvent('HOME_PAGE_PAGE_Container_2k3p4xly_ON_TAP');
                                                                                  logFirebaseEvent('Container_update_app_state');
                                                                                  FFAppState().mealID = containerVarItem.id;
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
                                                                                              if (containerVarItem.mealType == 'breakfast') {
                                                                                                return 'Petit-Déjenuer';
                                                                                              } else if (containerVarItem.mealType == 'lunch') {
                                                                                                return 'Déjeuner';
                                                                                              } else if (containerVarItem.mealType == 'lunch') {
                                                                                                return 'Collation';
                                                                                              } else {
                                                                                                return 'Dîner';
                                                                                              }
                                                                                            }(),
                                                                                            style: FlutterFlowTheme.of(context).titleSmall.override(
                                                                                                  font: GoogleFonts.poppins(
                                                                                                    fontWeight: FlutterFlowTheme.of(context).titleSmall.fontWeight,
                                                                                                    fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                                  ),
                                                                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                                                                  letterSpacing: 0.0,
                                                                                                  fontWeight: FlutterFlowTheme.of(context).titleSmall.fontWeight,
                                                                                                  fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
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
                                                                    },
                                                                    carouselController:
                                                                        _model.carouselController ??=
                                                                            CarouselSliderController(),
                                                                    options:
                                                                        CarouselOptions(
                                                                      initialPage: max(
                                                                          0,
                                                                          min(1,
                                                                              containerVar.length - 1)),
                                                                      viewportFraction:
                                                                          () {
                                                                        if (MediaQuery.sizeOf(context).width <
                                                                            kBreakpointSmall) {
                                                                          return 0.8;
                                                                        } else if (MediaQuery.sizeOf(context).width <
                                                                            kBreakpointMedium) {
                                                                          return 0.5;
                                                                        } else if (MediaQuery.sizeOf(context).width <
                                                                            kBreakpointLarge) {
                                                                          return 0.33;
                                                                        } else {
                                                                          return 0.33;
                                                                        }
                                                                      }(),
                                                                      disableCenter:
                                                                          true,
                                                                      enlargeCenterPage:
                                                                          true,
                                                                      enlargeFactor:
                                                                          0.25,
                                                                      enableInfiniteScroll:
                                                                          true,
                                                                      scrollDirection:
                                                                          Axis.horizontal,
                                                                      autoPlay:
                                                                          false,
                                                                      onPageChanged: (index,
                                                                              _) =>
                                                                          _model.carouselCurrentIndex =
                                                                              index,
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                          Divider(
                                            thickness: 2.0,
                                            color: FlutterFlowTheme.of(context)
                                                .alternate,
                                          ),
                                          FutureBuilder<List<ShoppingListRow>>(
                                            future: ShoppingListTable()
                                                .querySingleRow(
                                              queryFn: (q) => q.eqOrNull(
                                                'meal_plan_id',
                                                myMealPlanMealPlanRow?.id,
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
                                              List<ShoppingListRow>
                                                  shoppingListContainerShoppingListRowList =
                                                  snapshot.data!;

                                              // Return an empty Container when the item does not exist.
                                              if (snapshot.data!.isEmpty) {
                                                return Container();
                                              }
                                              final shoppingListContainerShoppingListRow =
                                                  shoppingListContainerShoppingListRowList
                                                          .isNotEmpty
                                                      ? shoppingListContainerShoppingListRowList
                                                          .first
                                                      : null;

                                              return Container(
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    if (shoppingListContainerShoppingListRow
                                                            ?.id !=
                                                        null)
                                                      Column(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          Text(
                                                            FFLocalizations.of(
                                                                    context)
                                                                .getText(
                                                              'p2x3581d' /* Liste de Course */,
                                                            ),
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .headlineMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .outfit(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .headlineMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .headlineMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .headlineMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .headlineMedium
                                                                      .fontStyle,
                                                                ),
                                                          ),
                                                          InkWell(
                                                            splashColor: Colors
                                                                .transparent,
                                                            focusColor: Colors
                                                                .transparent,
                                                            hoverColor: Colors
                                                                .transparent,
                                                            highlightColor:
                                                                Colors
                                                                    .transparent,
                                                            onTap: () async {
                                                              logFirebaseEvent(
                                                                  'HOME_PAGE_PAGE_Text_q4592jgm_ON_TAP');
                                                              logFirebaseEvent(
                                                                  'Text_navigate_to');

                                                              context.pushNamed(
                                                                ShoppingListWidget
                                                                    .routeName,
                                                                queryParameters:
                                                                    {
                                                                  'shoppingList':
                                                                      serializeParam(
                                                                    shoppingListContainerShoppingListRow,
                                                                    ParamType
                                                                        .SupabaseRow,
                                                                  ),
                                                                }.withoutNulls,
                                                              );
                                                            },
                                                            child: Text(
                                                              FFLocalizations.of(
                                                                      context)
                                                                  .getText(
                                                                'pq5wsnty' /* Voir toute la liste de coures */,
                                                              ),
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .labelMedium
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .poppins(
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .labelMedium
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .labelMedium
                                                                          .fontStyle,
                                                                    ),
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontStyle,
                                                                  ),
                                                            ),
                                                          ),
                                                          Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .secondaryBackground,
                                                            ),
                                                            child: FutureBuilder<
                                                                List<
                                                                    MealPlanRow>>(
                                                              future: MealPlanTable()
                                                                  .querySingleRow(
                                                                queryFn: (q) =>
                                                                    q.eqOrNull(
                                                                  'id',
                                                                  myMealPlanMealPlanRow
                                                                      ?.id,
                                                                ),
                                                              ),
                                                              builder: (context,
                                                                  snapshot) {
                                                                // Customize what your widget looks like when it's loading.
                                                                if (!snapshot
                                                                    .hasData) {
                                                                  return Center(
                                                                    child:
                                                                        SizedBox(
                                                                      width:
                                                                          50.0,
                                                                      height:
                                                                          50.0,
                                                                      child:
                                                                          SpinKitDoubleBounce(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .tertiary,
                                                                        size:
                                                                            50.0,
                                                                      ),
                                                                    ),
                                                                  );
                                                                }
                                                                List<MealPlanRow>
                                                                    columnMealPlanRowList =
                                                                    snapshot
                                                                        .data!;

                                                                // Return an empty Container when the item does not exist.
                                                                if (snapshot
                                                                    .data!
                                                                    .isEmpty) {
                                                                  return Container();
                                                                }
                                                                final columnMealPlanRow =
                                                                    columnMealPlanRowList
                                                                            .isNotEmpty
                                                                        ? columnMealPlanRowList
                                                                            .first
                                                                        : null;

                                                                return Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Align(
                                                                      alignment:
                                                                          AlignmentDirectional(
                                                                              0.0,
                                                                              0.0),
                                                                      child:
                                                                          FlutterFlowRadioButton(
                                                                        options:
                                                                            [
                                                                          FFLocalizations.of(context)
                                                                              .getText(
                                                                            'cb0t2ua4' /* Tous */,
                                                                          ),
                                                                          FFLocalizations.of(context)
                                                                              .getText(
                                                                            'ntl5oze7' /* Déjà acheté */,
                                                                          ),
                                                                          FFLocalizations.of(context)
                                                                              .getText(
                                                                            'qaa19unc' /* Reste à acheter */,
                                                                          )
                                                                        ].toList(),
                                                                        onChanged:
                                                                            (val) async {
                                                                          safeSetState(
                                                                              () {});
                                                                          logFirebaseEvent(
                                                                              'HOME_RadioButton_klnv8u9i_ON_FORM_WIDGET');
                                                                          await Future
                                                                              .wait([
                                                                            Future(() async {
                                                                              logFirebaseEvent('RadioButton_refresh_database_request');
                                                                              safeSetState(() => _model.requestCompleter8 = null);
                                                                              await _model.waitForRequestCompleted8();
                                                                            }),
                                                                            Future(() async {
                                                                              logFirebaseEvent('RadioButton_refresh_database_request');
                                                                              safeSetState(() => _model.requestCompleter5 = null);
                                                                              await _model.waitForRequestCompleted5();
                                                                            }),
                                                                            Future(() async {
                                                                              logFirebaseEvent('RadioButton_refresh_database_request');
                                                                              safeSetState(() => _model.requestCompleter7 = null);
                                                                              await _model.waitForRequestCompleted7();
                                                                            }),
                                                                          ]);
                                                                        },
                                                                        controller: _model
                                                                            .radioButtonValueController ??= FormFieldController<
                                                                                String>(
                                                                            FFLocalizations.of(context).getText(
                                                                          's430144o' /* Tous */,
                                                                        )),
                                                                        optionHeight:
                                                                            32.0,
                                                                        textStyle: FlutterFlowTheme.of(context)
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
                                                                        selectedTextStyle: FlutterFlowTheme.of(context)
                                                                            .bodyLarge
                                                                            .override(
                                                                              font: GoogleFonts.poppins(
                                                                                fontWeight: FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                                                                                fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                                                                              ),
                                                                              letterSpacing: 0.0,
                                                                              fontWeight: FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                                                                              fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                                                                            ),
                                                                        buttonPosition:
                                                                            RadioButtonPosition.left,
                                                                        direction:
                                                                            Axis.horizontal,
                                                                        radioButtonColor:
                                                                            FlutterFlowTheme.of(context).primary,
                                                                        inactiveRadioButtonColor:
                                                                            FlutterFlowTheme.of(context).secondaryText,
                                                                        toggleable:
                                                                            false,
                                                                        horizontalAlignment:
                                                                            WrapAlignment.start,
                                                                        verticalAlignment:
                                                                            WrapCrossAlignment.start,
                                                                      ),
                                                                    ),
                                                                    FutureBuilder<
                                                                        List<
                                                                            ShoppingListRow>>(
                                                                      future: ShoppingListTable()
                                                                          .querySingleRow(
                                                                        queryFn:
                                                                            (q) =>
                                                                                q.eqOrNull(
                                                                          'meal_plan_id',
                                                                          columnMealPlanRow
                                                                              ?.id,
                                                                        ),
                                                                      ),
                                                                      builder:
                                                                          (context,
                                                                              snapshot) {
                                                                        // Customize what your widget looks like when it's loading.
                                                                        if (!snapshot
                                                                            .hasData) {
                                                                          return Center(
                                                                            child:
                                                                                SizedBox(
                                                                              width: 50.0,
                                                                              height: 50.0,
                                                                              child: SpinKitDoubleBounce(
                                                                                color: FlutterFlowTheme.of(context).tertiary,
                                                                                size: 50.0,
                                                                              ),
                                                                            ),
                                                                          );
                                                                        }
                                                                        List<ShoppingListRow>
                                                                            containerShoppingListRowList =
                                                                            snapshot.data!;

                                                                        // Return an empty Container when the item does not exist.
                                                                        if (snapshot
                                                                            .data!
                                                                            .isEmpty) {
                                                                          return Container();
                                                                        }
                                                                        final containerShoppingListRow = containerShoppingListRowList.isNotEmpty
                                                                            ? containerShoppingListRowList.first
                                                                            : null;

                                                                        return Container(
                                                                          decoration:
                                                                              BoxDecoration(),
                                                                          child:
                                                                              Column(
                                                                            mainAxisSize:
                                                                                MainAxisSize.max,
                                                                            children: [
                                                                              if (_model.radioButtonValue ==
                                                                                  FFLocalizations.of(context).getVariableText(
                                                                                    frText: 'Tous',
                                                                                    enText: 'All',
                                                                                    arText: '',
                                                                                  ))
                                                                                FutureBuilder<List<ShoppingIngredientRow>>(
                                                                                  future: (_model.requestCompleter8 ??= Completer<List<ShoppingIngredientRow>>()
                                                                                        ..complete(ShoppingIngredientTable().queryRows(
                                                                                          queryFn: (q) => q.eqOrNull(
                                                                                            'shopping_list_id',
                                                                                            containerShoppingListRow?.id,
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
                                                                                    List<ShoppingIngredientRow> tousContainerShoppingIngredientRowList = snapshot.data!;

                                                                                    return Container(
                                                                                      decoration: BoxDecoration(),
                                                                                      child: Column(
                                                                                        mainAxisSize: MainAxisSize.max,
                                                                                        children: [
                                                                                          Row(
                                                                                            mainAxisSize: MainAxisSize.max,
                                                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                                                            children: [
                                                                                              Text(
                                                                                                FFLocalizations.of(context).getText(
                                                                                                  'u2de4dv1' /* Nombre d'ingredient total */,
                                                                                                ),
                                                                                                style: FlutterFlowTheme.of(context).headlineSmall.override(
                                                                                                      font: GoogleFonts.outfit(
                                                                                                        fontWeight: FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                                                                                                        fontStyle: FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                                                                                                      ),
                                                                                                      color: FlutterFlowTheme.of(context).secondary,
                                                                                                      letterSpacing: 0.0,
                                                                                                      fontWeight: FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                                                                                                      fontStyle: FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                                                                                                    ),
                                                                                              ),
                                                                                              Text(
                                                                                                valueOrDefault<String>(
                                                                                                  tousContainerShoppingIngredientRowList.length.toString(),
                                                                                                  '0',
                                                                                                ),
                                                                                                style: FlutterFlowTheme.of(context).headlineSmall.override(
                                                                                                      font: GoogleFonts.outfit(
                                                                                                        fontWeight: FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                                                                                                        fontStyle: FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                                                                                                      ),
                                                                                                      color: FlutterFlowTheme.of(context).secondary,
                                                                                                      letterSpacing: 0.0,
                                                                                                      fontWeight: FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                                                                                                      fontStyle: FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                                                                                                    ),
                                                                                              ),
                                                                                            ].divide(SizedBox(width: 5.0)),
                                                                                          ),
                                                                                          if (_model.radioButtonValue ==
                                                                                              FFLocalizations.of(context).getVariableText(
                                                                                                frText: 'Tous',
                                                                                                enText: 'All',
                                                                                                arText: 'Alle',
                                                                                              ))
                                                                                            Builder(
                                                                                              builder: (context) {
                                                                                                final tousContainerVar = tousContainerShoppingIngredientRowList.toList().take(5).toList();

                                                                                                return ListView.separated(
                                                                                                  padding: EdgeInsets.zero,
                                                                                                  primary: false,
                                                                                                  shrinkWrap: true,
                                                                                                  scrollDirection: Axis.vertical,
                                                                                                  itemCount: tousContainerVar.length,
                                                                                                  separatorBuilder: (_, __) => SizedBox(height: 5.0),
                                                                                                  itemBuilder: (context, tousContainerVarIndex) {
                                                                                                    final tousContainerVarItem = tousContainerVar[tousContainerVarIndex];
                                                                                                    return Padding(
                                                                                                      padding: EdgeInsetsDirectional.fromSTEB(5.0, 0.0, 5.0, 0.0),
                                                                                                      child: Container(
                                                                                                        decoration: BoxDecoration(
                                                                                                          color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                          borderRadius: BorderRadius.circular(12.0),
                                                                                                          border: Border.all(
                                                                                                            color: FlutterFlowTheme.of(context).alternate,
                                                                                                          ),
                                                                                                        ),
                                                                                                        child: Padding(
                                                                                                          padding: EdgeInsetsDirectional.fromSTEB(0.0, 5.0, 0.0, 5.0),
                                                                                                          child: Row(
                                                                                                            mainAxisSize: MainAxisSize.min,
                                                                                                            children: [
                                                                                                              Expanded(
                                                                                                                child: Container(
                                                                                                                  width: 200.0,
                                                                                                                  decoration: BoxDecoration(),
                                                                                                                  child: Row(
                                                                                                                    mainAxisSize: MainAxisSize.max,
                                                                                                                    children: [
                                                                                                                      if ((tousContainerVarItem.quantity != null) && (tousContainerVarItem.quantity != 0.0))
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
                                                                                                                mainAxisSize: MainAxisSize.max,
                                                                                                                children: [
                                                                                                                  if (tousContainerVarItem.bought == true)
                                                                                                                    InkWell(
                                                                                                                      splashColor: Colors.transparent,
                                                                                                                      focusColor: Colors.transparent,
                                                                                                                      hoverColor: Colors.transparent,
                                                                                                                      highlightColor: Colors.transparent,
                                                                                                                      onTap: () async {
                                                                                                                        logFirebaseEvent('HOME_PAGE_PAGE_Icon_1xie6r1f_ON_TAP');
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
                                                                                                                        safeSetState(() => _model.requestCompleter8 = null);
                                                                                                                        await _model.waitForRequestCompleted8();
                                                                                                                      },
                                                                                                                      child: Icon(
                                                                                                                        Icons.check_box,
                                                                                                                        color: FlutterFlowTheme.of(context).primary,
                                                                                                                        size: 24.0,
                                                                                                                      ),
                                                                                                                    ),
                                                                                                                  if (tousContainerVarItem.bought == false)
                                                                                                                    InkWell(
                                                                                                                      splashColor: Colors.transparent,
                                                                                                                      focusColor: Colors.transparent,
                                                                                                                      hoverColor: Colors.transparent,
                                                                                                                      highlightColor: Colors.transparent,
                                                                                                                      onTap: () async {
                                                                                                                        logFirebaseEvent('HOME_PAGE_PAGE_Icon_4dply51i_ON_TAP');
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
                                                                                                                        safeSetState(() => _model.requestCompleter8 = null);
                                                                                                                        await _model.waitForRequestCompleted8();
                                                                                                                      },
                                                                                                                      child: Icon(
                                                                                                                        Icons.check_box_outline_blank,
                                                                                                                        color: FlutterFlowTheme.of(context).primary,
                                                                                                                        size: 24.0,
                                                                                                                      ),
                                                                                                                    ),
                                                                                                                ],
                                                                                                              ),
                                                                                                            ].divide(SizedBox(width: 10.0)).addToStart(SizedBox(width: 5.0)).addToEnd(SizedBox(width: 5.0)),
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
                                                                              if (_model.radioButtonValue ==
                                                                                  FFLocalizations.of(context).getVariableText(
                                                                                    frText: 'Déjà acheté',
                                                                                    enText: 'Already bought',
                                                                                    arText: '',
                                                                                  ))
                                                                                FutureBuilder<List<ShoppingIngredientRow>>(
                                                                                  future: (_model.requestCompleter5 ??= Completer<List<ShoppingIngredientRow>>()
                                                                                        ..complete(ShoppingIngredientTable().queryRows(
                                                                                          queryFn: (q) => q
                                                                                              .eqOrNull(
                                                                                                'shopping_list_id',
                                                                                                containerShoppingListRow?.id,
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
                                                                                            color: FlutterFlowTheme.of(context).tertiary,
                                                                                            size: 50.0,
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                    }
                                                                                    List<ShoppingIngredientRow> acheteContainerShoppingIngredientRowList = snapshot.data!;

                                                                                    return Container(
                                                                                      decoration: BoxDecoration(),
                                                                                      child: Column(
                                                                                        mainAxisSize: MainAxisSize.max,
                                                                                        children: [
                                                                                          Padding(
                                                                                            padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 30.0),
                                                                                            child: Row(
                                                                                              mainAxisSize: MainAxisSize.max,
                                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                                              children: [
                                                                                                if (_model.radioButtonValue == 'Déjà acheté')
                                                                                                  Text(
                                                                                                    FFLocalizations.of(context).getText(
                                                                                                      'bbuvb1dz' /* Nombre d'ingredient acheté */,
                                                                                                    ),
                                                                                                    style: FlutterFlowTheme.of(context).headlineSmall.override(
                                                                                                          font: GoogleFonts.outfit(
                                                                                                            fontWeight: FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                                                                                                            fontStyle: FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                                                                                                          ),
                                                                                                          color: FlutterFlowTheme.of(context).secondary,
                                                                                                          letterSpacing: 0.0,
                                                                                                          fontWeight: FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                                                                                                          fontStyle: FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                                                                                                        ),
                                                                                                  ),
                                                                                                Text(
                                                                                                  valueOrDefault<String>(
                                                                                                    acheteContainerShoppingIngredientRowList.length.toString(),
                                                                                                    '0',
                                                                                                  ),
                                                                                                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                                                                                                        font: GoogleFonts.outfit(
                                                                                                          fontWeight: FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                                                                                                          fontStyle: FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                                                                                                        ),
                                                                                                        color: FlutterFlowTheme.of(context).secondary,
                                                                                                        letterSpacing: 0.0,
                                                                                                        fontWeight: FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                                                                                                        fontStyle: FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                                                                                                      ),
                                                                                                ),
                                                                                              ].divide(SizedBox(width: 5.0)),
                                                                                            ),
                                                                                          ),
                                                                                          Builder(
                                                                                            builder: (context) {
                                                                                              final acheteContainerVar = acheteContainerShoppingIngredientRowList.toList().take(5).toList();

                                                                                              return ListView.separated(
                                                                                                padding: EdgeInsets.zero,
                                                                                                primary: false,
                                                                                                shrinkWrap: true,
                                                                                                scrollDirection: Axis.vertical,
                                                                                                itemCount: acheteContainerVar.length,
                                                                                                separatorBuilder: (_, __) => SizedBox(height: 5.0),
                                                                                                itemBuilder: (context, acheteContainerVarIndex) {
                                                                                                  final acheteContainerVarItem = acheteContainerVar[acheteContainerVarIndex];
                                                                                                  return Padding(
                                                                                                    padding: EdgeInsetsDirectional.fromSTEB(5.0, 0.0, 5.0, 0.0),
                                                                                                    child: Container(
                                                                                                      decoration: BoxDecoration(
                                                                                                        color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                        borderRadius: BorderRadius.circular(12.0),
                                                                                                        border: Border.all(
                                                                                                          color: FlutterFlowTheme.of(context).alternate,
                                                                                                        ),
                                                                                                      ),
                                                                                                      child: Padding(
                                                                                                        padding: EdgeInsetsDirectional.fromSTEB(0.0, 5.0, 0.0, 5.0),
                                                                                                        child: Row(
                                                                                                          mainAxisSize: MainAxisSize.min,
                                                                                                          children: [
                                                                                                            Expanded(
                                                                                                              child: Container(
                                                                                                                width: 200.0,
                                                                                                                decoration: BoxDecoration(),
                                                                                                                child: Row(
                                                                                                                  mainAxisSize: MainAxisSize.max,
                                                                                                                  children: [
                                                                                                                    if ((acheteContainerVarItem.quantity != null) && (acheteContainerVarItem.quantity != 0.0))
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
                                                                                                                      valueOrDefault<String>(
                                                                                                                        acheteContainerVarItem.name,
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
                                                                                                              mainAxisSize: MainAxisSize.max,
                                                                                                              children: [
                                                                                                                if (acheteContainerVarItem.bought == true)
                                                                                                                  InkWell(
                                                                                                                    splashColor: Colors.transparent,
                                                                                                                    focusColor: Colors.transparent,
                                                                                                                    hoverColor: Colors.transparent,
                                                                                                                    highlightColor: Colors.transparent,
                                                                                                                    onTap: () async {
                                                                                                                      logFirebaseEvent('HOME_PAGE_PAGE_Icon_z9ztle8b_ON_TAP');
                                                                                                                      logFirebaseEvent('Icon_backend_call');
                                                                                                                      await ShoppingIngredientTable().update(
                                                                                                                        data: {
                                                                                                                          'bought': false,
                                                                                                                        },
                                                                                                                        matchingRows: (rows) => rows.eqOrNull(
                                                                                                                          'id',
                                                                                                                          acheteContainerVarItem.id,
                                                                                                                        ),
                                                                                                                      );
                                                                                                                      logFirebaseEvent('Icon_refresh_database_request');
                                                                                                                      safeSetState(() => _model.requestCompleter5 = null);
                                                                                                                      await _model.waitForRequestCompleted5();
                                                                                                                    },
                                                                                                                    child: Icon(
                                                                                                                      Icons.check_box,
                                                                                                                      color: FlutterFlowTheme.of(context).primary,
                                                                                                                      size: 24.0,
                                                                                                                    ),
                                                                                                                  ),
                                                                                                                if (acheteContainerVarItem.bought == false)
                                                                                                                  InkWell(
                                                                                                                    splashColor: Colors.transparent,
                                                                                                                    focusColor: Colors.transparent,
                                                                                                                    hoverColor: Colors.transparent,
                                                                                                                    highlightColor: Colors.transparent,
                                                                                                                    onTap: () async {
                                                                                                                      logFirebaseEvent('HOME_PAGE_PAGE_Icon_7es3tb70_ON_TAP');
                                                                                                                      logFirebaseEvent('Icon_backend_call');
                                                                                                                      await ShoppingIngredientTable().update(
                                                                                                                        data: {
                                                                                                                          'bought': true,
                                                                                                                        },
                                                                                                                        matchingRows: (rows) => rows.eqOrNull(
                                                                                                                          'id',
                                                                                                                          acheteContainerVarItem.id,
                                                                                                                        ),
                                                                                                                      );
                                                                                                                      logFirebaseEvent('Icon_refresh_database_request');
                                                                                                                      safeSetState(() => _model.requestCompleter8 = null);
                                                                                                                      await _model.waitForRequestCompleted8();
                                                                                                                    },
                                                                                                                    child: Icon(
                                                                                                                      Icons.check_box_outline_blank,
                                                                                                                      color: FlutterFlowTheme.of(context).primary,
                                                                                                                      size: 24.0,
                                                                                                                    ),
                                                                                                                  ),
                                                                                                              ],
                                                                                                            ),
                                                                                                          ].divide(SizedBox(width: 10.0)).addToStart(SizedBox(width: 5.0)).addToEnd(SizedBox(width: 5.0)),
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
                                                                                  FFLocalizations.of(context).getVariableText(
                                                                                    frText: 'Reste à acheter',
                                                                                    enText: 'Still to buy',
                                                                                    arText: '',
                                                                                  ))
                                                                                FutureBuilder<List<ShoppingIngredientRow>>(
                                                                                  future: (_model.requestCompleter7 ??= Completer<List<ShoppingIngredientRow>>()
                                                                                        ..complete(ShoppingIngredientTable().queryRows(
                                                                                          queryFn: (q) => q
                                                                                              .eqOrNull(
                                                                                                'shopping_list_id',
                                                                                                containerShoppingListRow?.id,
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
                                                                                            color: FlutterFlowTheme.of(context).tertiary,
                                                                                            size: 50.0,
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                    }
                                                                                    List<ShoppingIngredientRow> restantContainerShoppingIngredientRowList = snapshot.data!;

                                                                                    return Container(
                                                                                      decoration: BoxDecoration(),
                                                                                      child: Column(
                                                                                        mainAxisSize: MainAxisSize.max,
                                                                                        children: [
                                                                                          Padding(
                                                                                            padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 30.0),
                                                                                            child: Row(
                                                                                              mainAxisSize: MainAxisSize.max,
                                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                                              children: [
                                                                                                Text(
                                                                                                  FFLocalizations.of(context).getText(
                                                                                                    'dlvw8uyh' /* Nombre d'ingredient restant */,
                                                                                                  ),
                                                                                                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                                                                                                        font: GoogleFonts.outfit(
                                                                                                          fontWeight: FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                                                                                                          fontStyle: FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                                                                                                        ),
                                                                                                        color: FlutterFlowTheme.of(context).secondary,
                                                                                                        letterSpacing: 0.0,
                                                                                                        fontWeight: FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                                                                                                        fontStyle: FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                                                                                                      ),
                                                                                                ),
                                                                                                Text(
                                                                                                  valueOrDefault<String>(
                                                                                                    restantContainerShoppingIngredientRowList.length.toString(),
                                                                                                    '0',
                                                                                                  ),
                                                                                                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                                                                                                        font: GoogleFonts.outfit(
                                                                                                          fontWeight: FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                                                                                                          fontStyle: FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                                                                                                        ),
                                                                                                        color: FlutterFlowTheme.of(context).secondary,
                                                                                                        letterSpacing: 0.0,
                                                                                                        fontWeight: FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                                                                                                        fontStyle: FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                                                                                                      ),
                                                                                                ),
                                                                                              ].divide(SizedBox(width: 5.0)),
                                                                                            ),
                                                                                          ),
                                                                                          Builder(
                                                                                            builder: (context) {
                                                                                              final restantContainerVar = restantContainerShoppingIngredientRowList.toList().take(5).toList();

                                                                                              return ListView.separated(
                                                                                                padding: EdgeInsets.zero,
                                                                                                primary: false,
                                                                                                shrinkWrap: true,
                                                                                                scrollDirection: Axis.vertical,
                                                                                                itemCount: restantContainerVar.length,
                                                                                                separatorBuilder: (_, __) => SizedBox(height: 5.0),
                                                                                                itemBuilder: (context, restantContainerVarIndex) {
                                                                                                  final restantContainerVarItem = restantContainerVar[restantContainerVarIndex];
                                                                                                  return Padding(
                                                                                                    padding: EdgeInsetsDirectional.fromSTEB(5.0, 0.0, 5.0, 0.0),
                                                                                                    child: Container(
                                                                                                      decoration: BoxDecoration(
                                                                                                        color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                        borderRadius: BorderRadius.circular(12.0),
                                                                                                        border: Border.all(
                                                                                                          color: FlutterFlowTheme.of(context).alternate,
                                                                                                        ),
                                                                                                      ),
                                                                                                      child: Padding(
                                                                                                        padding: EdgeInsetsDirectional.fromSTEB(0.0, 5.0, 0.0, 5.0),
                                                                                                        child: Row(
                                                                                                          mainAxisSize: MainAxisSize.min,
                                                                                                          children: [
                                                                                                            Expanded(
                                                                                                              child: Container(
                                                                                                                width: 200.0,
                                                                                                                decoration: BoxDecoration(),
                                                                                                                child: Row(
                                                                                                                  mainAxisSize: MainAxisSize.max,
                                                                                                                  children: [
                                                                                                                    if ((restantContainerVarItem.quantity != null) && (restantContainerVarItem.quantity != 0.0))
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
                                                                                                                    if ((restantContainerVarItem.unit != null && restantContainerVarItem.unit != '') && (restantContainerVarItem.unit != 'sans unité'))
                                                                                                                      Text(
                                                                                                                        restantContainerVarItem.unit!,
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
                                                                                                                        restantContainerVarItem.name,
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
                                                                                                              mainAxisSize: MainAxisSize.max,
                                                                                                              children: [
                                                                                                                if (restantContainerVarItem.bought == true)
                                                                                                                  InkWell(
                                                                                                                    splashColor: Colors.transparent,
                                                                                                                    focusColor: Colors.transparent,
                                                                                                                    hoverColor: Colors.transparent,
                                                                                                                    highlightColor: Colors.transparent,
                                                                                                                    onTap: () async {
                                                                                                                      logFirebaseEvent('HOME_PAGE_PAGE_Icon_d9mwdqw4_ON_TAP');
                                                                                                                      logFirebaseEvent('Icon_backend_call');
                                                                                                                      await ShoppingIngredientTable().update(
                                                                                                                        data: {
                                                                                                                          'bought': false,
                                                                                                                        },
                                                                                                                        matchingRows: (rows) => rows.eqOrNull(
                                                                                                                          'id',
                                                                                                                          restantContainerVarItem.id,
                                                                                                                        ),
                                                                                                                      );
                                                                                                                      logFirebaseEvent('Icon_refresh_database_request');
                                                                                                                      safeSetState(() => _model.requestCompleter7 = null);
                                                                                                                      await _model.waitForRequestCompleted7();
                                                                                                                    },
                                                                                                                    child: Icon(
                                                                                                                      Icons.check_box,
                                                                                                                      color: FlutterFlowTheme.of(context).primary,
                                                                                                                      size: 24.0,
                                                                                                                    ),
                                                                                                                  ),
                                                                                                                if (restantContainerVarItem.bought == false)
                                                                                                                  InkWell(
                                                                                                                    splashColor: Colors.transparent,
                                                                                                                    focusColor: Colors.transparent,
                                                                                                                    hoverColor: Colors.transparent,
                                                                                                                    highlightColor: Colors.transparent,
                                                                                                                    onTap: () async {
                                                                                                                      logFirebaseEvent('HOME_PAGE_PAGE_Icon_6wnnd28c_ON_TAP');
                                                                                                                      logFirebaseEvent('Icon_backend_call');
                                                                                                                      await ShoppingIngredientTable().update(
                                                                                                                        data: {
                                                                                                                          'bought': true,
                                                                                                                        },
                                                                                                                        matchingRows: (rows) => rows.eqOrNull(
                                                                                                                          'id',
                                                                                                                          restantContainerVarItem.id,
                                                                                                                        ),
                                                                                                                      );
                                                                                                                      logFirebaseEvent('Icon_refresh_database_request');
                                                                                                                      safeSetState(() => _model.requestCompleter7 = null);
                                                                                                                      await _model.waitForRequestCompleted7();
                                                                                                                    },
                                                                                                                    child: Icon(
                                                                                                                      Icons.check_box_outline_blank,
                                                                                                                      color: FlutterFlowTheme.of(context).primary,
                                                                                                                      size: 24.0,
                                                                                                                    ),
                                                                                                                  ),
                                                                                                              ],
                                                                                                            ),
                                                                                                          ].divide(SizedBox(width: 10.0)).addToStart(SizedBox(width: 5.0)).addToEnd(SizedBox(width: 5.0)),
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
                                                                      .divide(SizedBox(
                                                                          height:
                                                                              30.0))
                                                                      .addToStart(SizedBox(
                                                                          height:
                                                                              40.0))
                                                                      .addToEnd(SizedBox(
                                                                          height:
                                                                              20.0)),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ].divide(SizedBox(
                                                            height: 10.0)),
                                                      ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ].divide(SizedBox(height: 15.0)),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 25.0, 0.0, 0.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        FFLocalizations.of(context).getText(
                                          'hzuuni1y' /* Recettes recomandées */,
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .headlineMedium
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .headlineMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .headlineMedium
                                                        .fontStyle,
                                              ),
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .headlineMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .headlineMedium
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
                                              'HOME_PAGE_PAGE_Text_an6fpdpu_ON_TAP');
                                          logFirebaseEvent('Text_navigate_to');

                                          context.pushNamed(
                                              RecipeResearchingListWidget
                                                  .routeName);
                                        },
                                        child: Text(
                                          FFLocalizations.of(context).getText(
                                            'v5u29a74' /* Toutes les nouvelles recettes ... */,
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
                                        ),
                                      ),
                                      FutureBuilder<ApiCallResponse>(
                                        future: SupabaseGroup
                                            .recommandedReceipeCall
                                            .call(
                                          userId: homePageUsersRow?.id,
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
                                          final rowRecommandedReceipeResponse =
                                              snapshot.data!;

                                          return Builder(
                                            builder: (context) {
                                              final receipesID = SupabaseGroup
                                                      .recommandedReceipeCall
                                                      .receipeIDs(
                                                        rowRecommandedReceipeResponse
                                                            .jsonBody,
                                                      )
                                                      ?.toList() ??
                                                  [];

                                              return SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: List.generate(
                                                          receipesID.length,
                                                          (receipesIDIndex) {
                                                    final receipesIDItem =
                                                        receipesID[
                                                            receipesIDIndex];
                                                    return FutureBuilder<
                                                        List<ReceipeRow>>(
                                                      future: ReceipeTable()
                                                          .querySingleRow(
                                                        queryFn: (q) =>
                                                            q.eqOrNull(
                                                          'id',
                                                          receipesIDItem,
                                                        ),
                                                      ),
                                                      builder:
                                                          (context, snapshot) {
                                                        // Customize what your widget looks like when it's loading.
                                                        if (!snapshot.hasData) {
                                                          return Center(
                                                            child: SizedBox(
                                                              width: 50.0,
                                                              height: 50.0,
                                                              child:
                                                                  SpinKitDoubleBounce(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .tertiary,
                                                                size: 50.0,
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                        List<ReceipeRow>
                                                            recipeCardMiniReceipeRowList =
                                                            snapshot.data!;

                                                        // Return an empty Container when the item does not exist.
                                                        if (snapshot
                                                            .data!.isEmpty) {
                                                          return Container();
                                                        }
                                                        final recipeCardMiniReceipeRow =
                                                            recipeCardMiniReceipeRowList
                                                                    .isNotEmpty
                                                                ? recipeCardMiniReceipeRowList
                                                                    .first
                                                                : null;

                                                        return wrapWithModel(
                                                          model: _model
                                                              .recipeCardMiniModels
                                                              .getModel(
                                                            receipesIDItem
                                                                .toString(),
                                                            receipesIDIndex,
                                                          ),
                                                          updateCallback: () =>
                                                              safeSetState(
                                                                  () {}),
                                                          child:
                                                              RecipeCardMiniWidget(
                                                            key: Key(
                                                              'Keyzpf_${receipesIDItem.toString()}',
                                                            ),
                                                            recipe:
                                                                recipeCardMiniReceipeRow!,
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  })
                                                      .divide(
                                                          SizedBox(width: 15.0))
                                                      .around(SizedBox(
                                                          width: 15.0)),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            10.0, 0.0, 10.0, 0.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  '1xbzfxkr' /* Partager vos recettes */,
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
                                                              .primary,
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
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  '851wd1em' /* Vous avez des recettes qui pou... */,
                                                ),
                                                style: FlutterFlowTheme.of(
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
                                              FFButtonWidget(
                                                onPressed: () async {
                                                  logFirebaseEvent(
                                                      'HOME_PAGE_PAGE_PARTAGER_BTN_ON_TAP');
                                                  logFirebaseEvent(
                                                      'Button_launch_u_r_l');
                                                  await launchURL(
                                                      'https://recipeaddition-jcylqs.flutterflow.app/');
                                                },
                                                text:
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                  'f4hz2ksx' /* Partager */,
                                                ),
                                                options: FFButtonOptions(
                                                  height: 40.0,
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          16.0, 0.0, 16.0, 0.0),
                                                  iconPadding:
                                                      EdgeInsetsDirectional
                                                          .fromSTEB(0.0, 0.0,
                                                              0.0, 0.0),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                  textStyle: FlutterFlowTheme
                                                          .of(context)
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
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primary,
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
                                                  elevation: 0.0,
                                                  borderSide: BorderSide(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                              ),
                                            ].divide(SizedBox(height: 5.0)),
                                          ),
                                        ),
                                      ),
                                    ]
                                        .divide(SizedBox(height: 15.0))
                                        .around(SizedBox(height: 15.0)),
                                  ),
                                ),
                              ].divide(SizedBox(height: 15.0)),
                            ),
                          ),
                        ),
                        if (_model.aiChat)
                          Align(
                            alignment: AlignmentDirectional(1.0, 1.0),
                            child: wrapWithModel(
                              model: _model.aiThreadModel,
                              updateCallback: () => safeSetState(() {}),
                              child: AiThreadWidget(
                                parameter2: _model.aiChat,
                                users: homePageUsersRow!,
                              ),
                            ),
                          ),
                        if (FFAppState().trialOver)
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    '6jd45i9i' /* Votre essai s'est terminé.  */,
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
                                ),
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'zvnqqf2o' /* Veuillez mettre à jour votre p... */,
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
                                ),
                              ],
                            ),
                          ),
                      ],
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
