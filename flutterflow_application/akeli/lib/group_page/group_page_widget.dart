import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/community/delete_group/delete_group_widget.dart';
import '/components/conversation_message_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/profil_management/edit_group/edit_group_widget.dart';
import 'dart:ui';
import '/index.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'group_page_model.dart';
export 'group_page_model.dart';

class GroupPageWidget extends StatefulWidget {
  const GroupPageWidget({
    super.key,
    required this.conversation,
  });

  final ChatConversationRow? conversation;

  static String routeName = 'group_page';
  static String routePath = '/groupPage';

  @override
  State<GroupPageWidget> createState() => _GroupPageWidgetState();
}

class _GroupPageWidgetState extends State<GroupPageWidget> {
  late GroupPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => GroupPageModel());

    logFirebaseEvent('screen_view', parameters: {'screen_name': 'group_page'});
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
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              Align(
                alignment: AlignmentDirectional(0.0, 0.0),
                child: FutureBuilder<List<ConversationGroupRow>>(
                  future: ConversationGroupTable().querySingleRow(
                    queryFn: (q) => q.eqOrNull(
                      'conversation_id',
                      widget!.conversation?.id,
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
                    List<ConversationGroupRow> columnConversationGroupRowList =
                        snapshot.data!;

                    final columnConversationGroupRow =
                        columnConversationGroupRowList.isNotEmpty
                            ? columnConversationGroupRowList.first
                            : null;

                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Stack(
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  if (columnConversationGroupRow?.imageUrl ==
                                          null ||
                                      columnConversationGroupRow?.imageUrl ==
                                          '')
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(0.0),
                                      child: Image.network(
                                        'https://jfbfymiyqlyciapfloug.supabase.co/storage/v1/object/public/images/group_photo/jive-sgroup-default-portrait-large.png',
                                        width: double.infinity,
                                        height: 250.0,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  if (columnConversationGroupRow?.imageUrl !=
                                          null &&
                                      columnConversationGroupRow?.imageUrl !=
                                          '')
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(0.0),
                                      child: Image.network(
                                        columnConversationGroupRow!.imageUrl!,
                                        width: double.infinity,
                                        height: 250.0,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                ],
                              ),
                              Align(
                                alignment: AlignmentDirectional(0.0, 1.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 20.0, 0.0, 0.0),
                                  child: Text(
                                    valueOrDefault<String>(
                                      columnConversationGroupRow?.name,
                                      'Group Name',
                                    ),
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
                                              .secondaryText,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .headlineLarge
                                                  .fontStyle,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            FFLocalizations.of(context).getText(
                              'f9vtvdvu' /* Description */,
                            ),
                            style: FlutterFlowTheme.of(context)
                                .headlineSmall
                                .override(
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
                          Container(
                            width: MediaQuery.sizeOf(context).width * 0.8,
                            decoration: BoxDecoration(),
                            child: Visibility(
                              visible: columnConversationGroupRow
                                          ?.description !=
                                      null &&
                                  columnConversationGroupRow?.description != '',
                              child: Text(
                                valueOrDefault<String>(
                                  columnConversationGroupRow?.description,
                                  'Group Description',
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
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            ),
                          ),
                          AuthUserStreamWidget(
                            builder: (context) =>
                                FutureBuilder<List<ConversationDemandRow>>(
                              future: ConversationDemandTable().querySingleRow(
                                queryFn: (q) => q
                                    .eqOrNull(
                                      'conversation_id',
                                      columnConversationGroupRow
                                          ?.conversationId,
                                    )
                                    .eqOrNull(
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
                                List<ConversationDemandRow>
                                    convDemandColumnConversationDemandRowList =
                                    snapshot.data!;

                                // Return an empty Container when the item does not exist.
                                if (snapshot.data!.isEmpty) {
                                  return Container();
                                }
                                final convDemandColumnConversationDemandRow =
                                    convDemandColumnConversationDemandRowList
                                            .isNotEmpty
                                        ? convDemandColumnConversationDemandRowList
                                            .first
                                        : null;

                                return Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        border: Border.all(
                                          color: FlutterFlowTheme.of(context)
                                              .tertiary,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                'oi59hdwy' /* Demande envoyé */,
                                              ),
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .labelLarge
                                                  .override(
                                                    font: GoogleFonts.poppins(
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
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .tertiary,
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
                                            Icon(
                                              Icons.check,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .tertiary,
                                              size: 18.0,
                                            ),
                                          ].divide(SizedBox(width: 10.0)),
                                        ),
                                      ),
                                    ),
                                    FFButtonWidget(
                                      onPressed: () async {
                                        logFirebaseEvent(
                                            'GROUP_ANNULER_DEMANDE_BTN_ON_TAP');
                                        logFirebaseEvent('Button_backend_call');
                                        await ConversationDemandTable().delete(
                                          matchingRows: (rows) => rows
                                              .eqOrNull(
                                                'conversation_id',
                                                widget!.conversation?.id,
                                              )
                                              .eqOrNull(
                                                'user_id',
                                                valueOrDefault(
                                                    currentUserDocument?.id, 0),
                                              ),
                                        );
                                        logFirebaseEvent(
                                            'Button_refresh_database_request');
                                        safeSetState(() =>
                                            _model.requestCompleter3 = null);
                                        logFirebaseEvent(
                                            'Button_refresh_database_request');
                                        safeSetState(() =>
                                            _model.requestCompleter2 = null);
                                        logFirebaseEvent(
                                            'Button_refresh_database_request');
                                        safeSetState(() =>
                                            _model.requestCompleter1 = null);

                                        safeSetState(() {});
                                      },
                                      text: FFLocalizations.of(context).getText(
                                        '0yank55w' /* Annuler demande */,
                                      ),
                                      options: FFButtonOptions(
                                        height: 40.0,
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            16.0, 0.0, 16.0, 0.0),
                                        iconPadding:
                                            EdgeInsetsDirectional.fromSTEB(
                                                0.0, 0.0, 0.0, 0.0),
                                        color: FlutterFlowTheme.of(context)
                                            .tertiary,
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
                                  ].divide(SizedBox(width: 5.0)),
                                );
                              },
                            ),
                          ),
                          AuthUserStreamWidget(
                            builder: (context) =>
                                FutureBuilder<List<ConversationParticipantRow>>(
                              future: (_model.requestCompleter2 ??= Completer<
                                      List<ConversationParticipantRow>>()
                                    ..complete(ConversationParticipantTable()
                                        .querySingleRow(
                                      queryFn: (q) => q
                                          .eqOrNull(
                                            'conversation_id',
                                            widget!.conversation?.id,
                                          )
                                          .eqOrNull(
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
                                List<ConversationParticipantRow>
                                    conversattionParticipantConversationParticipantRowList =
                                    snapshot.data!;

                                final conversattionParticipantConversationParticipantRow =
                                    conversattionParticipantConversationParticipantRowList
                                            .isNotEmpty
                                        ? conversattionParticipantConversationParticipantRowList
                                            .first
                                        : null;

                                return Container(
                                  decoration: BoxDecoration(),
                                  child: FutureBuilder<
                                      List<ConversationDemandRow>>(
                                    future:
                                        (_model.requestCompleter3 ??= Completer<
                                                List<ConversationDemandRow>>()
                                              ..complete(
                                                  ConversationDemandTable()
                                                      .querySingleRow(
                                                queryFn: (q) => q
                                                    .eqOrNull(
                                                      'conversation_id',
                                                      widget!.conversation?.id,
                                                    )
                                                    .eqOrNull(
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
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .tertiary,
                                              size: 50.0,
                                            ),
                                          ),
                                        );
                                      }
                                      List<ConversationDemandRow>
                                          conversationDemandConversationDemandRowList =
                                          snapshot.data!;

                                      final conversationDemandConversationDemandRow =
                                          conversationDemandConversationDemandRowList
                                                  .isNotEmpty
                                              ? conversationDemandConversationDemandRowList
                                                  .first
                                              : null;

                                      return Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if ((conversationDemandConversationDemandRow
                                                      ?.id ==
                                                  null) &&
                                              (conversattionParticipantConversationParticipantRow
                                                      ?.id ==
                                                  null))
                                            FFButtonWidget(
                                              onPressed: () async {
                                                logFirebaseEvent(
                                                    'GROUP_PAGE_PAGE_REJOINDRE_BTN_ON_TAP');
                                                logFirebaseEvent(
                                                    'Button_backend_call');
                                                _model.groupDemand =
                                                    await ConversationDemandTable()
                                                        .insert({
                                                  'conversation_id':
                                                      widget!.conversation?.id,
                                                  'user_id': valueOrDefault(
                                                      currentUserDocument?.id,
                                                      0),
                                                });
                                                logFirebaseEvent(
                                                    'Button_refresh_database_request');
                                                safeSetState(() => _model
                                                    .requestCompleter3 = null);
                                                logFirebaseEvent(
                                                    'Button_refresh_database_request');
                                                safeSetState(() => _model
                                                    .requestCompleter2 = null);
                                                logFirebaseEvent(
                                                    'Button_refresh_database_request');
                                                safeSetState(() => _model
                                                    .requestCompleter1 = null);
                                                logFirebaseEvent(
                                                    'Button_backend_call');
                                                _model.apiResultek0 =
                                                    await SupabaseGroup
                                                        .conversationRequestCall
                                                        .call(
                                                  demandId:
                                                      _model.groupDemand?.id,
                                                  conversationId:
                                                      conversationDemandConversationDemandRow
                                                          ?.conversationId,
                                                  grouped: true,
                                                  userId: valueOrDefault(
                                                      currentUserDocument?.id,
                                                      0),
                                                );

                                                safeSetState(() {});
                                              },
                                              text: FFLocalizations.of(context)
                                                  .getText(
                                                '5d0vz9zc' /* Rejoindre */,
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
                                        ],
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          FutureBuilder<List<ConversationDemandRow>>(
                            future: (_model.requestCompleter1 ??=
                                    Completer<List<ConversationDemandRow>>()
                                      ..complete(
                                          ConversationDemandTable().queryRows(
                                        queryFn: (q) => q.eqOrNull(
                                          'conversation_id',
                                          widget!.conversation?.id,
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
                                          FlutterFlowTheme.of(context).tertiary,
                                      size: 50.0,
                                    ),
                                  ),
                                );
                              }
                              List<ConversationDemandRow>
                                  convDemandContConversationDemandRowList =
                                  snapshot.data!;

                              return Container(
                                decoration: BoxDecoration(),
                                child: Visibility(
                                  visible: (widget!.conversation?.adminUserId ==
                                          valueOrDefault(
                                              currentUserDocument?.id, 0)) &&
                                      (convDemandContConversationDemandRowList
                                          .isNotEmpty),
                                  child: AuthUserStreamWidget(
                                    builder: (context) => Column(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Text(
                                          FFLocalizations.of(context).getText(
                                            'aqka5xzr' /* Demandes */,
                                          ),
                                          style: FlutterFlowTheme.of(context)
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
                                                    FlutterFlowTheme.of(context)
                                                        .titleLarge
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleLarge
                                                        .fontStyle,
                                              ),
                                        ),
                                        Builder(
                                          builder: (context) {
                                            final containerVar =
                                                convDemandContConversationDemandRowList
                                                    .toList();

                                            return ListView.builder(
                                              padding: EdgeInsets.zero,
                                              primary: false,
                                              shrinkWrap: true,
                                              scrollDirection: Axis.vertical,
                                              itemCount: containerVar.length,
                                              itemBuilder:
                                                  (context, containerVarIndex) {
                                                final containerVarItem =
                                                    containerVar[
                                                        containerVarIndex];
                                                return Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: FutureBuilder<
                                                      List<UsersRow>>(
                                                    future: UsersTable()
                                                        .querySingleRow(
                                                      queryFn: (q) =>
                                                          q.eqOrNull(
                                                        'id',
                                                        containerVarItem.userId,
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
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .tertiary,
                                                              size: 50.0,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                      List<UsersRow>
                                                          userDemandUsersRowList =
                                                          snapshot.data!;

                                                      final userDemandUsersRow =
                                                          userDemandUsersRowList
                                                                  .isNotEmpty
                                                              ? userDemandUsersRowList
                                                                  .first
                                                              : null;

                                                      return Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            children: [
                                                              ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            50.0),
                                                                child: Image
                                                                    .network(
                                                                  'https://jfbfymiyqlyciapfloug.supabase.co/storage/v1/object/public/images/group_photo/360_F_65772719_A1UV5kLi5nCEWI0BNLLiFaBPEkUbv5Fv.jpg',
                                                                  width: 50.0,
                                                                  height: 50.0,
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
                                                              if (userDemandUsersRow
                                                                          ?.profilImageUrl !=
                                                                      null &&
                                                                  userDemandUsersRow
                                                                          ?.profilImageUrl !=
                                                                      '')
                                                                ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              50.0),
                                                                  child: Image
                                                                      .network(
                                                                    userDemandUsersRow!
                                                                        .profilImageUrl!,
                                                                    width: 50.0,
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
                                                                    userDemandUsersRow
                                                                        ?.userName,
                                                                    'user name',
                                                                  ),
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyLarge
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .poppins(
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .bodyLarge
                                                                              .fontStyle,
                                                                        ),
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyLarge
                                                                            .fontStyle,
                                                                      ),
                                                                ),
                                                                Text(
                                                                  valueOrDefault<
                                                                      String>(
                                                                    userDemandUsersRow
                                                                        ?.description,
                                                                    'user description',
                                                                  ),
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .poppins(
                                                                          fontWeight: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontStyle,
                                                                        ),
                                                                        letterSpacing:
                                                                            0.0,
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
                                                                  'GROUP_PAGE_PAGE_Icon_jam3voa9_ON_TAP');
                                                              logFirebaseEvent(
                                                                  'Icon_backend_call');
                                                              await ConversationDemandTable()
                                                                  .delete(
                                                                matchingRows:
                                                                    (rows) => rows
                                                                        .eqOrNull(
                                                                  'id',
                                                                  containerVarItem
                                                                      .id,
                                                                ),
                                                              );
                                                              logFirebaseEvent(
                                                                  'Icon_show_snack_bar');
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    'Demande supprimée',
                                                                    style:
                                                                        TextStyle(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                    ),
                                                                  ),
                                                                  duration: Duration(
                                                                      milliseconds:
                                                                          4000),
                                                                  backgroundColor:
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondary,
                                                                ),
                                                              );
                                                              logFirebaseEvent(
                                                                  'Icon_backend_call');
                                                              _model.apiResultgsl =
                                                                  await SupabaseGroup
                                                                      .conversationAcceptedCall
                                                                      .call(
                                                                demandId: _model
                                                                    .acceptedGroupedDemand
                                                                    ?.firstOrNull
                                                                    ?.id,
                                                                responderUserId:
                                                                    valueOrDefault(
                                                                        currentUserDocument
                                                                            ?.id,
                                                                        0),
                                                                conversationId:
                                                                    columnConversationGroupRow
                                                                        ?.conversationId,
                                                                grouped: true,
                                                                accepted: false,
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
                                                                  .delete_rounded,
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .secondary,
                                                              size: 24.0,
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
                                                                  'GROUP_PAGE_PAGE_Icon_2rx6j8w1_ON_TAP');
                                                              logFirebaseEvent(
                                                                  'Icon_backend_call');
                                                              await ConversationParticipantTable()
                                                                  .insert({
                                                                'conversation_id':
                                                                    widget!
                                                                        .conversation
                                                                        ?.id,
                                                                'user_id':
                                                                    userDemandUsersRow
                                                                        ?.id,
                                                              });
                                                              logFirebaseEvent(
                                                                  'Icon_backend_call');
                                                              await ConversationDemandTable()
                                                                  .delete(
                                                                matchingRows:
                                                                    (rows) => rows
                                                                        .eqOrNull(
                                                                  'id',
                                                                  containerVarItem
                                                                      .id,
                                                                ),
                                                              );
                                                              logFirebaseEvent(
                                                                  'Icon_refresh_database_request');
                                                              safeSetState(() =>
                                                                  _model.requestCompleter2 =
                                                                      null);
                                                              await _model
                                                                  .waitForRequestCompleted2();
                                                              logFirebaseEvent(
                                                                  'Icon_refresh_database_request');
                                                              safeSetState(() =>
                                                                  _model.requestCompleter3 =
                                                                      null);
                                                              await _model
                                                                  .waitForRequestCompleted3();
                                                              logFirebaseEvent(
                                                                  'Icon_show_snack_bar');
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    '${userDemandUsersRow?.userName} a été ajouté à votre groupe',
                                                                    style:
                                                                        TextStyle(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                    ),
                                                                  ),
                                                                  duration: Duration(
                                                                      milliseconds:
                                                                          4000),
                                                                  backgroundColor:
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondary,
                                                                ),
                                                              );
                                                              logFirebaseEvent(
                                                                  'Icon_backend_call');
                                                              _model.acceptedDemandNotification =
                                                                  await SupabaseGroup
                                                                      .conversationAcceptedCall
                                                                      .call(
                                                                demandId: _model
                                                                    .acceptedGroupedDemand
                                                                    ?.firstOrNull
                                                                    ?.id,
                                                                responderUserId:
                                                                    valueOrDefault(
                                                                        currentUserDocument
                                                                            ?.id,
                                                                        0),
                                                                conversationId:
                                                                    columnConversationGroupRow
                                                                        ?.conversationId,
                                                                grouped: true,
                                                                accepted: true,
                                                                userId: valueOrDefault(
                                                                    currentUserDocument
                                                                        ?.id,
                                                                    0),
                                                              );

                                                              safeSetState(
                                                                  () {});
                                                            },
                                                            child: Icon(
                                                              Icons.add_circle,
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .primary,
                                                              size: 24.0,
                                                            ),
                                                          ),
                                                        ]
                                                            .divide(SizedBox(
                                                                width: 10.0))
                                                            .around(SizedBox(
                                                                width: 10.0)),
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
                          Text(
                            FFLocalizations.of(context).getText(
                              'ix51tm8n' /* Participant */,
                            ),
                            style: FlutterFlowTheme.of(context)
                                .titleLarge
                                .override(
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
                          Container(
                            decoration: BoxDecoration(),
                            child:
                                StreamBuilder<List<ConversationParticipantRow>>(
                              stream: _model.containerSupabaseStream ??=
                                  SupaFlow.client
                                      .from("conversation_participant")
                                      .stream(primaryKey: ['id'])
                                      .eqOrNull(
                                        'conversation_id',
                                        widget!.conversation?.id,
                                      )
                                      .map((list) => list
                                          .map((item) =>
                                              ConversationParticipantRow(item))
                                          .toList()),
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
                                List<ConversationParticipantRow>
                                    containerConversationParticipantRowList =
                                    snapshot.data!;

                                return Container(
                                  decoration: BoxDecoration(),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      if (!(containerConversationParticipantRowList
                                          .where((e) =>
                                              e.userId ==
                                              valueOrDefault(
                                                  currentUserDocument?.id, 0))
                                          .toList()
                                          .isNotEmpty))
                                        AuthUserStreamWidget(
                                          builder: (context) => Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(10.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Text(
                                                    '${containerConversationParticipantRowList.length.toString()} participants',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .poppins(
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
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (containerConversationParticipantRowList
                                          .where((e) =>
                                              e.userId ==
                                              valueOrDefault(
                                                  currentUserDocument?.id, 0))
                                          .toList()
                                          .isNotEmpty)
                                        AuthUserStreamWidget(
                                          builder: (context) => Builder(
                                            builder: (context) {
                                              final containerVar =
                                                  containerConversationParticipantRowList
                                                      .toList();

                                              return ListView.builder(
                                                padding: EdgeInsets.zero,
                                                primary: false,
                                                shrinkWrap: true,
                                                scrollDirection: Axis.vertical,
                                                itemCount: containerVar.length,
                                                itemBuilder: (context,
                                                    containerVarIndex) {
                                                  final containerVarItem =
                                                      containerVar[
                                                          containerVarIndex];
                                                  return Padding(
                                                    padding:
                                                        EdgeInsets.all(10.0),
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
                                                        List<UsersRow>
                                                            containerUsersRowList =
                                                            snapshot.data!;

                                                        final containerUsersRow =
                                                            containerUsersRowList
                                                                    .isNotEmpty
                                                                ? containerUsersRowList
                                                                    .first
                                                                : null;

                                                        return Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .secondaryBackground,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    5.0),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              children: [
                                                                Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    if (containerUsersRow?.profilImageUrl ==
                                                                            null ||
                                                                        containerUsersRow?.profilImageUrl ==
                                                                            '')
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
                                                                              'GROUP_PAGE_PAGE_Image_9ktq97x0_ON_TAP');
                                                                          logFirebaseEvent(
                                                                              'Image_navigate_to');

                                                                          context
                                                                              .pushNamed(
                                                                            UserprofileWidget.routeName,
                                                                            queryParameters:
                                                                                {
                                                                              'users': serializeParam(
                                                                                containerUsersRow,
                                                                                ParamType.SupabaseRow,
                                                                              ),
                                                                            }.withoutNulls,
                                                                          );
                                                                        },
                                                                        child:
                                                                            ClipRRect(
                                                                          borderRadius:
                                                                              BorderRadius.circular(50.0),
                                                                          child:
                                                                              Image.network(
                                                                            'https://jfbfymiyqlyciapfloug.supabase.co/storage/v1/object/public/images/group_photo/360_F_65772719_A1UV5kLi5nCEWI0BNLLiFaBPEkUbv5Fv.jpg',
                                                                            width:
                                                                                50.0,
                                                                            height:
                                                                                50.0,
                                                                            fit:
                                                                                BoxFit.cover,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    if (containerUsersRow
                                                                            ?.profilImageUrl ==
                                                                        '')
                                                                      ClipRRect(
                                                                        borderRadius:
                                                                            BorderRadius.circular(50.0),
                                                                        child: Image
                                                                            .network(
                                                                          containerUsersRow!
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
                                                                Expanded(
                                                                  child: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Text(
                                                                        valueOrDefault<
                                                                            String>(
                                                                          containerUsersRow
                                                                              ?.userName,
                                                                          'user name',
                                                                        ),
                                                                        style: FlutterFlowTheme.of(context)
                                                                            .labelLarge
                                                                            .override(
                                                                              font: GoogleFonts.poppins(
                                                                                fontWeight: FlutterFlowTheme.of(context).labelLarge.fontWeight,
                                                                                fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                                                                              ),
                                                                              letterSpacing: 0.0,
                                                                              fontWeight: FlutterFlowTheme.of(context).labelLarge.fontWeight,
                                                                              fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                                                                            ),
                                                                      ),
                                                                      if (containerVarItem
                                                                              .role ==
                                                                          'admin')
                                                                        Text(
                                                                          FFLocalizations.of(context)
                                                                              .getText(
                                                                            'bzr8z9q5' /* Admin */,
                                                                          ),
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .labelSmall
                                                                              .override(
                                                                                font: GoogleFonts.poppins(
                                                                                  fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                  fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                ),
                                                                                letterSpacing: 0.0,
                                                                                fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                              ),
                                                                        ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                if ((widget!.conversation
                                                                            ?.adminUserId ==
                                                                        valueOrDefault(
                                                                            currentUserDocument
                                                                                ?.id,
                                                                            0)) &&
                                                                    (containerVarItem
                                                                            .userId !=
                                                                        valueOrDefault(
                                                                            currentUserDocument?.id,
                                                                            0)))
                                                                  InkWell(
                                                                    splashColor:
                                                                        Colors
                                                                            .transparent,
                                                                    focusColor:
                                                                        Colors
                                                                            .transparent,
                                                                    hoverColor:
                                                                        Colors
                                                                            .transparent,
                                                                    highlightColor:
                                                                        Colors
                                                                            .transparent,
                                                                    onTap:
                                                                        () async {
                                                                      logFirebaseEvent(
                                                                          'GROUP_PAGE_PAGE_Icon_4ezt2v3j_ON_TAP');
                                                                      logFirebaseEvent(
                                                                          'Icon_backend_call');
                                                                      await ConversationParticipantTable()
                                                                          .delete(
                                                                        matchingRows: (rows) => rows
                                                                            .eqOrNull(
                                                                              'conversation_id',
                                                                              widget!.conversation?.id,
                                                                            )
                                                                            .eqOrNull(
                                                                              'user_id',
                                                                              containerUsersRow?.id,
                                                                            ),
                                                                      );
                                                                      logFirebaseEvent(
                                                                          'Icon_show_snack_bar');
                                                                      ScaffoldMessenger.of(
                                                                              context)
                                                                          .showSnackBar(
                                                                        SnackBar(
                                                                          content:
                                                                              Text(
                                                                            '${containerUsersRow?.userName} a été supprimé du groupe',
                                                                            style:
                                                                                TextStyle(
                                                                              color: FlutterFlowTheme.of(context).primaryText,
                                                                            ),
                                                                          ),
                                                                          duration:
                                                                              Duration(milliseconds: 4000),
                                                                          backgroundColor:
                                                                              FlutterFlowTheme.of(context).secondary,
                                                                        ),
                                                                      );
                                                                    },
                                                                    child: Icon(
                                                                      Icons
                                                                          .delete_sharp,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondary,
                                                                      size:
                                                                          24.0,
                                                                    ),
                                                                  ),
                                                                if (containerUsersRow
                                                                        ?.id !=
                                                                    valueOrDefault(
                                                                        currentUserDocument
                                                                            ?.id,
                                                                        0))
                                                                  wrapWithModel(
                                                                    model: _model
                                                                        .conversationMessageModels
                                                                        .getModel(
                                                                      containerUsersRow!
                                                                          .id
                                                                          .toString(),
                                                                      containerVarIndex,
                                                                    ),
                                                                    updateCallback: () =>
                                                                        safeSetState(
                                                                            () {}),
                                                                    child:
                                                                        ConversationMessageWidget(
                                                                      key: Key(
                                                                        'Keyd0s_${containerUsersRow!.id.toString()}',
                                                                      ),
                                                                      userID:
                                                                          containerUsersRow!
                                                                              .id,
                                                                    ),
                                                                  ),
                                                              ].divide(SizedBox(
                                                                  width: 5.0)),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      if (containerConversationParticipantRowList
                                          .where((e) =>
                                              e.userId ==
                                              valueOrDefault(
                                                  currentUserDocument?.id, 0))
                                          .toList()
                                          .isNotEmpty)
                                        AuthUserStreamWidget(
                                          builder: (context) => FFButtonWidget(
                                            onPressed: () async {
                                              logFirebaseEvent(
                                                  'GROUP_QUITTER_LE_GROUPE_BTN_ON_TAP');
                                              logFirebaseEvent(
                                                  'Button_backend_call');
                                              await ConversationParticipantTable()
                                                  .delete(
                                                matchingRows: (rows) => rows
                                                    .eqOrNull(
                                                      'user_id',
                                                      valueOrDefault(
                                                          currentUserDocument
                                                              ?.id,
                                                          0),
                                                    )
                                                    .eqOrNull(
                                                      'conversation_id',
                                                      widget!.conversation?.id,
                                                    ),
                                              );
                                              logFirebaseEvent(
                                                  'Button_navigate_to');

                                              context.pushNamed(
                                                  CommunityWidget.routeName);
                                            },
                                            text: FFLocalizations.of(context)
                                                .getText(
                                              'p4mng5ff' /* Quitter le groupe */,
                                            ),
                                            options: FFButtonOptions(
                                              height: 40.0,
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      16.0, 0.0, 16.0, 0.0),
                                              iconPadding: EdgeInsetsDirectional
                                                  .fromSTEB(0.0, 0.0, 0.0, 0.0),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondary,
                                              textStyle:
                                                  FlutterFlowTheme.of(context)
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
                                        ),
                                    ].divide(SizedBox(height: 20.0)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ].divide(SizedBox(height: 20.0)),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20.0, 30.0, 20.0, 0.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    FlutterFlowIconButton(
                      borderRadius: 100.0,
                      buttonSize: 40.0,
                      fillColor: FlutterFlowTheme.of(context).primary,
                      icon: Icon(
                        Icons.arrow_back,
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        size: 24.0,
                      ),
                      onPressed: () async {
                        logFirebaseEvent(
                            'GROUP_PAGE_PAGE_arrow_back_ICN_ON_TAP');
                        logFirebaseEvent('IconButton_navigate_back');
                        context.safePop();
                      },
                    ),
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [],
                      ),
                    ),
                    if (valueOrDefault(currentUserDocument?.id, 0) ==
                        widget!.conversation?.adminUserId)
                      AuthUserStreamWidget(
                        builder: (context) => InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            logFirebaseEvent(
                                'GROUP_PAGE_PAGE_Icon_s7ww578r_ON_TAP');
                            logFirebaseEvent('Icon_bottom_sheet');
                            await showModalBottomSheet(
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
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
                                      padding: MediaQuery.viewInsetsOf(context),
                                      child: Container(
                                        height: 750.0,
                                        child: EditGroupWidget(
                                          conv: widget!.conversation?.id,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ).then((value) => safeSetState(() {}));
                          },
                          child: Icon(
                            Icons.edit,
                            color: FlutterFlowTheme.of(context).primary,
                            size: 24.0,
                          ),
                        ),
                      ),
                    if (valueOrDefault(currentUserDocument?.id, 0) ==
                        widget!.conversation?.adminUserId)
                      AuthUserStreamWidget(
                        builder: (context) => InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            logFirebaseEvent(
                                'GROUP_PAGE_PAGE_Icon_h0htdtm3_ON_TAP');
                            logFirebaseEvent('Icon_bottom_sheet');
                            await showModalBottomSheet(
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
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
                                      padding: MediaQuery.viewInsetsOf(context),
                                      child: Container(
                                        height: 300.0,
                                        child: DeleteGroupWidget(
                                          group: widget!.conversation!,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ).then((value) => safeSetState(() {}));
                          },
                          child: Icon(
                            Icons.delete_rounded,
                            color: FlutterFlowTheme.of(context).secondary,
                            size: 24.0,
                          ),
                        ),
                      ),
                  ].divide(SizedBox(width: 10.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
