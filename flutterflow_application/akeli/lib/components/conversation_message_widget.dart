import '/auth/firebase_auth/auth_util.dart';
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
import 'conversation_message_model.dart';
export 'conversation_message_model.dart';

class ConversationMessageWidget extends StatefulWidget {
  const ConversationMessageWidget({
    super.key,
    required this.userID,
  });

  final int? userID;

  @override
  State<ConversationMessageWidget> createState() =>
      _ConversationMessageWidgetState();
}

class _ConversationMessageWidgetState extends State<ConversationMessageWidget> {
  late ConversationMessageModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ConversationMessageModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: widget!.userID != valueOrDefault(currentUserDocument?.id, 0),
      child: AuthUserStreamWidget(
        builder: (context) => FutureBuilder<List<ConversationParticipantRow>>(
          future: ConversationParticipantTable().queryRows(
            queryFn: (q) => q.eqOrNull(
              'user_id',
              widget!.userID,
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
                userConversationParticipantRowList = snapshot.data!;

            return Container(
              decoration: BoxDecoration(),
              child: FutureBuilder<List<ConversationParticipantRow>>(
                future: ConversationParticipantTable().queryRows(
                  queryFn: (q) => q.eqOrNull(
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
                  List<ConversationParticipantRow>
                      authUserConversationParticipantRowList = snapshot.data!;

                  return Container(
                    decoration: BoxDecoration(),
                    child: FutureBuilder<List<ChatConversationRow>>(
                      future: ChatConversationTable().querySingleRow(
                        queryFn: (q) => q
                            .inFilterOrNull(
                              'id',
                              authUserConversationParticipantRowList
                                  .map((e) => e.conversationId)
                                  .withoutNulls
                                  .toList(),
                            )
                            .inFilterOrNull(
                              'id',
                              userConversationParticipantRowList
                                  .map((e) => e.conversationId)
                                  .withoutNulls
                                  .toList(),
                            )
                            .eqOrNull(
                              'grouped',
                              false,
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
                        List<ChatConversationRow>
                            containerChatConversationRowList = snapshot.data!;

                        final containerChatConversationRow =
                            containerChatConversationRowList.isNotEmpty
                                ? containerChatConversationRowList.first
                                : null;

                        return Container(
                          decoration: BoxDecoration(),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              if (containerChatConversationRow?.id == null)
                                FFButtonWidget(
                                  onPressed: () async {
                                    logFirebaseEvent(
                                        'CONVERSATION_MESSAGE_AJOUTER_BTN_ON_TAP');
                                    logFirebaseEvent('Button_backend_call');
                                    await ConversationDemandTable().insert({
                                      'user_id': valueOrDefault(
                                          currentUserDocument?.id, 0),
                                      'destined_user': widget!.userID,
                                    });
                                  },
                                  text: FFLocalizations.of(context).getText(
                                    'oi2my8f7' /* Ajouter */,
                                  ),
                                  icon: Icon(
                                    Icons.add,
                                    size: 15.0,
                                  ),
                                  options: FFButtonOptions(
                                    height: 30.0,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        10.0, 0.0, 10.0, 0.0),
                                    iconAlignment: IconAlignment.end,
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: FlutterFlowTheme.of(context).primary,
                                    textStyle: FlutterFlowTheme.of(context)
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
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryBackground,
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
                                    elevation: 0.0,
                                    borderSide: BorderSide(
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              if (containerChatConversationRow?.id != null)
                                FFButtonWidget(
                                  onPressed: () async {
                                    logFirebaseEvent(
                                        'CONVERSATION_MESSAGE_ECRIRE_BTN_ON_TAP');
                                    logFirebaseEvent('Button_navigate_to');

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
                                  text: FFLocalizations.of(context).getText(
                                    '93hblve8' /* Ecrire */,
                                  ),
                                  icon: Icon(
                                    Icons.send_rounded,
                                    size: 15.0,
                                  ),
                                  options: FFButtonOptions(
                                    height: 30.0,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        10.0, 0.0, 10.0, 0.0),
                                    iconAlignment: IconAlignment.end,
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    textStyle: FlutterFlowTheme.of(context)
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
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
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
                                    elevation: 0.0,
                                    borderSide: BorderSide(
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
