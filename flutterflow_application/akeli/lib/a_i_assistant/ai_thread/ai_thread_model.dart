import '/a_i_assistant/ai_chat/ai_chat_widget.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'ai_thread_widget.dart' show AiThreadWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AiThreadModel extends FlutterFlowModel<AiThreadWidget> {
  ///  Local state fields for this component.

  String? status;

  List<dynamic> listMessage = [];
  void addToListMessage(dynamic item) => listMessage.add(item);
  void removeFromListMessage(dynamic item) => listMessage.remove(item);
  void removeAtIndexFromListMessage(int index) => listMessage.removeAt(index);
  void insertAtIndexInListMessage(int index, dynamic item) =>
      listMessage.insert(index, item);
  void updateListMessageAtIndex(int index, Function(dynamic) updateFn) =>
      listMessage[index] = updateFn(listMessage[index]);

  bool buttonOn = true;

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - API (get ai message)] action in ai_thread widget.
  ApiCallResponse? getMessage;
  // Models for ai_chat dynamic component.
  late FlutterFlowDynamicModels<AiChatModel> aiChatModels;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Backend Call - API (AIassistant)] action in Icon widget.
  ApiCallResponse? aiMessage;

  @override
  void initState(BuildContext context) {
    aiChatModels = FlutterFlowDynamicModels(() => AiChatModel());
  }

  @override
  void dispose() {
    aiChatModels.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
