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
import 'chat_page_widget.dart' show ChatPageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ChatPageModel extends FlutterFlowModel<ChatPageWidget> {
  ///  Local state fields for this page.

  List<UsersRow> convUsers = [];
  void addToConvUsers(UsersRow item) => convUsers.add(item);
  void removeFromConvUsers(UsersRow item) => convUsers.remove(item);
  void removeAtIndexFromConvUsers(int index) => convUsers.removeAt(index);
  void insertAtIndexInConvUsers(int index, UsersRow item) =>
      convUsers.insert(index, item);
  void updateConvUsersAtIndex(int index, Function(UsersRow) updateFn) =>
      convUsers[index] = updateFn(convUsers[index]);

  List<dynamic> chatMessages = [];
  void addToChatMessages(dynamic item) => chatMessages.add(item);
  void removeFromChatMessages(dynamic item) => chatMessages.remove(item);
  void removeAtIndexFromChatMessages(int index) => chatMessages.removeAt(index);
  void insertAtIndexInChatMessages(int index, dynamic item) =>
      chatMessages.insert(index, item);
  void updateChatMessagesAtIndex(int index, Function(dynamic) updateFn) =>
      chatMessages[index] = updateFn(chatMessages[index]);

  int? conversationId;

  String? oldestmessageTime;

  bool hasMoreMessage = true;

  bool isLoadingmore = false;

  List<dynamic> local = [];
  void addToLocal(dynamic item) => local.add(item);
  void removeFromLocal(dynamic item) => local.remove(item);
  void removeAtIndexFromLocal(int index) => local.removeAt(index);
  void insertAtIndexInLocal(int index, dynamic item) =>
      local.insert(index, item);
  void updateLocalAtIndex(int index, Function(dynamic) updateFn) =>
      local[index] = updateFn(local[index]);

  ///  State fields for stateful widgets in this page.

  Stream<List<ChatMessageRow>>? chatPageSupabaseStream;
  // Stores action output result for [Backend Call - API (get chat messages)] action in chatPage widget.
  ApiCallResponse? chatMessgae;
  // Stores action output result for [Backend Call - Query Rows] action in chatPage widget.
  List<ConversationParticipantRow>? convPart;
  // Stores action output result for [Backend Call - Query Rows] action in chatPage widget.
  List<UsersRow>? convUser;
  // Stores action output result for [Backend Call - Query Rows] action in chatPage widget.
  List<ChatMessageRow>? querriedMessage;
  // Stores action output result for [Backend Call - API (get chat messages)] action in ListView widget.
  ApiCallResponse? apiResultil2;
  // Models for chat dynamic component.
  late FlutterFlowDynamicModels<ChatModel> chatModels;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Backend Call - API (send a message)] action in IconButton widget.
  ApiCallResponse? sendMessage;
  // Stores action output result for [Backend Call - Update Row(s)] action in IconButton widget.
  List<ChatConversationRow>? lastMessage;
  // Stores action output result for [Backend Call - API (chat notiification)] action in IconButton widget.
  ApiCallResponse? chatNotification;

  @override
  void initState(BuildContext context) {
    chatModels = FlutterFlowDynamicModels(() => ChatModel());
  }

  @override
  void dispose() {
    chatModels.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
