import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'chat_user_model.dart';
export 'chat_user_model.dart';

class ChatUserWidget extends StatefulWidget {
  const ChatUserWidget({
    super.key,
    required this.chatConv,
    required this.currentUser,
  });

  final ChatConversationRow? chatConv;
  final int? currentUser;

  @override
  State<ChatUserWidget> createState() => _ChatUserWidgetState();
}

class _ChatUserWidgetState extends State<ChatUserWidget> {
  late ChatUserModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ChatUserModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(5.0),
      child: FutureBuilder<List<ConversationParticipantRow>>(
        future: ConversationParticipantTable().querySingleRow(
          queryFn: (q) => q
              .eqOrNull(
                'conversation_id',
                widget!.chatConv?.id,
              )
              .neqOrNull(
                'user_id',
                widget!.currentUser,
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
          List<ConversationParticipantRow>
              containerConversationParticipantRowList = snapshot.data!;

          final containerConversationParticipantRow =
              containerConversationParticipantRowList.isNotEmpty
                  ? containerConversationParticipantRowList.first
                  : null;

          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: FutureBuilder<List<UsersRow>>(
                future: UsersTable().querySingleRow(
                  queryFn: (q) => q.eqOrNull(
                    'id',
                    containerConversationParticipantRow?.userId,
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

                  final rowUsersRow =
                      rowUsersRowList.isNotEmpty ? rowUsersRowList.first : null;

                  return InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      logFirebaseEvent('CHAT_USER_COMP_Row_r7qnulce_ON_TAP');
                      logFirebaseEvent('Row_navigate_to');

                      context.pushNamed(
                        ChatPageWidget.routeName,
                        queryParameters: {
                          'conversation': serializeParam(
                            widget!.chatConv,
                            ParamType.SupabaseRow,
                          ),
                          'destinedUserId': serializeParam(
                            rowUsersRow?.id,
                            ParamType.int,
                          ),
                        }.withoutNulls,
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        if (rowUsersRow?.profilImageUrl != null &&
                            rowUsersRow?.profilImageUrl != '')
                          InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              logFirebaseEvent(
                                  'CHAT_USER_CircleImage_n7vrxzpd_ON_TAP');
                              logFirebaseEvent('CircleImage_navigate_to');

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
                            child: Container(
                              width: 50.0,
                              height: 50.0,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: Image.network(
                                rowUsersRow!.profilImageUrl!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        if (rowUsersRow?.profilImageUrl == null ||
                            rowUsersRow?.profilImageUrl == '')
                          InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              logFirebaseEvent(
                                  'CHAT_USER_CircleImage_jiajkw0f_ON_TAP');
                              logFirebaseEvent('CircleImage_navigate_to');

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
                            child: Container(
                              width: 50.0,
                              height: 50.0,
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
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                valueOrDefault<String>(
                                  rowUsersRow?.userName,
                                  'user name',
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .labelLarge
                                    .override(
                                      font: GoogleFonts.poppins(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .fontStyle,
                                    ),
                              ),
                              if (widget!.chatConv?.lastMessageContent !=
                                      null &&
                                  widget!.chatConv?.lastMessageContent != '')
                                Text(
                                  widget!.chatConv!.lastMessageContent!,
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
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_forward_ios,
                              color: FlutterFlowTheme.of(context).primaryText,
                              size: 24.0,
                            ),
                            if (widget!.chatConv?.lastMessageTime != null)
                              FutureBuilder<List<LastMessageTimeRow>>(
                                future: LastMessageTimeTable().querySingleRow(
                                  queryFn: (q) => q.eqOrNull(
                                    'id',
                                    widget!.chatConv?.id,
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
                                  List<LastMessageTimeRow>
                                      textLastMessageTimeRowList =
                                      snapshot.data!;

                                  final textLastMessageTimeRow =
                                      textLastMessageTimeRowList.isNotEmpty
                                          ? textLastMessageTimeRowList.first
                                          : null;

                                  return Text(
                                    dateTimeFormat(
                                      "relative",
                                      textLastMessageTimeRow!
                                          .localLastMessageTime!,
                                      locale: FFLocalizations.of(context)
                                          .languageCode,
                                    ),
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
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontStyle,
                                        ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ].divide(SizedBox(width: 5.0)),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
