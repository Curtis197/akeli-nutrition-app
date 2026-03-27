import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/recipe_management/recipe_review/recipe_review_widget.dart';
import 'dart:ui';
import '/index.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'userprofile_model.dart';
export 'userprofile_model.dart';

class UserprofileWidget extends StatefulWidget {
  const UserprofileWidget({
    super.key,
    required this.users,
  });

  final UsersRow? users;

  static String routeName = 'userprofile';
  static String routePath = '/userprofile';

  @override
  State<UserprofileWidget> createState() => _UserprofileWidgetState();
}

class _UserprofileWidgetState extends State<UserprofileWidget>
    with TickerProviderStateMixin {
  late UserprofileModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => UserprofileModel());

    logFirebaseEvent('screen_view', parameters: {'screen_name': 'userprofile'});
    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      logFirebaseEvent('USERPROFILE_userprofile_ON_INIT_STATE');
      await Future.wait([
        Future(() async {
          logFirebaseEvent('userprofile_backend_call');
          _model.conv1 = await ConversationParticipantTable().queryRows(
            queryFn: (q) => q.eqOrNull(
              'user_id',
              widget!.users?.id,
            ),
          );
        }),
        Future(() async {
          logFirebaseEvent('userprofile_backend_call');
          _model.conv2 = await ConversationParticipantTable().queryRows(
            queryFn: (q) => q.eqOrNull(
              'user_id',
              valueOrDefault(currentUserDocument?.id, 0),
            ),
          );
        }),
      ]);
      logFirebaseEvent('userprofile_backend_call');
      _model.privateConv = await ChatConversationTable().queryRows(
        queryFn: (q) => q
            .inFilterOrNull(
              'id',
              _model.conv1?.map((e) => e.conversationId).withoutNulls.toList(),
            )
            .inFilterOrNull(
              'id',
              _model.conv2?.map((e) => e.conversationId).withoutNulls.toList(),
            )
            .eqOrNull(
              'grouped',
              false,
            ),
      );
    });

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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0.0, 40.0, 0.0, 0.0),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              alignment: AlignmentDirectional(0.0, -1.0),
              children: [
                Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [],
                    ),
                    Align(
                      alignment: AlignmentDirectional(0.0, -1.0),
                      child: Container(
                        width: 150.0,
                        height: 150.0,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primaryBackground,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: FlutterFlowTheme.of(context).secondary,
                          ),
                        ),
                        child: Visibility(
                          visible: widget!.users?.profilImageUrl == null ||
                              widget!.users?.profilImageUrl == '',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100.0),
                            child: Image.network(
                              'https://jfbfymiyqlyciapfloug.supabase.co/storage/v1/object/public/images/group_photo/360_F_65772719_A1UV5kLi5nCEWI0BNLLiFaBPEkUbv5Fv.jpg',
                              width: 148.0,
                              height: 148.0,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget!.users?.userName != null &&
                        widget!.users?.userName != '')
                      Text(
                        valueOrDefault<String>(
                          widget!.users?.userName,
                          'user name',
                        ),
                        style:
                            FlutterFlowTheme.of(context).headlineSmall.override(
                                  font: GoogleFonts.outfit(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .fontStyle,
                                  ),
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .fontStyle,
                                ),
                      ),
                  ],
                ),
                Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Align(
                          alignment: AlignmentDirectional(0.0, 1.0),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 250.0, 0.0, 0.0),
                            child: Container(
                              width: double.infinity,
                              height: 800.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 4.0,
                                    color: Color(0x320E151B),
                                    offset: Offset(
                                      0.0,
                                      -2.0,
                                    ),
                                  )
                                ],
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(0.0),
                                  bottomRight: Radius.circular(0.0),
                                  topLeft: Radius.circular(16.0),
                                  topRight: Radius.circular(16.0),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 12.0, 0.0, 0.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (widget!.users?.id !=
                                        valueOrDefault(
                                            currentUserDocument?.id, 0))
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            15.0, 0.0, 0.0, 0.0),
                                        child: AuthUserStreamWidget(
                                          builder: (context) => FutureBuilder<
                                              List<ConversationDemandRow>>(
                                            future: (_model.requestCompleter ??=
                                                    Completer<
                                                        List<
                                                            ConversationDemandRow>>()
                                                      ..complete(
                                                          ConversationDemandTable()
                                                              .querySingleRow(
                                                        queryFn: (q) => q
                                                            .eqOrNull(
                                                              'user_id',
                                                              valueOrDefault(
                                                                  currentUserDocument
                                                                      ?.id,
                                                                  0),
                                                            )
                                                            .eqOrNull(
                                                              'destined_user',
                                                              widget!.users?.id,
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
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .tertiary,
                                                      size: 50.0,
                                                    ),
                                                  ),
                                                );
                                              }
                                              List<ConversationDemandRow>
                                                  conversationDemandRowConversationDemandRowList =
                                                  snapshot.data!;

                                              final conversationDemandRowConversationDemandRow =
                                                  conversationDemandRowConversationDemandRowList
                                                          .isNotEmpty
                                                      ? conversationDemandRowConversationDemandRowList
                                                          .first
                                                      : null;

                                              return Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Expanded(
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(),
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(),
                                                            child: FutureBuilder<
                                                                ApiCallResponse>(
                                                              future: (_model.apiRequestCompleter ??= Completer<
                                                                      ApiCallResponse>()
                                                                    ..complete(
                                                                        SupabaseGroup
                                                                            .searchAConversationCall
                                                                            .call(
                                                                      destinedUserId: widget!
                                                                          .users
                                                                          ?.id,
                                                                      userId: valueOrDefault(
                                                                          currentUserDocument
                                                                              ?.id,
                                                                          0),
                                                                    )))
                                                                  .future,
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
                                                                final chatConvSearchAConversationResponse =
                                                                    snapshot
                                                                        .data!;

                                                                return Container(
                                                                  decoration:
                                                                      BoxDecoration(),
                                                                  child: FutureBuilder<
                                                                      List<
                                                                          ChatConversationRow>>(
                                                                    future: ChatConversationTable()
                                                                        .querySingleRow(
                                                                      queryFn:
                                                                          (q) =>
                                                                              q.eqOrNull(
                                                                        'id',
                                                                        SupabaseGroup
                                                                            .searchAConversationCall
                                                                            .conversationId(
                                                                          chatConvSearchAConversationResponse
                                                                              .jsonBody,
                                                                        ),
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
                                                                            width:
                                                                                50.0,
                                                                            height:
                                                                                50.0,
                                                                            child:
                                                                                SpinKitDoubleBounce(
                                                                              color: FlutterFlowTheme.of(context).tertiary,
                                                                              size: 50.0,
                                                                            ),
                                                                          ),
                                                                        );
                                                                      }
                                                                      List<ChatConversationRow>
                                                                          rowChatConversationRowList =
                                                                          snapshot
                                                                              .data!;

                                                                      final rowChatConversationRow = rowChatConversationRowList
                                                                              .isNotEmpty
                                                                          ? rowChatConversationRowList
                                                                              .first
                                                                          : null;

                                                                      return Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        children:
                                                                            [
                                                                          if (!SupabaseGroup.searchAConversationCall.found(
                                                                                chatConvSearchAConversationResponse.jsonBody,
                                                                              )! &&
                                                                              (conversationDemandRowConversationDemandRow?.id == null) &&
                                                                              widget!.users!.public!)
                                                                            FFButtonWidget(
                                                                              onPressed: () async {
                                                                                logFirebaseEvent('USERPROFILE_PAGE_AJOUTER_BTN_ON_TAP');
                                                                                logFirebaseEvent('Button_backend_call');
                                                                                _model.newDemand = await ConversationDemandTable().insert({
                                                                                  'user_id': valueOrDefault(currentUserDocument?.id, 0),
                                                                                  'destined_user': widget!.users?.id,
                                                                                  'grouped': false,
                                                                                });
                                                                                logFirebaseEvent('Button_refresh_database_request');
                                                                                safeSetState(() => _model.requestCompleter = null);
                                                                                await _model.waitForRequestCompleted();
                                                                                logFirebaseEvent('Button_backend_call');
                                                                                _model.conversationRequest = await SupabaseGroup.conversationRequestCall.call(
                                                                                  demandId: _model.newDemand?.id,
                                                                                  grouped: false,
                                                                                  destinedUserId: widget!.users?.id,
                                                                                  userId: valueOrDefault(currentUserDocument?.id, 0),
                                                                                  conversationId: 0,
                                                                                );

                                                                                safeSetState(() {});
                                                                              },
                                                                              text: FFLocalizations.of(context).getText(
                                                                                '4wmuze30' /* Ajouter */,
                                                                              ),
                                                                              icon: Icon(
                                                                                Icons.add,
                                                                                size: 15.0,
                                                                              ),
                                                                              options: FFButtonOptions(
                                                                                height: 30.0,
                                                                                padding: EdgeInsetsDirectional.fromSTEB(10.0, 0.0, 10.0, 0.0),
                                                                                iconAlignment: IconAlignment.end,
                                                                                iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                                                                                color: FlutterFlowTheme.of(context).primary,
                                                                                textStyle: FlutterFlowTheme.of(context).labelSmall.override(
                                                                                      font: GoogleFonts.poppins(
                                                                                        fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                        fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                      ),
                                                                                      color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                      letterSpacing: 0.0,
                                                                                      fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                      fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                    ),
                                                                                elevation: 0.0,
                                                                                borderSide: BorderSide(
                                                                                  color: FlutterFlowTheme.of(context).primary,
                                                                                ),
                                                                                borderRadius: BorderRadius.circular(8.0),
                                                                              ),
                                                                            ),
                                                                          if (SupabaseGroup.searchAConversationCall.found(
                                                                                chatConvSearchAConversationResponse.jsonBody,
                                                                              ) ??
                                                                              true)
                                                                            Row(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              children: [
                                                                                FFButtonWidget(
                                                                                  onPressed: () async {
                                                                                    logFirebaseEvent('USERPROFILE_PAGE_ECRIRE_BTN_ON_TAP');
                                                                                    logFirebaseEvent('Button_navigate_to');

                                                                                    context.pushNamed(
                                                                                      ChatPageWidget.routeName,
                                                                                      queryParameters: {
                                                                                        'conversation': serializeParam(
                                                                                          rowChatConversationRow,
                                                                                          ParamType.SupabaseRow,
                                                                                        ),
                                                                                        'destinedUserId': serializeParam(
                                                                                          widget!.users?.id,
                                                                                          ParamType.int,
                                                                                        ),
                                                                                      }.withoutNulls,
                                                                                    );
                                                                                  },
                                                                                  text: FFLocalizations.of(context).getText(
                                                                                    'eo755sgt' /* Ecrire */,
                                                                                  ),
                                                                                  icon: Icon(
                                                                                    Icons.send_rounded,
                                                                                    size: 15.0,
                                                                                  ),
                                                                                  options: FFButtonOptions(
                                                                                    height: 30.0,
                                                                                    padding: EdgeInsetsDirectional.fromSTEB(10.0, 0.0, 10.0, 0.0),
                                                                                    iconAlignment: IconAlignment.end,
                                                                                    iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                                                                                    color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                    textStyle: FlutterFlowTheme.of(context).labelSmall.override(
                                                                                          font: GoogleFonts.poppins(
                                                                                            fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                            fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                          ),
                                                                                          color: FlutterFlowTheme.of(context).primary,
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                          fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                        ),
                                                                                    elevation: 0.0,
                                                                                    borderSide: BorderSide(
                                                                                      color: FlutterFlowTheme.of(context).primary,
                                                                                    ),
                                                                                    borderRadius: BorderRadius.circular(8.0),
                                                                                  ),
                                                                                ),
                                                                                FFButtonWidget(
                                                                                  onPressed: () async {
                                                                                    logFirebaseEvent('USERPROFILE_QUITTER_LA_CONVERSATION_BTN_');
                                                                                    logFirebaseEvent('Button_backend_call');
                                                                                    _model.deletedMessage = await ChatMessageTable().delete(
                                                                                      matchingRows: (rows) => rows.eqOrNull(
                                                                                        'conversation_id',
                                                                                        rowChatConversationRow?.id,
                                                                                      ),
                                                                                      returnRows: true,
                                                                                    );
                                                                                    logFirebaseEvent('Button_backend_call');
                                                                                    await ConversationParticipantTable().delete(
                                                                                      matchingRows: (rows) => rows.eqOrNull(
                                                                                        'conversation_id',
                                                                                        rowChatConversationRow?.id,
                                                                                      ),
                                                                                    );
                                                                                    logFirebaseEvent('Button_backend_call');
                                                                                    _model.deletedConversation = await ChatConversationTable().delete(
                                                                                      matchingRows: (rows) => rows.eqOrNull(
                                                                                        'id',
                                                                                        rowChatConversationRow?.id,
                                                                                      ),
                                                                                      returnRows: true,
                                                                                    );
                                                                                    logFirebaseEvent('Button_refresh_database_request');
                                                                                    safeSetState(() => _model.apiRequestCompleter = null);
                                                                                    await _model.waitForApiRequestCompleted();

                                                                                    safeSetState(() {});
                                                                                  },
                                                                                  text: FFLocalizations.of(context).getText(
                                                                                    'w887piq3' /* Quitter la Conversation */,
                                                                                  ),
                                                                                  options: FFButtonOptions(
                                                                                    height: 30.0,
                                                                                    padding: EdgeInsetsDirectional.fromSTEB(10.0, 0.0, 10.0, 0.0),
                                                                                    iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                                                                                    color: FlutterFlowTheme.of(context).secondary,
                                                                                    textStyle: FlutterFlowTheme.of(context).labelSmall.override(
                                                                                          font: GoogleFonts.poppins(
                                                                                            fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                            fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                          ),
                                                                                          color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                          fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                        ),
                                                                                    elevation: 0.0,
                                                                                    borderRadius: BorderRadius.circular(8.0),
                                                                                  ),
                                                                                ),
                                                                              ].divide(SizedBox(width: 5.0)),
                                                                            ),
                                                                        ].divide(SizedBox(width: 10.0)),
                                                                      );
                                                                    },
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (conversationDemandRowConversationDemandRow
                                                          ?.id !=
                                                      null)
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  0.0,
                                                                  15.0,
                                                                  0.0),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8.0),
                                                              border:
                                                                  Border.all(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .tertiary,
                                                              ),
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          8.0,
                                                                          5.0,
                                                                          8.0,
                                                                          5.0),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                children: [
                                                                  Text(
                                                                    FFLocalizations.of(
                                                                            context)
                                                                        .getText(
                                                                      '9zw207if' /* demande envoyée */,
                                                                    ),
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelSmall
                                                                        .override(
                                                                          font:
                                                                              GoogleFonts.poppins(
                                                                            fontWeight:
                                                                                FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                          ),
                                                                          color:
                                                                              FlutterFlowTheme.of(context).tertiary,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          fontWeight: FlutterFlowTheme.of(context)
                                                                              .labelSmall
                                                                              .fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .labelSmall
                                                                              .fontStyle,
                                                                        ),
                                                                  ),
                                                                  Icon(
                                                                    Icons
                                                                        .check_sharp,
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .tertiary,
                                                                    size: 18.0,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          FFButtonWidget(
                                                            onPressed:
                                                                () async {
                                                              logFirebaseEvent(
                                                                  'USERPROFILE_PAGE_ANNULER_BTN_ON_TAP');
                                                              logFirebaseEvent(
                                                                  'Button_backend_call');
                                                              await ConversationDemandTable()
                                                                  .delete(
                                                                matchingRows:
                                                                    (rows) => rows
                                                                        .eqOrNull(
                                                                  'id',
                                                                  conversationDemandRowConversationDemandRow
                                                                      ?.id,
                                                                ),
                                                              );
                                                              logFirebaseEvent(
                                                                  'Button_refresh_database_request');
                                                              safeSetState(() =>
                                                                  _model.requestCompleter =
                                                                      null);
                                                              await _model
                                                                  .waitForRequestCompleted();
                                                            },
                                                            text: FFLocalizations
                                                                    .of(context)
                                                                .getText(
                                                              'aem654dd' /* Annuler */,
                                                            ),
                                                            options:
                                                                FFButtonOptions(
                                                              height: 30.0,
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          10.0,
                                                                          0.0,
                                                                          10.0,
                                                                          0.0),
                                                              iconPadding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          0.0),
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .tertiary,
                                                              textStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelSmall
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .poppins(
                                                                          fontWeight: FlutterFlowTheme.of(context)
                                                                              .labelSmall
                                                                              .fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .labelSmall
                                                                              .fontStyle,
                                                                        ),
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .labelSmall
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .labelSmall
                                                                            .fontStyle,
                                                                      ),
                                                              elevation: 0.0,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8.0),
                                                            ),
                                                          ),
                                                        ].divide(SizedBox(
                                                            width: 5.0)),
                                                      ),
                                                    ),
                                                ].divide(SizedBox(width: 10.0)),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          16.0, 12.0, 16.0, 12.0),
                                      child: Text(
                                        valueOrDefault<String>(
                                          widget!.users?.description,
                                          'user description',
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
                                      ),
                                    ),
                                    if (!widget!.users!.public!)
                                      Align(
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0),
                                        child: Container(
                                          width: 350.0,
                                          height: 85.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'tmvua8mq' /* Ce compte est privé */,
                                                ),
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .headlineMedium
                                                    .override(
                                                      font: GoogleFonts.outfit(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .headlineMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .headlineMedium
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
                                                              .headlineMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .headlineMedium
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (widget!.users?.public ?? true)
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 12.0, 0.0, 0.0),
                                          child: Column(
                                            children: [
                                              Align(
                                                alignment: Alignment(0.0, 0),
                                                child: TabBar(
                                                  labelColor:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .primaryText,
                                                  unselectedLabelColor:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .secondaryText,
                                                  labelStyle: FlutterFlowTheme
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
                                                  unselectedLabelStyle:
                                                      TextStyle(),
                                                  indicatorColor:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .primaryText,
                                                  tabs: [
                                                    Tab(
                                                      text: FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'ilngfzyn' /* Favoris */,
                                                      ),
                                                    ),
                                                    Tab(
                                                      text: FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'lwxq1ua9' /* Groupe */,
                                                      ),
                                                    ),
                                                    Tab(
                                                      text: FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'o4xoiw2j' /* Commentaire */,
                                                      ),
                                                    ),
                                                  ],
                                                  controller:
                                                      _model.tabBarController,
                                                  onTap: (i) async {
                                                    [
                                                      () async {},
                                                      () async {},
                                                      () async {}
                                                    ][i]();
                                                  },
                                                ),
                                              ),
                                              Expanded(
                                                child: TabBarView(
                                                  controller:
                                                      _model.tabBarController,
                                                  children: [
                                                    StreamBuilder<
                                                        List<ReceipeLikesRow>>(
                                                      stream: _model
                                                              .containerSupabaseStream ??=
                                                          SupaFlow.client
                                                              .from(
                                                                  "receipe_likes")
                                                              .stream(
                                                                  primaryKey: [
                                                                    'id'
                                                                  ])
                                                              .eqOrNull(
                                                                'user_id',
                                                                widget!
                                                                    .users?.id,
                                                              )
                                                              .map((list) => list
                                                                  .map((item) =>
                                                                      ReceipeLikesRow(
                                                                          item))
                                                                  .toList()),
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
                                                        List<ReceipeLikesRow>
                                                            containerReceipeLikesRowList =
                                                            snapshot.data!;

                                                        return Container(
                                                          decoration:
                                                              BoxDecoration(),
                                                          child: Visibility(
                                                            visible:
                                                                containerReceipeLikesRowList
                                                                    .isNotEmpty,
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          24.0),
                                                              child: Builder(
                                                                builder:
                                                                    (context) {
                                                                  final containerVar =
                                                                      containerReceipeLikesRowList
                                                                          .toList();

                                                                  return ListView
                                                                      .builder(
                                                                    padding:
                                                                        EdgeInsets
                                                                            .zero,
                                                                    primary:
                                                                        false,
                                                                    scrollDirection:
                                                                        Axis.vertical,
                                                                    itemCount:
                                                                        containerVar
                                                                            .length,
                                                                    itemBuilder:
                                                                        (context,
                                                                            containerVarIndex) {
                                                                      final containerVarItem =
                                                                          containerVar[
                                                                              containerVarIndex];
                                                                      return Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            16.0,
                                                                            12.0,
                                                                            16.0,
                                                                            8.0),
                                                                        child: FutureBuilder<
                                                                            List<ReceipeRow>>(
                                                                          future:
                                                                              ReceipeTable().querySingleRow(
                                                                            queryFn: (q) =>
                                                                                q.eqOrNull(
                                                                              'id',
                                                                              containerVarItem.receipeId,
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
                                                                                  child: SpinKitDoubleBounce(
                                                                                    color: FlutterFlowTheme.of(context).tertiary,
                                                                                    size: 50.0,
                                                                                  ),
                                                                                ),
                                                                              );
                                                                            }
                                                                            List<ReceipeRow>
                                                                                rowReceipeRowList =
                                                                                snapshot.data!;

                                                                            final rowReceipeRow = rowReceipeRowList.isNotEmpty
                                                                                ? rowReceipeRowList.first
                                                                                : null;

                                                                            return Row(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                              children: [
                                                                                Expanded(
                                                                                  child: Column(
                                                                                    mainAxisSize: MainAxisSize.max,
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                      Padding(
                                                                                        padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 8.0),
                                                                                        child: Text(
                                                                                          valueOrDefault<String>(
                                                                                            rowReceipeRow?.name,
                                                                                            'receipe name',
                                                                                          ),
                                                                                          style: FlutterFlowTheme.of(context).headlineSmall.override(
                                                                                                font: GoogleFonts.outfit(
                                                                                                  fontWeight: FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                                                                                                  fontStyle: FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                                                                                                ),
                                                                                                letterSpacing: 0.0,
                                                                                                fontWeight: FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                                                                                                fontStyle: FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                                                                                              ),
                                                                                        ),
                                                                                      ),
                                                                                      Text(
                                                                                        valueOrDefault<String>(
                                                                                          rowReceipeRow?.description,
                                                                                          'receipe description',
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
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                                Padding(
                                                                                  padding: EdgeInsetsDirectional.fromSTEB(8.0, 8.0, 0.0, 8.0),
                                                                                  child: ClipRRect(
                                                                                    borderRadius: BorderRadius.circular(12.0),
                                                                                    child: Image.network(
                                                                                      'https://images.unsplash.com/photo-1519582149095-fe7d19b2a3d2?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxzZWFyY2h8NHx8d2F0ZXJmYWxsfGVufDB8fDB8fA%3D%3D&auto=format&fit=crop&w=500&q=60',
                                                                                      width: 100.0,
                                                                                      height: 100.0,
                                                                                      fit: BoxFit.cover,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            );
                                                                          },
                                                                        ),
                                                                      );
                                                                    },
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                    FutureBuilder<
                                                        List<
                                                            ConversationParticipantRow>>(
                                                      future:
                                                          ConversationParticipantTable()
                                                              .queryRows(
                                                        queryFn: (q) =>
                                                            q.eqOrNull(
                                                          'user_id',
                                                          widget!.users?.id,
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
                                                        List<ConversationParticipantRow>
                                                            containerConversationParticipantRowList =
                                                            snapshot.data!;

                                                        return Container(
                                                          decoration:
                                                              BoxDecoration(),
                                                          child: Visibility(
                                                            visible:
                                                                containerConversationParticipantRowList
                                                                    .isNotEmpty,
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          24.0),
                                                              child: Builder(
                                                                builder:
                                                                    (context) {
                                                                  final containerVar =
                                                                      containerConversationParticipantRowList
                                                                          .toList();

                                                                  return ListView
                                                                      .builder(
                                                                    padding:
                                                                        EdgeInsets
                                                                            .zero,
                                                                    primary:
                                                                        false,
                                                                    shrinkWrap:
                                                                        true,
                                                                    scrollDirection:
                                                                        Axis.vertical,
                                                                    itemCount:
                                                                        containerVar
                                                                            .length,
                                                                    itemBuilder:
                                                                        (context,
                                                                            containerVarIndex) {
                                                                      final containerVarItem =
                                                                          containerVar[
                                                                              containerVarIndex];
                                                                      return FutureBuilder<
                                                                          List<
                                                                              ChatConversationRow>>(
                                                                        future:
                                                                            ChatConversationTable().querySingleRow(
                                                                          queryFn: (q) =>
                                                                              q.eqOrNull(
                                                                            'id',
                                                                            containerVarItem.conversationId,
                                                                          ),
                                                                        ),
                                                                        builder:
                                                                            (context,
                                                                                snapshot) {
                                                                          // Customize what your widget looks like when it's loading.
                                                                          if (!snapshot
                                                                              .hasData) {
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
                                                                          List<ChatConversationRow>
                                                                              containerChatConversationRowList =
                                                                              snapshot.data!;

                                                                          final containerChatConversationRow = containerChatConversationRowList.isNotEmpty
                                                                              ? containerChatConversationRowList.first
                                                                              : null;

                                                                          return Container(
                                                                            decoration:
                                                                                BoxDecoration(),
                                                                            child:
                                                                                Visibility(
                                                                              visible: containerChatConversationRow?.grouped ?? true,
                                                                              child: Padding(
                                                                                padding: EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 8.0),
                                                                                child: FutureBuilder<List<ConversationGroupRow>>(
                                                                                  future: ConversationGroupTable().querySingleRow(
                                                                                    queryFn: (q) => q.eqOrNull(
                                                                                      'conversation_id',
                                                                                      containerChatConversationRow?.id,
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
                                                                                    List<ConversationGroupRow> rowConversationGroupRowList = snapshot.data!;

                                                                                    final rowConversationGroupRow = rowConversationGroupRowList.isNotEmpty ? rowConversationGroupRowList.first : null;

                                                                                    return InkWell(
                                                                                      splashColor: Colors.transparent,
                                                                                      focusColor: Colors.transparent,
                                                                                      hoverColor: Colors.transparent,
                                                                                      highlightColor: Colors.transparent,
                                                                                      onTap: () async {
                                                                                        logFirebaseEvent('USERPROFILE_PAGE_Row_70e1jz8t_ON_TAP');
                                                                                        logFirebaseEvent('Row_navigate_to');

                                                                                        context.pushNamed(
                                                                                          GroupPageWidget.routeName,
                                                                                          queryParameters: {
                                                                                            'conversation': serializeParam(
                                                                                              containerChatConversationRow,
                                                                                              ParamType.SupabaseRow,
                                                                                            ),
                                                                                          }.withoutNulls,
                                                                                        );
                                                                                      },
                                                                                      child: Row(
                                                                                        mainAxisSize: MainAxisSize.max,
                                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                        children: [
                                                                                          Expanded(
                                                                                            child: Column(
                                                                                              mainAxisSize: MainAxisSize.max,
                                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                                              children: [
                                                                                                Padding(
                                                                                                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 8.0),
                                                                                                  child: Text(
                                                                                                    valueOrDefault<String>(
                                                                                                      rowConversationGroupRow?.name,
                                                                                                      'group name',
                                                                                                    ),
                                                                                                    style: FlutterFlowTheme.of(context).headlineSmall.override(
                                                                                                          font: GoogleFonts.outfit(
                                                                                                            fontWeight: FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                                                                                                            fontStyle: FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                                                                                                          ),
                                                                                                          letterSpacing: 0.0,
                                                                                                          fontWeight: FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                                                                                                          fontStyle: FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                                                                                                        ),
                                                                                                  ),
                                                                                                ),
                                                                                                Text(
                                                                                                  valueOrDefault<String>(
                                                                                                    rowConversationGroupRow?.description,
                                                                                                    'group description',
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
                                                                                              ],
                                                                                            ),
                                                                                          ),
                                                                                          Padding(
                                                                                            padding: EdgeInsetsDirectional.fromSTEB(8.0, 8.0, 0.0, 8.0),
                                                                                            child: ClipRRect(
                                                                                              borderRadius: BorderRadius.circular(12.0),
                                                                                              child: Image.network(
                                                                                                'https://images.unsplash.com/photo-1519582149095-fe7d19b2a3d2?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxzZWFyY2h8NHx8d2F0ZXJmYWxsfGVufDB8fDB8fA%3D%3D&auto=format&fit=crop&w=500&q=60',
                                                                                                width: 100.0,
                                                                                                height: 100.0,
                                                                                                fit: BoxFit.cover,
                                                                                              ),
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
                                                                    },
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                    Container(
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      decoration: BoxDecoration(
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .primaryBackground,
                                                      ),
                                                      child: FutureBuilder<
                                                          List<
                                                              ReceipeCommentsRow>>(
                                                        future:
                                                            ReceipeCommentsTable()
                                                                .queryRows(
                                                          queryFn: (q) =>
                                                              q.eqOrNull(
                                                            'user_id',
                                                            widget!.users?.id,
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
                                                          List<ReceipeCommentsRow>
                                                              containerReceipeCommentsRowList =
                                                              snapshot.data!;

                                                          return Container(
                                                            decoration:
                                                                BoxDecoration(),
                                                            child: Visibility(
                                                              visible:
                                                                  containerReceipeCommentsRowList
                                                                      .isNotEmpty,
                                                              child: Builder(
                                                                builder:
                                                                    (context) {
                                                                  final containerVar =
                                                                      containerReceipeCommentsRowList
                                                                          .toList();

                                                                  return ListView
                                                                      .builder(
                                                                    padding:
                                                                        EdgeInsets
                                                                            .zero,
                                                                    primary:
                                                                        false,
                                                                    scrollDirection:
                                                                        Axis.vertical,
                                                                    itemCount:
                                                                        containerVar
                                                                            .length,
                                                                    itemBuilder:
                                                                        (context,
                                                                            containerVarIndex) {
                                                                      final containerVarItem =
                                                                          containerVar[
                                                                              containerVarIndex];
                                                                      return wrapWithModel(
                                                                        model: _model
                                                                            .recipeReviewModels
                                                                            .getModel(
                                                                          containerVarItem
                                                                              .id
                                                                              .toString(),
                                                                          containerVarIndex,
                                                                        ),
                                                                        updateCallback:
                                                                            () =>
                                                                                safeSetState(() {}),
                                                                        child:
                                                                            RecipeReviewWidget(
                                                                          key:
                                                                              Key(
                                                                            'Key347_${containerVarItem.id.toString()}',
                                                                          ),
                                                                          receipeComment:
                                                                              containerVarItem,
                                                                        ),
                                                                      );
                                                                    },
                                                                  );
                                                                },
                                                              ),
                                                            ),
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
                                      ),
                                  ]
                                      .divide(SizedBox(height: 20.0))
                                      .around(SizedBox(height: 20.0)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 0.0, 0.0),
                        child: FlutterFlowIconButton(
                          borderRadius: 100.0,
                          buttonSize: 40.0,
                          fillColor: FlutterFlowTheme.of(context).primary,
                          icon: Icon(
                            Icons.arrow_back,
                            color: FlutterFlowTheme.of(context).info,
                            size: 24.0,
                          ),
                          onPressed: () async {
                            logFirebaseEvent(
                                'USERPROFILE_PAGE_arrow_back_ICN_ON_TAP');
                            logFirebaseEvent('IconButton_navigate_back');
                            context.safePop();
                          },
                        ),
                      ),
                    ],
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
