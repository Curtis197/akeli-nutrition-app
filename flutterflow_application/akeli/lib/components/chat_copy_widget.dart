import '/auth/firebase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/backend/schema/structs/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'chat_copy_model.dart';
export 'chat_copy_model.dart';

class ChatCopyWidget extends StatefulWidget {
  const ChatCopyWidget({
    super.key,
    required this.message,
  });

  final dynamic message;

  @override
  State<ChatCopyWidget> createState() => _ChatCopyWidgetState();
}

class _ChatCopyWidgetState extends State<ChatCopyWidget> {
  late ChatCopyModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ChatCopyModel());

    // On component load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      logFirebaseEvent('CHAT_COPY_COMP_chatCopy_ON_INIT_STATE');
      logFirebaseEvent('chatCopy_update_component_state');
      _model.readBy = ChatMessageStruct.maybeFromMap(widget!.message!)!
          .readBy
          .toList()
          .cast<int>();
      safeSetState(() {});
      if (!_model.readBy.contains(valueOrDefault(currentUserDocument?.id, 0))) {
        logFirebaseEvent('chatCopy_update_component_state');
        _model.addToReadBy(valueOrDefault(currentUserDocument?.id, 0));
        safeSetState(() {});
        logFirebaseEvent('chatCopy_backend_call');
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
        logFirebaseEvent('chatCopy_backend_call');
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
            Text(
              widget!.message!.toString(),
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.poppins(
                      fontWeight:
                          FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
            ),
            Text(
              widget!.message!.toString(),
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.poppins(
                      fontWeight:
                          FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
