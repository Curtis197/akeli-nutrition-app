import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/community/chat_user/chat_user_widget.dart';
import '/community/group_creation/group_creation_widget.dart';
import '/flutter_flow/flutter_flow_radio_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/backend/schema/structs/index.dart';
import '/index.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'community_model.dart';
export 'community_model.dart';

class CommunityWidget extends StatefulWidget {
  const CommunityWidget({super.key});

  static String routeName = 'Community';
  static String routePath = '/community';

  @override
  State<CommunityWidget> createState() => _CommunityWidgetState();
}

class _CommunityWidgetState extends State<CommunityWidget>
    with TickerProviderStateMixin {
  late CommunityModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CommunityModel());

    logFirebaseEvent('screen_view', parameters: {'screen_name': 'Community'});
    _model.tabBarController = TabController(
      vsync: this,
      length: 2,
      initialIndex: 0,
    )..addListener(() => safeSetState(() {}));

    _model.convSearchTextController ??= TextEditingController();
    _model.convSearchFocusNode ??= FocusNode();

    _model.groupSearchTextController ??= TextEditingController();
    _model.groupSearchFocusNode ??= FocusNode();

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
        List<UsersRow> communityUsersRowList = snapshot.data!;

        final communityUsersRow = communityUsersRowList.isNotEmpty
            ? communityUsersRowList.first
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
              backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
              automaticallyImplyLeading: false,
              title: Text(
                FFLocalizations.of(context).getText(
                  '0znnfdeb' /* Discussion */,
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
                      color: FlutterFlowTheme.of(context).primary,
                      fontSize: 28.0,
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
              child: Container(
                decoration: BoxDecoration(),
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (communityUsersRow?.paidPlan ?? true)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(),
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment(0.0, 0),
                                  child: TabBar(
                                    labelColor: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    unselectedLabelColor:
                                        FlutterFlowTheme.of(context)
                                            .secondaryText,
                                    labelStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .override(
                                          font: GoogleFonts.poppins(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .titleMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleMedium
                                                  .fontStyle,
                                        ),
                                    unselectedLabelStyle:
                                        FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .override(
                                              font: GoogleFonts.poppins(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .fontStyle,
                                              ),
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                    indicatorColor:
                                        FlutterFlowTheme.of(context).primary,
                                    tabs: [
                                      Tab(
                                        text:
                                            FFLocalizations.of(context).getText(
                                          'uyyah338' /* Conversation */,
                                        ),
                                      ),
                                      Tab(
                                        text:
                                            FFLocalizations.of(context).getText(
                                          'q06dyd9i' /* Groupe */,
                                        ),
                                      ),
                                    ],
                                    controller: _model.tabBarController,
                                    onTap: (i) async {
                                      [
                                        () async {
                                          logFirebaseEvent(
                                              'COMMUNITY_PAGE_Tab_bmlsqw0b_ON_TAP');
                                          logFirebaseEvent(
                                              'Tab_update_page_state');
                                          _model.inSearch = false;
                                          safeSetState(() {});
                                        },
                                        () async {
                                          logFirebaseEvent(
                                              'COMMUNITY_PAGE_Tab_v4gbbgi8_ON_TAP');
                                          logFirebaseEvent(
                                              'Tab_update_page_state');
                                          _model.inSearch = false;
                                          safeSetState(() {});
                                        }
                                      ][i]();
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
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      30.0, 10.0, 30.0, 0.0),
                                              child: Container(
                                                width: double.infinity,
                                                child: TextFormField(
                                                  controller: _model
                                                      .convSearchTextController,
                                                  focusNode: _model
                                                      .convSearchFocusNode,
                                                  onFieldSubmitted: (_) async {
                                                    logFirebaseEvent(
                                                        'COMMUNITY_convSearch_ON_TEXTFIELD_SUBMIT');
                                                    logFirebaseEvent(
                                                        'convSearch_backend_call');
                                                    _model.privateConversation =
                                                        await SupabaseGroup
                                                            .searchAPrivateConversationCall
                                                            .call(
                                                      name: _model
                                                          .convSearchTextController
                                                          .text,
                                                      userId:
                                                          communityUsersRow?.id,
                                                    );

                                                    logFirebaseEvent(
                                                        'convSearch_update_page_state');
                                                    _model.inSearch = true;
                                                    safeSetState(() {});

                                                    safeSetState(() {});
                                                  },
                                                  autofocus: false,
                                                  obscureText: false,
                                                  decoration: InputDecoration(
                                                    isDense: true,
                                                    labelStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
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
                                                        FFLocalizations.of(
                                                                context)
                                                            .getText(
                                                      'lvxyi5t9' /* Chercher une conversation */,
                                                    ),
                                                    hintStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
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
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            Color(0x00000000),
                                                        width: 1.0,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50.0),
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            Color(0x00000000),
                                                        width: 1.0,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50.0),
                                                    ),
                                                    errorBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .error,
                                                        width: 1.0,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50.0),
                                                    ),
                                                    focusedErrorBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .error,
                                                        width: 1.0,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50.0),
                                                    ),
                                                    filled: true,
                                                    fillColor: FlutterFlowTheme
                                                            .of(context)
                                                        .secondaryBackground,
                                                    suffixIcon: Icon(
                                                      Icons.search_rounded,
                                                    ),
                                                  ),
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        font:
                                                            GoogleFonts.poppins(
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
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .primaryText,
                                                  validator: _model
                                                      .convSearchTextControllerValidator
                                                      .asValidator(context),
                                                ),
                                              ),
                                            ),
                                            FutureBuilder<
                                                List<ConversationDemandRow>>(
                                              future: (_model
                                                          .requestCompleter ??=
                                                      Completer<
                                                          List<
                                                              ConversationDemandRow>>()
                                                        ..complete(
                                                            ConversationDemandTable()
                                                                .queryRows(
                                                          queryFn: (q) =>
                                                              q.eqOrNull(
                                                            'destined_user',
                                                            communityUsersRow
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
                                                      child:
                                                          SpinKitDoubleBounce(
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
                                                    conversationDemandConversationDemandRowList =
                                                    snapshot.data!;

                                                return Container(
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryBackground,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                  ),
                                                  child: Visibility(
                                                    visible:
                                                        conversationDemandConversationDemandRowList
                                                            .isNotEmpty,
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(12.0),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          Text(
                                                            FFLocalizations.of(
                                                                    context)
                                                                .getText(
                                                              'g0fg8k1m' /* Demandes */,
                                                            ),
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .titleLarge
                                                                .override(
                                                                  font: GoogleFonts
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
                                                          ),
                                                          Builder(
                                                            builder: (context) {
                                                              final containerVar =
                                                                  conversationDemandConversationDemandRowList
                                                                      .toList();

                                                              return ListView
                                                                  .builder(
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                primary: false,
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
                                                                  return Padding(
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                            8.0),
                                                                    child: FutureBuilder<
                                                                        List<
                                                                            UsersRow>>(
                                                                      future: UsersTable()
                                                                          .querySingleRow(
                                                                        queryFn:
                                                                            (q) =>
                                                                                q.eqOrNull(
                                                                          'id',
                                                                          containerVarItem
                                                                              .userId,
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
                                                                        List<UsersRow>
                                                                            rowUsersRowList =
                                                                            snapshot.data!;

                                                                        final rowUsersRow = rowUsersRowList.isNotEmpty
                                                                            ? rowUsersRowList.first
                                                                            : null;

                                                                        return Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          children:
                                                                              [
                                                                            Row(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              children: [
                                                                                if (communityUsersRow?.profilImageUrl != null && communityUsersRow?.profilImageUrl != '')
                                                                                  ClipRRect(
                                                                                    borderRadius: BorderRadius.circular(50.0),
                                                                                    child: Image.network(
                                                                                      communityUsersRow!.profilImageUrl!,
                                                                                      width: 50.0,
                                                                                      height: 50.0,
                                                                                      fit: BoxFit.cover,
                                                                                    ),
                                                                                  ),
                                                                              ],
                                                                            ),
                                                                            Row(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              children: [
                                                                                if (communityUsersRow?.profilImageUrl == null || communityUsersRow?.profilImageUrl == '')
                                                                                  ClipRRect(
                                                                                    borderRadius: BorderRadius.circular(50.0),
                                                                                    child: Image.network(
                                                                                      'https://jfbfymiyqlyciapfloug.supabase.co/storage/v1/object/public/images/group_photo/360_F_65772719_A1UV5kLi5nCEWI0BNLLiFaBPEkUbv5Fv.jpg',
                                                                                      width: 50.0,
                                                                                      height: 50.0,
                                                                                      fit: BoxFit.cover,
                                                                                    ),
                                                                                  ),
                                                                              ],
                                                                            ),
                                                                            Expanded(
                                                                              child: Padding(
                                                                                padding: EdgeInsetsDirectional.fromSTEB(10.0, 0.0, 10.0, 0.0),
                                                                                child: Column(
                                                                                  mainAxisSize: MainAxisSize.max,
                                                                                  children: [
                                                                                    Text(
                                                                                      valueOrDefault<String>(
                                                                                        rowUsersRow?.userName,
                                                                                        'user name',
                                                                                      ),
                                                                                      style: FlutterFlowTheme.of(context).bodyLarge.override(
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
                                                                                      valueOrDefault<String>(
                                                                                        rowUsersRow?.description,
                                                                                        'user description',
                                                                                      ),
                                                                                      style: FlutterFlowTheme.of(context).bodySmall.override(
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
                                                                            ),
                                                                            InkWell(
                                                                              splashColor: Colors.transparent,
                                                                              focusColor: Colors.transparent,
                                                                              hoverColor: Colors.transparent,
                                                                              highlightColor: Colors.transparent,
                                                                              onTap: () async {
                                                                                logFirebaseEvent('COMMUNITY_PAGE_Icon_cwuixprd_ON_TAP');
                                                                                logFirebaseEvent('Icon_backend_call');
                                                                                await ConversationDemandTable().delete(
                                                                                  matchingRows: (rows) => rows.eqOrNull(
                                                                                    'id',
                                                                                    containerVarItem.id,
                                                                                  ),
                                                                                );
                                                                                logFirebaseEvent('Icon_refresh_database_request');
                                                                                safeSetState(() => _model.requestCompleter = null);
                                                                                await _model.waitForRequestCompleted();
                                                                              },
                                                                              child: Icon(
                                                                                Icons.delete,
                                                                                color: FlutterFlowTheme.of(context).secondary,
                                                                                size: 24.0,
                                                                              ),
                                                                            ),
                                                                            InkWell(
                                                                              splashColor: Colors.transparent,
                                                                              focusColor: Colors.transparent,
                                                                              hoverColor: Colors.transparent,
                                                                              highlightColor: Colors.transparent,
                                                                              onTap: () async {
                                                                                logFirebaseEvent('COMMUNITY_PAGE_Icon_ugsm7fy7_ON_TAP');
                                                                                logFirebaseEvent('Icon_backend_call');
                                                                                _model.newConversation = await SupabaseGroup.findOrCreateTheConversationCall.call(
                                                                                  destinedUserId: containerVarItem.destinedUser,
                                                                                  userId: containerVarItem.userId,
                                                                                );

                                                                                if ((_model.newConversation?.succeeded ?? true)) {
                                                                                  logFirebaseEvent('Icon_backend_call');
                                                                                  await ConversationDemandTable().delete(
                                                                                    matchingRows: (rows) => rows.eqOrNull(
                                                                                      'id',
                                                                                      containerVarItem.id,
                                                                                    ),
                                                                                  );
                                                                                  logFirebaseEvent('Icon_backend_call');
                                                                                  _model.queriedChat = await ChatConversationTable().queryRows(
                                                                                    queryFn: (q) => q.eqOrNull(
                                                                                      'id',
                                                                                      SupabaseGroup.findOrCreateTheConversationCall.conversationId(
                                                                                        (_model.newConversation?.jsonBody ?? ''),
                                                                                      ),
                                                                                    ),
                                                                                  );
                                                                                  logFirebaseEvent('Icon_navigate_to');

                                                                                  context.pushNamed(
                                                                                    ChatPageWidget.routeName,
                                                                                    queryParameters: {
                                                                                      'conversation': serializeParam(
                                                                                        _model.queriedChat?.firstOrNull,
                                                                                        ParamType.SupabaseRow,
                                                                                      ),
                                                                                      'destinedUserId': serializeParam(
                                                                                        rowUsersRow?.id,
                                                                                        ParamType.int,
                                                                                      ),
                                                                                    }.withoutNulls,
                                                                                  );
                                                                                }
                                                                                logFirebaseEvent('Icon_refresh_database_request');
                                                                                safeSetState(() => _model.requestCompleter = null);
                                                                                await _model.waitForRequestCompleted();

                                                                                safeSetState(() {});
                                                                              },
                                                                              child: Icon(
                                                                                Icons.add_circle_outlined,
                                                                                color: FlutterFlowTheme.of(context).tertiary,
                                                                                size: 24.0,
                                                                              ),
                                                                            ),
                                                                          ].divide(SizedBox(width: 10.0)).around(SizedBox(width: 10.0)),
                                                                        );
                                                                      },
                                                                    ),
                                                                  );
                                                                },
                                                              );
                                                            },
                                                          ),
                                                        ].divide(SizedBox(
                                                            height: 15.0)),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            if (_model.inSearch == false)
                                              StreamBuilder<
                                                  List<
                                                      ConversationParticipantRow>>(
                                                stream: _model
                                                        .listViewSupabaseStream ??=
                                                    SupaFlow.client
                                                        .from(
                                                            "conversation_participant")
                                                        .stream(
                                                            primaryKey: ['id'])
                                                        .eqOrNull(
                                                          'user_id',
                                                          communityUsersRow?.id,
                                                        )
                                                        .map((list) => list
                                                            .map((item) =>
                                                                ConversationParticipantRow(
                                                                    item))
                                                            .toList()),
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
                                                  List<ConversationParticipantRow>
                                                      listViewConversationParticipantRowList =
                                                      snapshot.data!;

                                                  return ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    primary: false,
                                                    shrinkWrap: true,
                                                    scrollDirection:
                                                        Axis.vertical,
                                                    itemCount:
                                                        listViewConversationParticipantRowList
                                                            .length,
                                                    itemBuilder: (context,
                                                        listViewIndex) {
                                                      final listViewConversationParticipantRow =
                                                          listViewConversationParticipantRowList[
                                                              listViewIndex];
                                                      return FutureBuilder<
                                                          List<
                                                              ChatConversationRow>>(
                                                        future:
                                                            ChatConversationTable()
                                                                .querySingleRow(
                                                          queryFn: (q) => q
                                                              .eqOrNull(
                                                                'id',
                                                                listViewConversationParticipantRow
                                                                    .conversationId,
                                                              )
                                                              .eqOrNull(
                                                                'grouped',
                                                                false,
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
                                                          List<ChatConversationRow>
                                                              chatUserChatConversationRowList =
                                                              snapshot.data!;

                                                          // Return an empty Container when the item does not exist.
                                                          if (snapshot
                                                              .data!.isEmpty) {
                                                            return Container();
                                                          }
                                                          final chatUserChatConversationRow =
                                                              chatUserChatConversationRowList
                                                                      .isNotEmpty
                                                                  ? chatUserChatConversationRowList
                                                                      .first
                                                                  : null;

                                                          return wrapWithModel(
                                                            model: _model
                                                                .chatUserModels1
                                                                .getModel(
                                                              chatUserChatConversationRow!
                                                                  .id
                                                                  .toString(),
                                                              listViewIndex,
                                                            ),
                                                            updateCallback: () =>
                                                                safeSetState(
                                                                    () {}),
                                                            child:
                                                                ChatUserWidget(
                                                              key: Key(
                                                                'Key71q_${chatUserChatConversationRow!.id.toString()}',
                                                              ),
                                                              chatConv:
                                                                  chatUserChatConversationRow!,
                                                              currentUser:
                                                                  communityUsersRow!
                                                                      .id,
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            if (_model.inSearch == true)
                                              Builder(
                                                builder: (context) {
                                                  final conversation = SupabaseGroup
                                                          .searchAPrivateConversationCall
                                                          .conversation(
                                                            (_model.privateConversation
                                                                    ?.jsonBody ??
                                                                ''),
                                                          )
                                                          ?.toList() ??
                                                      [];

                                                  return ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    primary: false,
                                                    shrinkWrap: true,
                                                    scrollDirection:
                                                        Axis.vertical,
                                                    itemCount:
                                                        conversation.length,
                                                    itemBuilder: (context,
                                                        conversationIndex) {
                                                      final conversationItem =
                                                          conversation[
                                                              conversationIndex];
                                                      return FutureBuilder<
                                                          List<
                                                              ChatConversationRow>>(
                                                        future:
                                                            ChatConversationTable()
                                                                .querySingleRow(
                                                          queryFn: (q) =>
                                                              q.eqOrNull(
                                                            'id',
                                                            ConversationsStruct
                                                                    .maybeFromMap(
                                                                        conversationItem)
                                                                ?.conversationId,
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
                                                          List<ChatConversationRow>
                                                              chatUserChatConversationRowList =
                                                              snapshot.data!;

                                                          final chatUserChatConversationRow =
                                                              chatUserChatConversationRowList
                                                                      .isNotEmpty
                                                                  ? chatUserChatConversationRowList
                                                                      .first
                                                                  : null;

                                                          return wrapWithModel(
                                                            model: _model
                                                                .chatUserModels2
                                                                .getModel(
                                                              chatUserChatConversationRow!
                                                                  .id
                                                                  .toString(),
                                                              conversationIndex,
                                                            ),
                                                            updateCallback: () =>
                                                                safeSetState(
                                                                    () {}),
                                                            child:
                                                                ChatUserWidget(
                                                              key: Key(
                                                                'Keys4i_${chatUserChatConversationRow!.id.toString()}',
                                                              ),
                                                              chatConv:
                                                                  chatUserChatConversationRow!,
                                                              currentUser: ConversationsStruct
                                                                      .maybeFromMap(
                                                                          conversationItem)!
                                                                  .requesterId,
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                          ]
                                              .divide(SizedBox(height: 20.0))
                                              .addToStart(
                                                  SizedBox(height: 10.0)),
                                        ),
                                      ),
                                      SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 20.0, 0.0, 0.0),
                                              child: Container(
                                                width: 300.0,
                                                child: TextFormField(
                                                  controller: _model
                                                      .groupSearchTextController,
                                                  focusNode: _model
                                                      .groupSearchFocusNode,
                                                  onFieldSubmitted: (_) async {
                                                    logFirebaseEvent(
                                                        'COMMUNITY_groupSearch_ON_TEXTFIELD_SUBMI');
                                                    if (_model.participation) {
                                                      logFirebaseEvent(
                                                          'groupSearch_backend_call');
                                                      _model.filterGroupbyId =
                                                          await SupabaseGroup
                                                              .searchAGroupByNameCall
                                                              .call(
                                                        userId:
                                                            communityUsersRow
                                                                ?.id,
                                                        name: _model
                                                            .groupSearchTextController
                                                            .text,
                                                      );

                                                      logFirebaseEvent(
                                                          'groupSearch_update_page_state');
                                                      _model.inSearch = true;
                                                      safeSetState(() {});
                                                    } else {
                                                      logFirebaseEvent(
                                                          'groupSearch_backend_call');
                                                      _model.filterGroup =
                                                          await SupabaseGroup
                                                              .searchAGroupCall
                                                              .call(
                                                        name: _model
                                                            .groupSearchTextController
                                                            .text,
                                                      );

                                                      logFirebaseEvent(
                                                          'groupSearch_update_page_state');
                                                      _model.inSearch = true;
                                                      safeSetState(() {});
                                                    }

                                                    safeSetState(() {});
                                                  },
                                                  autofocus: false,
                                                  obscureText: false,
                                                  decoration: InputDecoration(
                                                    isDense: true,
                                                    labelStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
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
                                                        FFLocalizations.of(
                                                                context)
                                                            .getText(
                                                      '4pi1cf09' /* Chercher un groupe */,
                                                    ),
                                                    hintStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
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
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            Color(0x00000000),
                                                        width: 1.0,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50.0),
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            Color(0x00000000),
                                                        width: 1.0,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50.0),
                                                    ),
                                                    errorBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .error,
                                                        width: 1.0,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50.0),
                                                    ),
                                                    focusedErrorBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .error,
                                                        width: 1.0,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50.0),
                                                    ),
                                                    filled: true,
                                                    fillColor: FlutterFlowTheme
                                                            .of(context)
                                                        .secondaryBackground,
                                                    suffixIcon: Icon(
                                                      Icons.search_outlined,
                                                    ),
                                                  ),
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        font:
                                                            GoogleFonts.poppins(
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
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .primaryText,
                                                  validator: _model
                                                      .groupSearchTextControllerValidator
                                                      .asValidator(context),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 15.0, 0.0, 15.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  FlutterFlowRadioButton(
                                                    options: [
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'zjezrq4w' /* Tous */,
                                                      ),
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'ciajqmj0' /* Participant */,
                                                      )
                                                    ].toList(),
                                                    onChanged: (val) async {
                                                      safeSetState(() {});
                                                      logFirebaseEvent(
                                                          'COMMUNITY_RadioButton_2fm9iov8_ON_FORM_W');
                                                      logFirebaseEvent(
                                                          'RadioButton_update_page_state');
                                                      _model.participation =
                                                          _model.radioButtonValue ==
                                                                  'Participant'
                                                              ? true
                                                              : false;
                                                      _model.inSearch = false;
                                                      safeSetState(() {});
                                                    },
                                                    controller: _model
                                                            .radioButtonValueController ??=
                                                        FormFieldController<
                                                                String>(
                                                            FFLocalizations.of(
                                                                    context)
                                                                .getText(
                                                      '48gj8r1i' /* Tous */,
                                                    )),
                                                    optionHeight: 32.0,
                                                    textStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
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
                                                    selectedTextStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .override(
                                                              font: GoogleFonts
                                                                  .poppins(
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                              letterSpacing:
                                                                  0.0,
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
                                                    buttonPosition:
                                                        RadioButtonPosition
                                                            .left,
                                                    direction: Axis.horizontal,
                                                    radioButtonColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primary,
                                                    inactiveRadioButtonColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .secondaryText,
                                                    toggleable: false,
                                                    horizontalAlignment:
                                                        WrapAlignment.start,
                                                    verticalAlignment:
                                                        WrapCrossAlignment
                                                            .start,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 15.0, 0.0, 15.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  FFButtonWidget(
                                                    onPressed: () async {
                                                      logFirebaseEvent(
                                                          'COMMUNITY_PAGE_CRER_UN_GROUPE_BTN_ON_TAP');
                                                      logFirebaseEvent(
                                                          'Button_bottom_sheet');
                                                      await showModalBottomSheet(
                                                        isScrollControlled:
                                                            true,
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        enableDrag: false,
                                                        context: context,
                                                        builder: (context) {
                                                          return WebViewAware(
                                                            child:
                                                                GestureDetector(
                                                              onTap: () {
                                                                FocusScope.of(
                                                                        context)
                                                                    .unfocus();
                                                                FocusManager
                                                                    .instance
                                                                    .primaryFocus
                                                                    ?.unfocus();
                                                              },
                                                              child: Padding(
                                                                padding: MediaQuery
                                                                    .viewInsetsOf(
                                                                        context),
                                                                child:
                                                                    Container(
                                                                  height: 450.0,
                                                                  child:
                                                                      GroupCreationWidget(
                                                                    users:
                                                                        communityUsersRow,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ).then((value) =>
                                                          safeSetState(() {}));
                                                    },
                                                    text: FFLocalizations.of(
                                                            context)
                                                        .getText(
                                                      '7i518550' /* Créer un groupe */,
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
                                                ],
                                              ),
                                            ),
                                            if ((_model.participation ==
                                                    false) &&
                                                (_model.inSearch == false))
                                              FutureBuilder<
                                                  List<ChatConversationRow>>(
                                                future: ChatConversationTable()
                                                    .queryRows(
                                                  queryFn: (q) => q
                                                      .eqOrNull(
                                                        'grouped',
                                                        true,
                                                      )
                                                      .order(
                                                          'last_message_time'),
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
                                                  List<ChatConversationRow>
                                                      partFseachFChatConversationRowList =
                                                      snapshot.data!;

                                                  return ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    primary: false,
                                                    shrinkWrap: true,
                                                    scrollDirection:
                                                        Axis.vertical,
                                                    itemCount:
                                                        partFseachFChatConversationRowList
                                                            .length,
                                                    itemBuilder: (context,
                                                        partFseachFIndex) {
                                                      final partFseachFChatConversationRow =
                                                          partFseachFChatConversationRowList[
                                                              partFseachFIndex];
                                                      return Container(
                                                        decoration:
                                                            BoxDecoration(),
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  5.0),
                                                          child: Container(
                                                            width:
                                                                double.infinity,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .secondaryBackground,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10.0),
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(
                                                                          10.0),
                                                              child: FutureBuilder<
                                                                  List<
                                                                      ConversationGroupRow>>(
                                                                future: ConversationGroupTable()
                                                                    .querySingleRow(
                                                                  queryFn: (q) =>
                                                                      q.eqOrNull(
                                                                    'conversation_id',
                                                                    partFseachFChatConversationRow
                                                                        .id,
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
                                                                          color:
                                                                              FlutterFlowTheme.of(context).tertiary,
                                                                          size:
                                                                              50.0,
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }
                                                                  List<ConversationGroupRow>
                                                                      rowConversationGroupRowList =
                                                                      snapshot
                                                                          .data!;

                                                                  // Return an empty Container when the item does not exist.
                                                                  if (snapshot
                                                                      .data!
                                                                      .isEmpty) {
                                                                    return Container();
                                                                  }
                                                                  final rowConversationGroupRow = rowConversationGroupRowList
                                                                          .isNotEmpty
                                                                      ? rowConversationGroupRowList
                                                                          .first
                                                                      : null;

                                                                  return InkWell(
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
                                                                          'COMMUNITY_PAGE_Row_vmrconkb_ON_TAP');
                                                                      logFirebaseEvent(
                                                                          'Row_backend_call');
                                                                      _model.apiResultavh = await SupabaseGroup
                                                                          .checkIfAUserIsInAGroupCall
                                                                          .call(
                                                                        userId:
                                                                            communityUsersRow?.id,
                                                                        conversationId:
                                                                            rowConversationGroupRow?.conversationId,
                                                                      );

                                                                      if (SupabaseGroup
                                                                          .checkIfAUserIsInAGroupCall
                                                                          .result(
                                                                        (_model.apiResultavh?.jsonBody ??
                                                                            ''),
                                                                      )!) {
                                                                        logFirebaseEvent(
                                                                            'Row_navigate_to');

                                                                        context
                                                                            .pushNamed(
                                                                          ChatPageWidget
                                                                              .routeName,
                                                                          queryParameters:
                                                                              {
                                                                            'conversation':
                                                                                serializeParam(
                                                                              partFseachFChatConversationRow,
                                                                              ParamType.SupabaseRow,
                                                                            ),
                                                                          }.withoutNulls,
                                                                        );
                                                                      } else {
                                                                        logFirebaseEvent(
                                                                            'Row_navigate_to');

                                                                        context
                                                                            .pushNamed(
                                                                          GroupPageWidget
                                                                              .routeName,
                                                                          queryParameters:
                                                                              {
                                                                            'conversation':
                                                                                serializeParam(
                                                                              partFseachFChatConversationRow,
                                                                              ParamType.SupabaseRow,
                                                                            ),
                                                                          }.withoutNulls,
                                                                        );
                                                                      }

                                                                      safeSetState(
                                                                          () {});
                                                                    },
                                                                    child: Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children:
                                                                          [
                                                                        if (rowConversationGroupRow?.imageUrl !=
                                                                                null &&
                                                                            rowConversationGroupRow?.imageUrl !=
                                                                                '')
                                                                          ClipRRect(
                                                                            borderRadius:
                                                                                BorderRadius.circular(50.0),
                                                                            child:
                                                                                Image.network(
                                                                              rowConversationGroupRow!.imageUrl!,
                                                                              width: 50.0,
                                                                              height: 50.0,
                                                                              fit: BoxFit.cover,
                                                                            ),
                                                                          ),
                                                                        if (rowConversationGroupRow?.imageUrl ==
                                                                                null ||
                                                                            rowConversationGroupRow?.imageUrl ==
                                                                                '')
                                                                          ClipRRect(
                                                                            borderRadius:
                                                                                BorderRadius.circular(50.0),
                                                                            child:
                                                                                Image.network(
                                                                              'https://jfbfymiyqlyciapfloug.supabase.co/storage/v1/object/public/images/group_photo/jive-sgroup-default-portrait-large.png',
                                                                              width: 50.0,
                                                                              height: 50.0,
                                                                              fit: BoxFit.cover,
                                                                            ),
                                                                          ),
                                                                        Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Text(
                                                                              valueOrDefault<String>(
                                                                                rowConversationGroupRow?.name,
                                                                                'group name',
                                                                              ),
                                                                              style: FlutterFlowTheme.of(context).labelLarge.override(
                                                                                    font: GoogleFonts.poppins(
                                                                                      fontWeight: FlutterFlowTheme.of(context).labelLarge.fontWeight,
                                                                                      fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                                                                                    ),
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FlutterFlowTheme.of(context).labelLarge.fontWeight,
                                                                                    fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                                                                                  ),
                                                                            ),
                                                                            Container(
                                                                              width: 200.0,
                                                                              decoration: BoxDecoration(),
                                                                              child: Text(
                                                                                valueOrDefault<String>(
                                                                                  rowConversationGroupRow?.description,
                                                                                  'group description',
                                                                                ),
                                                                                style: FlutterFlowTheme.of(context).labelSmall.override(
                                                                                      font: GoogleFonts.poppins(
                                                                                        fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                        fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                      ),
                                                                                      letterSpacing: 0.0,
                                                                                      fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                      fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                    ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            InkWell(
                                                                              splashColor: Colors.transparent,
                                                                              focusColor: Colors.transparent,
                                                                              hoverColor: Colors.transparent,
                                                                              highlightColor: Colors.transparent,
                                                                              onTap: () async {
                                                                                logFirebaseEvent('COMMUNITY_PAGE_Icon_t2un4tca_ON_TAP');
                                                                                logFirebaseEvent('Icon_navigate_to');

                                                                                context.pushNamed(
                                                                                  ChatPageWidget.routeName,
                                                                                  queryParameters: {
                                                                                    'conversation': serializeParam(
                                                                                      partFseachFChatConversationRow,
                                                                                      ParamType.SupabaseRow,
                                                                                    ),
                                                                                  }.withoutNulls,
                                                                                );
                                                                              },
                                                                              child: Icon(
                                                                                Icons.arrow_forward_ios,
                                                                                color: FlutterFlowTheme.of(context).primaryText,
                                                                                size: 24.0,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ].divide(SizedBox(
                                                                              width: 15.0)),
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            if ((_model.participation ==
                                                    false) &&
                                                (_model.inSearch == true))
                                              Builder(
                                                builder: (context) {
                                                  final filteredGroup =
                                                      SupabaseGroup
                                                              .searchAGroupCall
                                                              .conversation(
                                                                (_model.filterGroup
                                                                        ?.jsonBody ??
                                                                    ''),
                                                              )
                                                              ?.toList() ??
                                                          [];

                                                  return ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    primary: false,
                                                    shrinkWrap: true,
                                                    scrollDirection:
                                                        Axis.vertical,
                                                    itemCount:
                                                        filteredGroup.length,
                                                    itemBuilder: (context,
                                                        filteredGroupIndex) {
                                                      final filteredGroupItem =
                                                          filteredGroup[
                                                              filteredGroupIndex];
                                                      return FutureBuilder<
                                                          List<
                                                              ChatConversationRow>>(
                                                        future:
                                                            ChatConversationTable()
                                                                .querySingleRow(
                                                          queryFn: (q) =>
                                                              q.eqOrNull(
                                                            'id',
                                                            GroupTypeStruct
                                                                    .maybeFromMap(
                                                                        filteredGroupItem)
                                                                ?.conversationId,
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
                                                          List<ChatConversationRow>
                                                              containerChatConversationRowList =
                                                              snapshot.data!;

                                                          // Return an empty Container when the item does not exist.
                                                          if (snapshot
                                                              .data!.isEmpty) {
                                                            return Container();
                                                          }
                                                          final containerChatConversationRow =
                                                              containerChatConversationRowList
                                                                      .isNotEmpty
                                                                  ? containerChatConversationRowList
                                                                      .first
                                                                  : null;

                                                          return Container(
                                                            decoration:
                                                                BoxDecoration(),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(5.0),
                                                              child: Container(
                                                                width: double
                                                                    .infinity,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10.0),
                                                                ),
                                                                child: Padding(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              10.0),
                                                                  child: FutureBuilder<
                                                                      List<
                                                                          ConversationGroupRow>>(
                                                                    future: ConversationGroupTable()
                                                                        .querySingleRow(
                                                                      queryFn:
                                                                          (q) =>
                                                                              q.eqOrNull(
                                                                        'conversation_id',
                                                                        containerChatConversationRow
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
                                                                      List<ConversationGroupRow>
                                                                          rowConversationGroupRowList =
                                                                          snapshot
                                                                              .data!;

                                                                      // Return an empty Container when the item does not exist.
                                                                      if (snapshot
                                                                          .data!
                                                                          .isEmpty) {
                                                                        return Container();
                                                                      }
                                                                      final rowConversationGroupRow = rowConversationGroupRowList
                                                                              .isNotEmpty
                                                                          ? rowConversationGroupRowList
                                                                              .first
                                                                          : null;

                                                                      return InkWell(
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
                                                                              'COMMUNITY_PAGE_Row_fnhk6kfg_ON_TAP');
                                                                          logFirebaseEvent(
                                                                              'Row_backend_call');
                                                                          _model.apiResultavh2 = await SupabaseGroup
                                                                              .checkIfAUserIsInAGroupCall
                                                                              .call(
                                                                            userId:
                                                                                communityUsersRow?.id,
                                                                            conversationId:
                                                                                containerChatConversationRow?.id,
                                                                          );

                                                                          if (SupabaseGroup
                                                                              .checkIfAUserIsInAGroupCall
                                                                              .result(
                                                                            (_model.apiResultavh?.jsonBody ??
                                                                                ''),
                                                                          )!) {
                                                                            logFirebaseEvent('Row_navigate_to');

                                                                            context.pushNamed(
                                                                              ChatPageWidget.routeName,
                                                                              queryParameters: {
                                                                                'conversation': serializeParam(
                                                                                  containerChatConversationRow,
                                                                                  ParamType.SupabaseRow,
                                                                                ),
                                                                              }.withoutNulls,
                                                                            );
                                                                          } else {
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
                                                                          }

                                                                          safeSetState(
                                                                              () {});
                                                                        },
                                                                        child:
                                                                            Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children:
                                                                              [
                                                                            if (rowConversationGroupRow?.imageUrl != null &&
                                                                                rowConversationGroupRow?.imageUrl != '')
                                                                              ClipRRect(
                                                                                borderRadius: BorderRadius.circular(50.0),
                                                                                child: Image.network(
                                                                                  rowConversationGroupRow!.imageUrl!,
                                                                                  width: 50.0,
                                                                                  height: 50.0,
                                                                                  fit: BoxFit.cover,
                                                                                ),
                                                                              ),
                                                                            if (rowConversationGroupRow?.imageUrl == null ||
                                                                                rowConversationGroupRow?.imageUrl == '')
                                                                              ClipRRect(
                                                                                borderRadius: BorderRadius.circular(50.0),
                                                                                child: Image.network(
                                                                                  'https://jfbfymiyqlyciapfloug.supabase.co/storage/v1/object/public/images/group_photo/jive-sgroup-default-portrait-large.png',
                                                                                  width: 50.0,
                                                                                  height: 50.0,
                                                                                  fit: BoxFit.cover,
                                                                                ),
                                                                              ),
                                                                            Column(
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                Text(
                                                                                  valueOrDefault<String>(
                                                                                    rowConversationGroupRow?.name,
                                                                                    'group name',
                                                                                  ),
                                                                                  style: FlutterFlowTheme.of(context).labelLarge.override(
                                                                                        font: GoogleFonts.poppins(
                                                                                          fontWeight: FlutterFlowTheme.of(context).labelLarge.fontWeight,
                                                                                          fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                                                                                        ),
                                                                                        letterSpacing: 0.0,
                                                                                        fontWeight: FlutterFlowTheme.of(context).labelLarge.fontWeight,
                                                                                        fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                                                                                      ),
                                                                                ),
                                                                                Text(
                                                                                  valueOrDefault<String>(
                                                                                    rowConversationGroupRow?.description,
                                                                                    'group description',
                                                                                  ),
                                                                                  style: FlutterFlowTheme.of(context).labelSmall.override(
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
                                                                            Column(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                              children: [
                                                                                InkWell(
                                                                                  splashColor: Colors.transparent,
                                                                                  focusColor: Colors.transparent,
                                                                                  hoverColor: Colors.transparent,
                                                                                  highlightColor: Colors.transparent,
                                                                                  onTap: () async {
                                                                                    logFirebaseEvent('COMMUNITY_PAGE_Icon_f2zxtl37_ON_TAP');
                                                                                    logFirebaseEvent('Icon_navigate_to');

                                                                                    context.pushNamed(
                                                                                      ChatPageWidget.routeName,
                                                                                      queryParameters: {
                                                                                        'conversation': serializeParam(
                                                                                          containerChatConversationRow,
                                                                                          ParamType.SupabaseRow,
                                                                                        ),
                                                                                      }.withoutNulls,
                                                                                    );
                                                                                  },
                                                                                  child: Icon(
                                                                                    Icons.arrow_forward_ios,
                                                                                    color: FlutterFlowTheme.of(context).primaryText,
                                                                                    size: 24.0,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ].divide(SizedBox(width: 15.0)),
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),
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
                                            if ((_model.participation ==
                                                    true) &&
                                                (_model.inSearch == false))
                                              FutureBuilder<
                                                  List<
                                                      ConversationGroupByNameRow>>(
                                                future:
                                                    ConversationGroupByNameTable()
                                                        .queryRows(
                                                  queryFn: (q) => q.eqOrNull(
                                                    'requester_id',
                                                    communityUsersRow?.id,
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
                                                  List<ConversationGroupByNameRow>
                                                      partTsearchFConversationGroupByNameRowList =
                                                      snapshot.data!;

                                                  return ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    primary: false,
                                                    shrinkWrap: true,
                                                    scrollDirection:
                                                        Axis.vertical,
                                                    itemCount:
                                                        partTsearchFConversationGroupByNameRowList
                                                            .length,
                                                    itemBuilder: (context,
                                                        partTsearchFIndex) {
                                                      final partTsearchFConversationGroupByNameRow =
                                                          partTsearchFConversationGroupByNameRowList[
                                                              partTsearchFIndex];
                                                      return FutureBuilder<
                                                          List<
                                                              ChatConversationRow>>(
                                                        future:
                                                            ChatConversationTable()
                                                                .querySingleRow(
                                                          queryFn: (q) =>
                                                              q.eqOrNull(
                                                            'id',
                                                            partTsearchFConversationGroupByNameRow
                                                                .conversationId,
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
                                                          List<ChatConversationRow>
                                                              containerChatConversationRowList =
                                                              snapshot.data!;

                                                          final containerChatConversationRow =
                                                              containerChatConversationRowList
                                                                      .isNotEmpty
                                                                  ? containerChatConversationRowList
                                                                      .first
                                                                  : null;

                                                          return Container(
                                                            decoration:
                                                                BoxDecoration(),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(5.0),
                                                              child: Container(
                                                                width: double
                                                                    .infinity,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10.0),
                                                                ),
                                                                child: Padding(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              10.0),
                                                                  child: FutureBuilder<
                                                                      List<
                                                                          ConversationGroupRow>>(
                                                                    future: ConversationGroupTable()
                                                                        .querySingleRow(
                                                                      queryFn:
                                                                          (q) =>
                                                                              q.eqOrNull(
                                                                        'conversation_id',
                                                                        partTsearchFConversationGroupByNameRow
                                                                            .conversationId,
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
                                                                      List<ConversationGroupRow>
                                                                          rowConversationGroupRowList =
                                                                          snapshot
                                                                              .data!;

                                                                      // Return an empty Container when the item does not exist.
                                                                      if (snapshot
                                                                          .data!
                                                                          .isEmpty) {
                                                                        return Container();
                                                                      }
                                                                      final rowConversationGroupRow = rowConversationGroupRowList
                                                                              .isNotEmpty
                                                                          ? rowConversationGroupRowList
                                                                              .first
                                                                          : null;

                                                                      return InkWell(
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
                                                                              'COMMUNITY_PAGE_Row_q7jju3e7_ON_TAP');
                                                                          logFirebaseEvent(
                                                                              'Row_backend_call');
                                                                          _model.apiResultavh1 = await SupabaseGroup
                                                                              .checkIfAUserIsInAGroupCall
                                                                              .call(
                                                                            userId:
                                                                                communityUsersRow?.id,
                                                                            conversationId:
                                                                                containerChatConversationRow?.id,
                                                                          );

                                                                          if (SupabaseGroup
                                                                              .checkIfAUserIsInAGroupCall
                                                                              .result(
                                                                            (_model.apiResultavh?.jsonBody ??
                                                                                ''),
                                                                          )!) {
                                                                            logFirebaseEvent('Row_navigate_to');

                                                                            context.pushNamed(
                                                                              ChatPageWidget.routeName,
                                                                              queryParameters: {
                                                                                'conversation': serializeParam(
                                                                                  containerChatConversationRow,
                                                                                  ParamType.SupabaseRow,
                                                                                ),
                                                                              }.withoutNulls,
                                                                            );
                                                                          } else {
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
                                                                          }

                                                                          safeSetState(
                                                                              () {});
                                                                        },
                                                                        child:
                                                                            Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          children:
                                                                              [
                                                                            if (rowConversationGroupRow?.imageUrl != null &&
                                                                                rowConversationGroupRow?.imageUrl != '')
                                                                              ClipRRect(
                                                                                borderRadius: BorderRadius.circular(50.0),
                                                                                child: Image.network(
                                                                                  rowConversationGroupRow!.imageUrl!,
                                                                                  width: 50.0,
                                                                                  height: 50.0,
                                                                                  fit: BoxFit.cover,
                                                                                ),
                                                                              ),
                                                                            if (rowConversationGroupRow?.imageUrl == null ||
                                                                                rowConversationGroupRow?.imageUrl == '')
                                                                              ClipRRect(
                                                                                borderRadius: BorderRadius.circular(50.0),
                                                                                child: Image.network(
                                                                                  'https://jfbfymiyqlyciapfloug.supabase.co/storage/v1/object/public/images/group_photo/jive-sgroup-default-portrait-large.png',
                                                                                  width: 50.0,
                                                                                  height: 50.0,
                                                                                  fit: BoxFit.cover,
                                                                                ),
                                                                              ),
                                                                            Expanded(
                                                                              child: Column(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  Text(
                                                                                    valueOrDefault<String>(
                                                                                      rowConversationGroupRow?.name,
                                                                                      'group name',
                                                                                    ),
                                                                                    style: FlutterFlowTheme.of(context).labelLarge.override(
                                                                                          font: GoogleFonts.poppins(
                                                                                            fontWeight: FlutterFlowTheme.of(context).labelLarge.fontWeight,
                                                                                            fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                                                                                          ),
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FlutterFlowTheme.of(context).labelLarge.fontWeight,
                                                                                          fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                                                                                        ),
                                                                                  ),
                                                                                  Text(
                                                                                    valueOrDefault<String>(
                                                                                      rowConversationGroupRow?.description,
                                                                                      'group description',
                                                                                    ),
                                                                                    style: FlutterFlowTheme.of(context).labelSmall.override(
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
                                                                            Column(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                              children: [
                                                                                InkWell(
                                                                                  splashColor: Colors.transparent,
                                                                                  focusColor: Colors.transparent,
                                                                                  hoverColor: Colors.transparent,
                                                                                  highlightColor: Colors.transparent,
                                                                                  onTap: () async {
                                                                                    logFirebaseEvent('COMMUNITY_PAGE_Icon_1qgl9f1t_ON_TAP');
                                                                                    logFirebaseEvent('Icon_navigate_to');

                                                                                    context.pushNamed(
                                                                                      ChatPageWidget.routeName,
                                                                                      queryParameters: {
                                                                                        'conversation': serializeParam(
                                                                                          containerChatConversationRow,
                                                                                          ParamType.SupabaseRow,
                                                                                        ),
                                                                                      }.withoutNulls,
                                                                                    );
                                                                                  },
                                                                                  child: Icon(
                                                                                    Icons.arrow_forward_ios,
                                                                                    color: FlutterFlowTheme.of(context).primaryText,
                                                                                    size: 24.0,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ].divide(SizedBox(width: 10.0)),
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),
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
                                            if ((_model.participation ==
                                                    true) &&
                                                (_model.inSearch == true))
                                              Builder(
                                                builder: (context) {
                                                  final filteredGroupbyId =
                                                      getJsonField(
                                                    (_model.filterGroupbyId
                                                            ?.jsonBody ??
                                                        ''),
                                                    r'''$.conversations''',
                                                  ).toList();

                                                  return ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    primary: false,
                                                    shrinkWrap: true,
                                                    scrollDirection:
                                                        Axis.vertical,
                                                    itemCount: filteredGroupbyId
                                                        .length,
                                                    itemBuilder: (context,
                                                        filteredGroupbyIdIndex) {
                                                      final filteredGroupbyIdItem =
                                                          filteredGroupbyId[
                                                              filteredGroupbyIdIndex];
                                                      return FutureBuilder<
                                                          List<
                                                              ChatConversationRow>>(
                                                        future:
                                                            ChatConversationTable()
                                                                .querySingleRow(
                                                          queryFn: (q) =>
                                                              q.eqOrNull(
                                                            'id',
                                                            GroupByNameTypeStruct
                                                                    .maybeFromMap(
                                                                        filteredGroupbyIdItem)
                                                                ?.conversationId,
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
                                                          List<ChatConversationRow>
                                                              containerChatConversationRowList =
                                                              snapshot.data!;

                                                          // Return an empty Container when the item does not exist.
                                                          if (snapshot
                                                              .data!.isEmpty) {
                                                            return Container();
                                                          }
                                                          final containerChatConversationRow =
                                                              containerChatConversationRowList
                                                                      .isNotEmpty
                                                                  ? containerChatConversationRowList
                                                                      .first
                                                                  : null;

                                                          return Container(
                                                            decoration:
                                                                BoxDecoration(),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(5.0),
                                                              child: Container(
                                                                width: double
                                                                    .infinity,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10.0),
                                                                ),
                                                                child: Padding(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              10.0),
                                                                  child: FutureBuilder<
                                                                      List<
                                                                          ConversationGroupRow>>(
                                                                    future: ConversationGroupTable()
                                                                        .querySingleRow(
                                                                      queryFn:
                                                                          (q) =>
                                                                              q.eqOrNull(
                                                                        'conversation_id',
                                                                        containerChatConversationRow
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
                                                                      List<ConversationGroupRow>
                                                                          rowConversationGroupRowList =
                                                                          snapshot
                                                                              .data!;

                                                                      // Return an empty Container when the item does not exist.
                                                                      if (snapshot
                                                                          .data!
                                                                          .isEmpty) {
                                                                        return Container();
                                                                      }
                                                                      final rowConversationGroupRow = rowConversationGroupRowList
                                                                              .isNotEmpty
                                                                          ? rowConversationGroupRowList
                                                                              .first
                                                                          : null;

                                                                      return InkWell(
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
                                                                              'COMMUNITY_PAGE_Row_fcdrz6q3_ON_TAP');
                                                                          logFirebaseEvent(
                                                                              'Row_backend_call');
                                                                          _model.checkConversation = await SupabaseGroup
                                                                              .checkIfAUserIsInAGroupCall
                                                                              .call(
                                                                            userId:
                                                                                communityUsersRow?.id,
                                                                            conversationId:
                                                                                containerChatConversationRow?.id,
                                                                          );

                                                                          if (SupabaseGroup
                                                                              .checkIfAUserIsInAGroupCall
                                                                              .result(
                                                                            (_model.apiResultavh?.jsonBody ??
                                                                                ''),
                                                                          )!) {
                                                                            logFirebaseEvent('Row_navigate_to');

                                                                            context.pushNamed(
                                                                              ChatPageWidget.routeName,
                                                                              queryParameters: {
                                                                                'conversation': serializeParam(
                                                                                  containerChatConversationRow,
                                                                                  ParamType.SupabaseRow,
                                                                                ),
                                                                              }.withoutNulls,
                                                                            );
                                                                          } else {
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
                                                                          }

                                                                          safeSetState(
                                                                              () {});
                                                                        },
                                                                        child:
                                                                            Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          children:
                                                                              [
                                                                            if (rowConversationGroupRow?.imageUrl != null &&
                                                                                rowConversationGroupRow?.imageUrl != '')
                                                                              ClipRRect(
                                                                                borderRadius: BorderRadius.circular(50.0),
                                                                                child: Image.network(
                                                                                  rowConversationGroupRow!.imageUrl!,
                                                                                  width: 50.0,
                                                                                  height: 50.0,
                                                                                  fit: BoxFit.cover,
                                                                                ),
                                                                              ),
                                                                            if (rowConversationGroupRow?.imageUrl == null ||
                                                                                rowConversationGroupRow?.imageUrl == '')
                                                                              ClipRRect(
                                                                                borderRadius: BorderRadius.circular(50.0),
                                                                                child: Image.network(
                                                                                  'https://jfbfymiyqlyciapfloug.supabase.co/storage/v1/object/public/images/group_photo/jive-sgroup-default-portrait-large.png',
                                                                                  width: 50.0,
                                                                                  height: 50.0,
                                                                                  fit: BoxFit.cover,
                                                                                ),
                                                                              ),
                                                                            Expanded(
                                                                              child: Column(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  Text(
                                                                                    valueOrDefault<String>(
                                                                                      rowConversationGroupRow?.name,
                                                                                      'group name',
                                                                                    ),
                                                                                    style: FlutterFlowTheme.of(context).labelLarge.override(
                                                                                          font: GoogleFonts.poppins(
                                                                                            fontWeight: FlutterFlowTheme.of(context).labelLarge.fontWeight,
                                                                                            fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                                                                                          ),
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FlutterFlowTheme.of(context).labelLarge.fontWeight,
                                                                                          fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                                                                                        ),
                                                                                  ),
                                                                                  Text(
                                                                                    valueOrDefault<String>(
                                                                                      rowConversationGroupRow?.description,
                                                                                      'group description',
                                                                                    ),
                                                                                    style: FlutterFlowTheme.of(context).labelSmall.override(
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
                                                                            Column(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                              children: [
                                                                                InkWell(
                                                                                  splashColor: Colors.transparent,
                                                                                  focusColor: Colors.transparent,
                                                                                  hoverColor: Colors.transparent,
                                                                                  highlightColor: Colors.transparent,
                                                                                  onTap: () async {
                                                                                    logFirebaseEvent('COMMUNITY_PAGE_Icon_f4qgkld1_ON_TAP');
                                                                                    logFirebaseEvent('Icon_navigate_to');

                                                                                    context.pushNamed(
                                                                                      ChatPageWidget.routeName,
                                                                                      queryParameters: {
                                                                                        'conversation': serializeParam(
                                                                                          containerChatConversationRow,
                                                                                          ParamType.SupabaseRow,
                                                                                        ),
                                                                                      }.withoutNulls,
                                                                                    );
                                                                                  },
                                                                                  child: Icon(
                                                                                    Icons.arrow_forward_ios,
                                                                                    color: FlutterFlowTheme.of(context).primaryText,
                                                                                    size: 24.0,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ].divide(SizedBox(width: 10.0)),
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),
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
                      if (communityUsersRow?.freePlan ?? true)
                        Container(
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Text(
                                FFLocalizations.of(context).getText(
                                  '0hy8o68j' /* Veuillez mettre à jour votre a... */,
                                ),
                                textAlign: TextAlign.center,
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
                              FFButtonWidget(
                                onPressed: () async {
                                  logFirebaseEvent(
                                      'COMMUNITY_PAGE_METRRE__JOUR_BTN_ON_TAP');
                                  logFirebaseEvent('Button_navigate_to');

                                  context.pushNamed(
                                      PaymentSubscriptionWidget.routeName);
                                },
                                text: FFLocalizations.of(context).getText(
                                  'cb3r2a11' /* Metrre à jour */,
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
                            ].divide(SizedBox(height: 10.0)),
                          ),
                        ),
                    ].divide(SizedBox(height: 20.0)),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
