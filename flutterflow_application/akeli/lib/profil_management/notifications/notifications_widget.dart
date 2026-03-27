import '/auth/firebase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/components/notification_chat_widget.dart';
import '/components/notification_demand_widget.dart';
import '/components/notification_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'notifications_model.dart';
export 'notifications_model.dart';

class NotificationsWidget extends StatefulWidget {
  const NotificationsWidget({super.key});

  static String routeName = 'Notifications';
  static String routePath = '/notifications';

  @override
  State<NotificationsWidget> createState() => _NotificationsWidgetState();
}

class _NotificationsWidgetState extends State<NotificationsWidget>
    with TickerProviderStateMixin {
  late NotificationsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NotificationsModel());

    logFirebaseEvent('screen_view',
        parameters: {'screen_name': 'Notifications'});
    _model.tabBarController = TabController(
      vsync: this,
      length: 3,
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
    return AuthUserStreamWidget(
      builder: (context) => FutureBuilder<List<TotalNotificationsRow>>(
        future: TotalNotificationsTable().querySingleRow(
          queryFn: (q) => q.eqOrNull(
            'user_id',
            valueOrDefault(currentUserDocument?.id, 0),
          ),
        ),
        builder: (context, snapshot) {
          // Customize what your widget looks like when it's loading.
          if (!snapshot.hasData) {
            return Scaffold(
              backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
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
          List<TotalNotificationsRow> notificationsTotalNotificationsRowList =
              snapshot.data!;

          final notificationsTotalNotificationsRow =
              notificationsTotalNotificationsRowList.isNotEmpty
                  ? notificationsTotalNotificationsRowList.first
                  : null;

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
                    logFirebaseEvent(
                        'NOTIFICATIONS_arrow_back_rounded_ICN_ON_');
                    logFirebaseEvent('IconButton_navigate_back');
                    context.pop();
                  },
                ),
                title: Text(
                  FFLocalizations.of(context).getText(
                    'osw35r3x' /* Notifications */,
                  ),
                  style: FlutterFlowTheme.of(context).headlineLarge.override(
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
                actions: [],
                centerTitle: true,
                elevation: 2.0,
              ),
              body: Column(
                children: [
                  Align(
                    alignment: Alignment(0.0, 0),
                    child: TabBar(
                      labelColor: FlutterFlowTheme.of(context).primaryText,
                      unselectedLabelColor:
                          FlutterFlowTheme.of(context).secondaryText,
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
                          FlutterFlowTheme.of(context).labelMedium.override(
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
                      indicatorColor: FlutterFlowTheme.of(context).primary,
                      tabs: [
                        Tab(
                          text:
                              ' Repas  ${(notificationsTotalNotificationsRow?.mealCount != null) && (notificationsTotalNotificationsRow?.mealCount != 0) ? notificationsTotalNotificationsRow?.mealCount?.toString() : ''}',
                        ),
                        Tab(
                          text:
                              'Chat ${(notificationsTotalNotificationsRow?.chatCount != null) && (notificationsTotalNotificationsRow?.chatCount != 0) ? notificationsTotalNotificationsRow?.chatCount?.toString() : ''}',
                        ),
                        Tab(
                          text:
                              'Demande ${(notificationsTotalNotificationsRow?.demandCount != null) && (notificationsTotalNotificationsRow?.demandCount != 0) ? notificationsTotalNotificationsRow?.demandCount?.toString() : ''}',
                        ),
                      ],
                      controller: _model.tabBarController,
                      onTap: (i) async {
                        [() async {}, () async {}, () async {}][i]();
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
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 20.0, 0.0, 0.0),
                                child:
                                    FutureBuilder<List<MealNotificationsRow>>(
                                  future: MealNotificationsTable().queryRows(
                                    queryFn: (q) => q
                                        .eqOrNull(
                                          'user_id',
                                          valueOrDefault(
                                              currentUserDocument?.id, 0),
                                        )
                                        .order('sent_at'),
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
                                    List<MealNotificationsRow>
                                        listViewMealNotificationsRowList =
                                        snapshot.data!;

                                    return ListView.separated(
                                      padding: EdgeInsets.zero,
                                      primary: false,
                                      shrinkWrap: true,
                                      scrollDirection: Axis.vertical,
                                      itemCount:
                                          listViewMealNotificationsRowList
                                              .length,
                                      separatorBuilder: (_, __) =>
                                          SizedBox(height: 10.0),
                                      itemBuilder: (context, listViewIndex) {
                                        final listViewMealNotificationsRow =
                                            listViewMealNotificationsRowList[
                                                listViewIndex];
                                        return wrapWithModel(
                                          model: _model.notificationModels
                                              .getModel(
                                            listViewMealNotificationsRow.id!,
                                            listViewIndex,
                                          ),
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: NotificationWidget(
                                            key: Key(
                                              'Keywqr_${listViewMealNotificationsRow.id!}',
                                            ),
                                            notification:
                                                listViewMealNotificationsRow,
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
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 20.0, 0.0, 0.0),
                                child:
                                    FutureBuilder<List<ChatNotificationsRow>>(
                                  future: ChatNotificationsTable().queryRows(
                                    queryFn: (q) => q
                                        .eqOrNull(
                                          'user_id',
                                          valueOrDefault(
                                              currentUserDocument?.id, 0),
                                        )
                                        .order('created_at'),
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
                                    List<ChatNotificationsRow>
                                        listViewChatNotificationsRowList =
                                        snapshot.data!;

                                    return ListView.separated(
                                      padding: EdgeInsets.zero,
                                      primary: false,
                                      shrinkWrap: true,
                                      scrollDirection: Axis.vertical,
                                      itemCount:
                                          listViewChatNotificationsRowList
                                              .length,
                                      separatorBuilder: (_, __) =>
                                          SizedBox(height: 10.0),
                                      itemBuilder: (context, listViewIndex) {
                                        final listViewChatNotificationsRow =
                                            listViewChatNotificationsRowList[
                                                listViewIndex];
                                        return FutureBuilder<
                                            List<ChatConversationRow>>(
                                          future: ChatConversationTable()
                                              .querySingleRow(
                                            queryFn: (q) => q.eqOrNull(
                                              'id',
                                              listViewChatNotificationsRow
                                                  .conversationId,
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
                                            List<ChatConversationRow>
                                                notificationChatChatConversationRowList =
                                                snapshot.data!;

                                            final notificationChatChatConversationRow =
                                                notificationChatChatConversationRowList
                                                        .isNotEmpty
                                                    ? notificationChatChatConversationRowList
                                                        .first
                                                    : null;

                                            return InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                logFirebaseEvent(
                                                    'NOTIFICATIONS_Container_v8g5rqcq_ON_TAP');
                                                logFirebaseEvent(
                                                    'notification_chat_navigate_to');

                                                context.pushNamed(
                                                  ChatPageWidget.routeName,
                                                  queryParameters: {
                                                    'conversation':
                                                        serializeParam(
                                                      notificationChatChatConversationRow,
                                                      ParamType.SupabaseRow,
                                                    ),
                                                  }.withoutNulls,
                                                );
                                              },
                                              child: wrapWithModel(
                                                model: _model
                                                    .notificationChatModels
                                                    .getModel(
                                                  listViewChatNotificationsRow
                                                      .id
                                                      .toString(),
                                                  listViewIndex,
                                                ),
                                                updateCallback: () =>
                                                    safeSetState(() {}),
                                                child: NotificationChatWidget(
                                                  key: Key(
                                                    'Keyv8g_${listViewChatNotificationsRow.id.toString()}',
                                                  ),
                                                  chatNotification:
                                                      listViewChatNotificationsRow,
                                                ),
                                              ),
                                            );
                                          },
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
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 20.0, 0.0, 0.0),
                                child:
                                    FutureBuilder<List<DemandNotificationsRow>>(
                                  future: DemandNotificationsTable().queryRows(
                                    queryFn: (q) => q.eqOrNull(
                                      'user_id',
                                      valueOrDefault(
                                          currentUserDocument?.id, 0),
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
                                    List<DemandNotificationsRow>
                                        listViewDemandNotificationsRowList =
                                        snapshot.data!;

                                    return ListView.separated(
                                      padding: EdgeInsets.zero,
                                      primary: false,
                                      shrinkWrap: true,
                                      scrollDirection: Axis.vertical,
                                      itemCount:
                                          listViewDemandNotificationsRowList
                                              .length,
                                      separatorBuilder: (_, __) =>
                                          SizedBox(height: 10.0),
                                      itemBuilder: (context, listViewIndex) {
                                        final listViewDemandNotificationsRow =
                                            listViewDemandNotificationsRowList[
                                                listViewIndex];
                                        return wrapWithModel(
                                          model: _model.notificationDemandModels
                                              .getModel(
                                            listViewDemandNotificationsRow.id
                                                .toString(),
                                            listViewIndex,
                                          ),
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: NotificationDemandWidget(
                                            key: Key(
                                              'Key6yv_${listViewDemandNotificationsRow.id.toString()}',
                                            ),
                                            notification:
                                                listViewDemandNotificationsRow,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
