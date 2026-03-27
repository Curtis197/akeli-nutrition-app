import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/community/chat/chat_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'chat_page_model.dart';
export 'chat_page_model.dart';

class ChatPageWidget extends StatefulWidget {
  const ChatPageWidget({
    super.key,
    required this.conversation,
    this.destinedUserId,
    this.conversationParticipant,
  });

  final ChatConversationRow? conversation;
  final int? destinedUserId;
  final ConversationParticipantRow? conversationParticipant;

  static String routeName = 'chatPage';
  static String routePath = '/chatPage';

  @override
  State<ChatPageWidget> createState() => _ChatPageWidgetState();
}

class _ChatPageWidgetState extends State<ChatPageWidget> {
  late ChatPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ChatPageModel());

    logFirebaseEvent('screen_view', parameters: {'screen_name': 'chatPage'});
    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      logFirebaseEvent('CHAT_PAGE_PAGE_chatPage_ON_INIT_STATE');
      await Future.wait([
        Future(() async {
          logFirebaseEvent('chatPage_backend_call');
          _model.chatMessgae = await SupabaseGroup.getChatMessagesCall.call(
            conversationId: widget!.conversation?.id,
            limit: 50,
            userId: valueOrDefault(currentUserDocument?.id, 0),
          );
        }),
        Future(() async {
          logFirebaseEvent('chatPage_backend_call');
          _model.convPart = await ConversationParticipantTable().queryRows(
            queryFn: (q) => q
                .eqOrNull(
                  'conversation_id',
                  widget!.conversation?.id,
                )
                .neqOrNull(
                  'user_id',
                  valueOrDefault(currentUserDocument?.id, 0),
                ),
          );
          logFirebaseEvent('chatPage_backend_call');
          _model.convUser = await UsersTable().queryRows(
            queryFn: (q) => q.inFilterOrNull(
              'id',
              _model.convPart?.map((e) => e.userId).withoutNulls.toList(),
            ),
          );
        }),
      ]);
      logFirebaseEvent('chatPage_update_page_state');
      _model.convUsers = _model.convUsers.toList().cast<UsersRow>();
      _model.chatMessages = SupabaseGroup.getChatMessagesCall
          .listMessage(
            (_model.chatMessgae?.jsonBody ?? ''),
          )!
          .toList()
          .cast<dynamic>();
      _model.conversationId = widget!.conversation?.id;
      _model.oldestmessageTime = SupabaseGroup.getChatMessagesCall.oldestTim(
        (_model.chatMessgae?.jsonBody ?? ''),
      );
      _model.hasMoreMessage = SupabaseGroup.getChatMessagesCall.hasMore(
        (_model.chatMessgae?.jsonBody ?? ''),
      )!;
      safeSetState(() {});
    });

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatMessageRow>>(
      stream: _model.chatPageSupabaseStream ??= SupaFlow.client
          .from("chat_message")
          .stream(primaryKey: ['id'])
          .eqOrNull(
            'conversation_id',
            widget!.conversation?.id,
          )
          .map((list) => list.map((item) => ChatMessageRow(item)).toList())
        ..listen((List<ChatMessageRow> chatPageChatMessageRowList) async {
          logFirebaseEvent('CHAT_PAGE_PAGE_chatPage_ON_DATA_CHANGE');
          logFirebaseEvent('chatPage_wait__delay');
          await Future.delayed(
            Duration(
              milliseconds: 1000,
            ),
          );
          logFirebaseEvent('chatPage_backend_call');
          _model.querriedMessage = await ChatMessageTable().queryRows(
            queryFn: (q) => q
                .eqOrNull(
                  'conversation_id',
                  widget!.conversation?.id,
                )
                .order('created_at'),
          );
          logFirebaseEvent('chatPage_update_page_state');
          _model.chatMessages = functions
              .newCustomFunction2(_model.querriedMessage?.toList())!
              .toList()
              .cast<dynamic>();
          safeSetState(() {});

          safeSetState(() {});
        }),
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
        List<ChatMessageRow> chatPageChatMessageRowList = snapshot.data!;

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
              leading: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      logFirebaseEvent('CHAT_PAGE_PAGE_Icon_6yz0w1dl_ON_TAP');
                      logFirebaseEvent('Icon_navigate_back');
                      context.safePop();
                    },
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      size: 32.0,
                    ),
                  ),
                ],
              ),
              title: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (widget!.conversation?.grouped == false)
                    FutureBuilder<List<UsersRow>>(
                      future: UsersTable().querySingleRow(
                        queryFn: (q) => q.eqOrNull(
                          'id',
                          widget!.destinedUserId,
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
                        List<UsersRow> rowUsersRowList = snapshot.data!;

                        // Return an empty Container when the item does not exist.
                        if (snapshot.data!.isEmpty) {
                          return Container();
                        }
                        final rowUsersRow = rowUsersRowList.isNotEmpty
                            ? rowUsersRowList.first
                            : null;

                        return InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            logFirebaseEvent(
                                'CHAT_PAGE_PAGE_Row_yfo9x0uv_ON_TAP');
                            logFirebaseEvent('Row_navigate_to');

                            context.pushNamed(
                              UserprofileWidget.routeName,
                              queryParameters: {
                                'users': serializeParam(
                                  rowUsersRow,
                                  ParamType.SupabaseRow,
                                ),
                              }.withoutNulls,
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              if (rowUsersRow?.profilImageUrl == null ||
                                  rowUsersRow?.profilImageUrl == '')
                                Container(
                                  width: 30.0,
                                  height: 30.0,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: Image.network(
                                    'https://picsum.photos/seed/682/600',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              if (rowUsersRow?.profilImageUrl != null &&
                                  rowUsersRow?.profilImageUrl != '')
                                Container(
                                  width: 30.0,
                                  height: 30.0,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: Image.network(
                                    rowUsersRow!.profilImageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              Text(
                                valueOrDefault<String>(
                                  rowUsersRow?.userName,
                                  'group name',
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .titleMedium
                                    .override(
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
                              ),
                            ].divide(SizedBox(width: 20.0)),
                          ),
                        );
                      },
                    ),
                  if (widget!.conversation?.grouped == true)
                    FutureBuilder<List<ConversationGroupRow>>(
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
                        List<ConversationGroupRow> rowConversationGroupRowList =
                            snapshot.data!;

                        // Return an empty Container when the item does not exist.
                        if (snapshot.data!.isEmpty) {
                          return Container();
                        }
                        final rowConversationGroupRow =
                            rowConversationGroupRowList.isNotEmpty
                                ? rowConversationGroupRowList.first
                                : null;

                        return InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            logFirebaseEvent(
                                'CHAT_PAGE_PAGE_Row_3pmki7j9_ON_TAP');
                            logFirebaseEvent('Row_navigate_to');

                            context.pushNamed(
                              GroupPageWidget.routeName,
                              queryParameters: {
                                'conversation': serializeParam(
                                  widget!.conversation,
                                  ParamType.SupabaseRow,
                                ),
                              }.withoutNulls,
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              if (rowConversationGroupRow?.imageUrl == null ||
                                  rowConversationGroupRow?.imageUrl == '')
                                Container(
                                  width: 30.0,
                                  height: 30.0,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: Image.network(
                                    'https://picsum.photos/seed/682/600',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              if (rowConversationGroupRow?.imageUrl != null &&
                                  rowConversationGroupRow?.imageUrl != '')
                                Container(
                                  width: 30.0,
                                  height: 30.0,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: Image.network(
                                    rowConversationGroupRow!.imageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              if (widget!.conversation?.grouped == true)
                                Text(
                                  valueOrDefault<String>(
                                    rowConversationGroupRow?.name,
                                    'group name',
                                  ),
                                  style: FlutterFlowTheme.of(context)
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
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .fontStyle,
                                      ),
                                ),
                            ].divide(SizedBox(width: 20.0)),
                          ),
                        );
                      },
                    ),
                ],
              ),
              actions: [],
              centerTitle: true,
              elevation: 2.0,
            ),
            body: SafeArea(
              top: true,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final message = _model.chatMessages.toList();

                        return RefreshIndicator(
                          onRefresh: () async {
                            logFirebaseEvent(
                                'CHAT_ListView_k6edwqkn_ON_PULL_TO_REFRES');
                            if (_model.hasMoreMessage) {
                              logFirebaseEvent('ListView_backend_call');
                              _model.apiResultil2 =
                                  await SupabaseGroup.getChatMessagesCall.call(
                                oldestTimeMessage: _model.oldestmessageTime,
                                limit: 50,
                                conversationId: widget!.conversation?.id,
                                userId:
                                    valueOrDefault(currentUserDocument?.id, 0),
                              );

                              if ((_model.chatMessgae?.succeeded ?? true)) {
                                if (SupabaseGroup.getChatMessagesCall.hasMore(
                                  (_model.chatMessgae?.jsonBody ?? ''),
                                )!) {
                                  logFirebaseEvent(
                                      'ListView_update_page_state');
                                  _model.hasMoreMessage = true;
                                  _model.oldestmessageTime = SupabaseGroup
                                      .getChatMessagesCall
                                      .oldestTim(
                                    (_model.chatMessgae?.jsonBody ?? ''),
                                  );
                                  _model.chatMessages = functions
                                      .prependMessage(
                                          _model.chatMessages.toList(),
                                          SupabaseGroup.getChatMessagesCall
                                              .listMessage(
                                                (_model.chatMessgae?.jsonBody ??
                                                    ''),
                                              )
                                              ?.toList())!
                                      .toList()
                                      .cast<dynamic>();
                                  safeSetState(() {});
                                } else {
                                  logFirebaseEvent(
                                      'ListView_update_page_state');
                                  _model.hasMoreMessage = false;
                                  _model.oldestmessageTime = SupabaseGroup
                                      .getChatMessagesCall
                                      .oldestTim(
                                    (_model.chatMessgae?.jsonBody ?? ''),
                                  );
                                  _model.chatMessages = functions
                                      .prependMessage(
                                          _model.chatMessages.toList(),
                                          SupabaseGroup.getChatMessagesCall
                                              .listMessage(
                                                (_model.chatMessgae?.jsonBody ??
                                                    ''),
                                              )
                                              ?.toList())!
                                      .toList()
                                      .cast<dynamic>();
                                  safeSetState(() {});
                                }
                              }
                            }
                          },
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            reverse: true,
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            itemCount: message.length,
                            itemBuilder: (context, messageIndex) {
                              final messageItem = message[messageIndex];
                              return wrapWithModel(
                                model: _model.chatModels.getModel(
                                  messageItem.toString(),
                                  messageIndex,
                                ),
                                updateCallback: () => safeSetState(() {}),
                                child: ChatWidget(
                                  key: Key(
                                    'Keyc4p_${messageItem.toString()}',
                                  ),
                                  message: messageItem,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(15.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: Container(
                              width: 200.0,
                              child: TextFormField(
                                controller: _model.textController,
                                focusNode: _model.textFieldFocusNode,
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
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                  hintText: FFLocalizations.of(context).getText(
                                    'i0f3xtwh' /* 
 */
                                    ,
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
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0x00000000),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).error,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).error,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  filled: true,
                                  fillColor:
                                      FlutterFlowTheme.of(context).alternate,
                                ),
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
                                cursorColor:
                                    FlutterFlowTheme.of(context).primaryText,
                                validator: _model.textControllerValidator
                                    .asValidator(context),
                              ),
                            ),
                          ),
                          FlutterFlowIconButton(
                            borderRadius: 50.0,
                            buttonSize: 40.0,
                            fillColor: FlutterFlowTheme.of(context).primary,
                            icon: Icon(
                              Icons.send_rounded,
                              color: FlutterFlowTheme.of(context).info,
                              size: 24.0,
                            ),
                            onPressed: () async {
                              logFirebaseEvent(
                                  'CHAT_PAGE_PAGE_send_rounded_ICN_ON_TAP');
                              logFirebaseEvent('IconButton_update_page_state');
                              _model.insertAtIndexInChatMessages(
                                  0,
                                  functions.chatMessage(
                                      getCurrentTimestamp,
                                      _model.textController.text,
                                      valueOrDefault(
                                          currentUserDocument?.id, 0),
                                      widget!.conversation?.id,
                                      true,
                                      functions
                                          .integerToArray(valueOrDefault(
                                              currentUserDocument?.id, 0))
                                          ?.toList())!);
                              safeSetState(() {});
                              await Future.wait([
                                Future(() async {
                                  logFirebaseEvent('IconButton_backend_call');
                                  _model.sendMessage =
                                      await SupabaseGroup.sendAMessageCall.call(
                                    content: _model.textController.text,
                                    conversationId: widget!.conversation?.id,
                                    received: true,
                                    userId: valueOrDefault(
                                        currentUserDocument?.id, 0),
                                  );

                                  if ((_model.sendMessage?.succeeded ?? true)) {
                                    logFirebaseEvent('IconButton_wait__delay');
                                    await Future.delayed(
                                      Duration(
                                        milliseconds: 500,
                                      ),
                                    );
                                    await Future.wait([
                                      Future(() async {
                                        logFirebaseEvent(
                                            'IconButton_backend_call');
                                        await ChatConversationTable().update(
                                          data: {
                                            'last_message_time':
                                                supaSerialize<DateTime>(
                                                    getCurrentTimestamp),
                                            'last_message_content':
                                                SupabaseGroup.sendAMessageCall
                                                    .content(
                                              (_model.sendMessage?.jsonBody ??
                                                  ''),
                                            ),
                                          },
                                          matchingRows: (rows) => rows.eqOrNull(
                                            'id',
                                            widget!.conversation?.id,
                                          ),
                                        );
                                      }),
                                      Future(() async {
                                        logFirebaseEvent(
                                            'IconButton_backend_call');
                                        _model.chatNotification =
                                            await SupabaseGroup
                                                .chatNotiificationCall
                                                .call(
                                          senderId: valueOrDefault(
                                              currentUserDocument?.id, 0),
                                          conversationId:
                                              widget!.conversation?.id,
                                          messageContent: SupabaseGroup
                                              .sendAMessageCall
                                              .content(
                                            (_model.sendMessage?.jsonBody ??
                                                ''),
                                          ),
                                          messageId:
                                              SupabaseGroup.sendAMessageCall.id(
                                            (_model.sendMessage?.jsonBody ??
                                                ''),
                                          ),
                                          userId: valueOrDefault(
                                              currentUserDocument?.id, 0),
                                        );
                                      }),
                                    ]);
                                  }
                                }),
                                Future(() async {
                                  logFirebaseEvent(
                                      'IconButton_clear_text_fields_pin_codes');
                                  safeSetState(() {
                                    _model.textController?.clear();
                                  });
                                }),
                              ]);

                              safeSetState(() {});
                            },
                          ),
                        ].divide(SizedBox(width: 25.0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
