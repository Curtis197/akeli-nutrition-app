import '/analytics/daily_recap_copy/daily_recap_copy_widget.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/components/daily_recap_widget.dart';
import '/components/weekly_int_copy_widget.dart';
import '/components/weekly_int_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dash_model.dart';
export 'dash_model.dart';

class DashWidget extends StatefulWidget {
  const DashWidget({super.key});

  static String routeName = 'dash';
  static String routePath = '/dash';

  @override
  State<DashWidget> createState() => _DashWidgetState();
}

class _DashWidgetState extends State<DashWidget> with TickerProviderStateMixin {
  late DashModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DashModel());

    logFirebaseEvent('screen_view', parameters: {'screen_name': 'dash'});
    _model.tabBarController = TabController(
      vsync: this,
      length: 2,
      initialIndex: 0,
    )..addListener(() => safeSetState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: FlutterFlowTheme.of(context).secondaryBackground,
              size: 30.0,
            ),
            onPressed: () async {
              logFirebaseEvent('DASH_PAGE_arrow_back_rounded_ICN_ON_TAP');
              logFirebaseEvent('IconButton_navigate_back');
              context.pop();
            },
          ),
          title: Text(
            FFLocalizations.of(context).getText(
              'r7qsxl1a' /* Recapitulatif */,
            ),
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.outfit(
                    fontWeight:
                        FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).headlineMedium.fontWeight,
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
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 30.0, 0.0, 0.0),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment(0.0, 0),
                      child: TabBar(
                        labelColor: FlutterFlowTheme.of(context).primaryText,
                        unselectedLabelColor:
                            FlutterFlowTheme.of(context).secondaryText,
                        labelPadding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 10.0),
                        labelStyle:
                            FlutterFlowTheme.of(context).titleMedium.override(
                                  font: GoogleFonts.poppins(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontStyle,
                                ),
                        unselectedLabelStyle:
                            FlutterFlowTheme.of(context).titleMedium.override(
                                  font: GoogleFonts.poppins(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontStyle,
                                ),
                        indicatorColor: FlutterFlowTheme.of(context).primary,
                        padding: EdgeInsets.all(4.0),
                        tabs: [
                          Tab(
                            text: FFLocalizations.of(context).getText(
                              'jvg405lu' /* Journalier */,
                            ),
                            iconMargin: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 10.0),
                          ),
                          Tab(
                            text: FFLocalizations.of(context).getText(
                              'q1x2kxr6' /*  Hebdomadaire */,
                            ),
                          ),
                        ],
                        controller: _model.tabBarController,
                        onTap: (i) async {
                          [() async {}, () async {}][i]();
                        },
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _model.tabBarController,
                        children: [
                          SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                AuthUserStreamWidget(
                                  builder: (context) =>
                                      FutureBuilder<List<DailyUserTrackRow>>(
                                    future:
                                        DailyUserTrackTable().querySingleRow(
                                      queryFn: (q) => q
                                          .eqOrNull(
                                            'id',
                                            valueOrDefault(
                                                currentUserDocument?.id, 0),
                                          )
                                          .eqOrNull(
                                            'date',
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
                                      List<DailyUserTrackRow>
                                          containerDailyUserTrackRowList =
                                          snapshot.data!;

                                      final containerDailyUserTrackRow =
                                          containerDailyUserTrackRowList
                                                  .isNotEmpty
                                              ? containerDailyUserTrackRowList
                                                  .first
                                              : null;

                                      return Container(
                                        decoration: BoxDecoration(),
                                        child: Visibility(
                                          visible: containerDailyUserTrackRow ==
                                              null,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(),
                                                child: wrapWithModel(
                                                  model: _model
                                                      .dailyRecapCopyModel,
                                                  updateCallback: () =>
                                                      safeSetState(() {}),
                                                  child: DailyRecapCopyWidget(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                AuthUserStreamWidget(
                                  builder: (context) =>
                                      FutureBuilder<List<DailyUserTrackRow>>(
                                    future: DailyUserTrackTable().queryRows(
                                      queryFn: (q) => q
                                          .eqOrNull(
                                            'id',
                                            valueOrDefault(
                                                currentUserDocument?.id, 0),
                                          )
                                          .lteOrNull(
                                            'date',
                                            supaSerialize<DateTime>(
                                                getCurrentTimestamp),
                                          )
                                          .order('date'),
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
                                      List<DailyUserTrackRow>
                                          listViewDailyUserTrackRowList =
                                          snapshot.data!;

                                      return ListView.builder(
                                        padding: EdgeInsets.zero,
                                        primary: false,
                                        shrinkWrap: true,
                                        scrollDirection: Axis.vertical,
                                        itemCount: listViewDailyUserTrackRowList
                                            .length,
                                        itemBuilder: (context, listViewIndex) {
                                          final listViewDailyUserTrackRow =
                                              listViewDailyUserTrackRowList[
                                                  listViewIndex];
                                          return wrapWithModel(
                                            model: _model.dailyRecapModels
                                                .getModel(
                                              listViewDailyUserTrackRow.id!
                                                  .toString(),
                                              listViewIndex,
                                            ),
                                            updateCallback: () =>
                                                safeSetState(() {}),
                                            child: DailyRecapWidget(
                                              key: Key(
                                                'Keyrcc_${listViewDailyUserTrackRow.id!.toString()}',
                                              ),
                                              track: listViewDailyUserTrackRow,
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
                          SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                AuthUserStreamWidget(
                                  builder: (context) =>
                                      FutureBuilder<List<WeeklyUserTrackRow>>(
                                    future:
                                        WeeklyUserTrackTable().querySingleRow(
                                      queryFn: (q) => q
                                          .eqOrNull(
                                            'user_id',
                                            valueOrDefault(
                                                currentUserDocument?.id, 0),
                                          )
                                          .lteOrNull(
                                            'start_date',
                                            supaSerialize<DateTime>(
                                                getCurrentTimestamp),
                                          )
                                          .gteOrNull(
                                            'end_date',
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
                                      List<WeeklyUserTrackRow>
                                          containerWeeklyUserTrackRowList =
                                          snapshot.data!;

                                      final containerWeeklyUserTrackRow =
                                          containerWeeklyUserTrackRowList
                                                  .isNotEmpty
                                              ? containerWeeklyUserTrackRowList
                                                  .first
                                              : null;

                                      return Container(
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                        ),
                                        child: Visibility(
                                          visible: containerWeeklyUserTrackRow
                                                  ?.userId ==
                                              null,
                                          child: wrapWithModel(
                                            model: _model.weeklyIntModel,
                                            updateCallback: () =>
                                                safeSetState(() {}),
                                            child: WeeklyIntWidget(),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                AuthUserStreamWidget(
                                  builder: (context) =>
                                      FutureBuilder<List<WeeklyUserTrackRow>>(
                                    future: WeeklyUserTrackTable().queryRows(
                                      queryFn: (q) => q
                                          .eqOrNull(
                                            'user_id',
                                            valueOrDefault(
                                                currentUserDocument?.id, 0),
                                          )
                                          .order('start_date'),
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
                                      List<WeeklyUserTrackRow>
                                          columnWeeklyUserTrackRowList =
                                          snapshot.data!;

                                      return Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: List.generate(
                                            columnWeeklyUserTrackRowList.length,
                                            (columnIndex) {
                                          final columnWeeklyUserTrackRow =
                                              columnWeeklyUserTrackRowList[
                                                  columnIndex];
                                          return wrapWithModel(
                                            model: _model.weeklyIntCopyModels
                                                .getModel(
                                              columnWeeklyUserTrackRow.userId!
                                                  .toString(),
                                              columnIndex,
                                            ),
                                            updateCallback: () =>
                                                safeSetState(() {}),
                                            child: WeeklyIntCopyWidget(
                                              key: Key(
                                                'Keyrqc_${columnWeeklyUserTrackRow.userId!.toString()}',
                                              ),
                                              weeklyUserTrack:
                                                  columnWeeklyUserTrackRow,
                                            ),
                                          );
                                        }),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
