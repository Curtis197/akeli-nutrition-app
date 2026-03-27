import '/auth/firebase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'chat_model.dart';
export 'chat_model.dart';

class ChatWidget extends StatefulWidget {
  const ChatWidget({
    super.key,
    required this.message,
  });

  final dynamic message;

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  late ChatModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ChatModel());

    // On component load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      logFirebaseEvent('CHAT_COMP_chat_ON_INIT_STATE');
      logFirebaseEvent('chat_update_component_state');
      _model.readBy = ChatMessageStruct.maybeFromMap(widget!.message!)!
          .readBy
          .toList()
          .cast<int>();
      safeSetState(() {});
      if (!_model.readBy.contains(valueOrDefault(currentUserDocument?.id, 0))) {
        logFirebaseEvent('chat_update_component_state');
        _model.addToReadBy(valueOrDefault(currentUserDocument?.id, 0));
        safeSetState(() {});
        logFirebaseEvent('chat_backend_call');
        await ChatMessageTable().update(
          data: {
            'read_by': _model.readBy,
          },
          matchingRows: (rows) => rows
              .eqOrNull(
                'conversation_id',
                ChatMessageStruct.maybeFromMap(widget!.message)?.conversationId,
              )
              .eqOrNull(
                'content',
                ChatMessageStruct.maybeFromMap(widget!.message)?.content,
              ),
        );
        logFirebaseEvent('chat_backend_call');
        _model.deleteNotification = await ChatNotificationsTable().delete(
          matchingRows: (rows) => rows
              .eqOrNull(
                'user_id',
                valueOrDefault(currentUserDocument?.id, 0),
              )
              .eqOrNull(
                'conversation_id',
                ChatMessageStruct.maybeFromMap(widget!.message)?.conversationId,
              ),
          returnRows: true,
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            if (ChatMessageStruct.maybeFromMap(widget!.message)?.userId ==
                valueOrDefault(currentUserDocument?.id, 0))
              Align(
                alignment: AlignmentDirectional(1.0, 0.0),
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: AuthUserStreamWidget(
                    builder: (context) => Container(
                      constraints: BoxConstraints(
                        maxWidth: 200.0,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0x264D96FF),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FFLocalizations.of(context).getText(
                                '1be3s9co' /* Moi */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                            Text(
                              getJsonField(
                                widget!.message,
                                r'''$.content''',
                              ).toString(),
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    font: GoogleFonts.poppins(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .fontStyle,
                                  ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if ((ChatMessageStruct.maybeFromMap(
                                                widget!.message)
                                            ?.readBy
                                            ?.length ==
                                        1) &&
                                    functions.jsonToBoolean(getJsonField(
                                      widget!.message,
                                      r'''$.received''',
                                    ))!)
                                  Icon(
                                    Icons.check_rounded,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 16.0,
                                  ),
                                if (functions
                                        .arrayToListInteger(getJsonField(
                                          widget!.message,
                                          r'''$.read_by''',
                                        ))!
                                        .length >=
                                    2)
                                  Icon(
                                    Icons.done_all_rounded,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 16.0,
                                  ),
                                Text(
                                  dateTimeFormat(
                                    "relative",
                                    functions
                                        .timestampzToLocalDateTime(getJsonField(
                                      widget!.message,
                                      r'''$.created_at''',
                                    ).toString()),
                                    locale: FFLocalizations.of(context)
                                        .languageCode,
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
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .fontStyle,
                                      ),
                                ),
                              ].divide(SizedBox(width: 5.0)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (getJsonField(
                  widget!.message,
                  r'''$.user_id''',
                ) !=
                valueOrDefault(currentUserDocument?.id, 0))
              Align(
                alignment: AlignmentDirectional(-1.0, 0.0),
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: AuthUserStreamWidget(
                    builder: (context) => FutureBuilder<List<UsersRow>>(
                      future: UsersTable().querySingleRow(
                        queryFn: (q) => q.eqOrNull(
                          'id',
                          ChatMessageStruct.maybeFromMap(widget!.message)
                              ?.userId,
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
                        List<UsersRow> containerUsersRowList = snapshot.data!;

                        // Return an empty Container when the item does not exist.
                        if (snapshot.data!.isEmpty) {
                          return Container();
                        }
                        final containerUsersRow =
                            containerUsersRowList.isNotEmpty
                                ? containerUsersRowList.first
                                : null;

                        return Container(
                          constraints: BoxConstraints(
                            maxWidth: 200.0,
                          ),
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: AlignmentDirectional(-1.0, -1.0),
                                  child: InkWell(
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () async {
                                      logFirebaseEvent(
                                          'CHAT_COMP_Text_296x2uip_ON_TAP');
                                      logFirebaseEvent('Text_navigate_to');

                                      context.pushNamed(
                                        UserprofileWidget.routeName,
                                        queryParameters: {
                                          'users': serializeParam(
                                            containerUsersRow,
                                            ParamType.SupabaseRow,
                                          ),
                                        }.withoutNulls,
                                      );
                                    },
                                    child: Text(
                                      valueOrDefault<String>(
                                        containerUsersRow?.userName,
                                        'sender name',
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w500,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w500,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                ),
                                Text(
                                  getJsonField(
                                    widget!.message,
                                    r'''$.content''',
                                  ).toString(),
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontStyle,
                                        ),
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if ((ChatMessageStruct.maybeFromMap(
                                                    widget!.message)
                                                ?.received ==
                                            true) &&
                                        (ChatMessageStruct.maybeFromMap(
                                                    widget!.message)
                                                ?.readBy
                                                ?.length ==
                                            1))
                                      Icon(
                                        Icons.check_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        size: 16.0,
                                      ),
                                    if (functions
                                            .arrayToListInteger(getJsonField(
                                              widget!.message,
                                              r'''$.read_by''',
                                            ))!
                                            .length >=
                                        2)
                                      Icon(
                                        Icons.done_all_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        size: 16.0,
                                      ),
                                    Text(
                                      dateTimeFormat(
                                        "relative",
                                        functions
                                            .timestampzToDateTime(getJsonField(
                                          widget!.message,
                                          r'''$.created_at''',
                                        ).toString()),
                                        locale: FFLocalizations.of(context)
                                            .languageCode,
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
                                  ].divide(SizedBox(width: 5.0)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
