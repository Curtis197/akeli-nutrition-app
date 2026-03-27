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
import 'community_widget.dart' show CommunityWidget;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class CommunityModel extends FlutterFlowModel<CommunityWidget> {
  ///  Local state fields for this page.

  bool participation = false;

  bool inSearch = false;

  bool test = false;

  ///  State fields for stateful widgets in this page.

  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ? tabBarController!.previousIndex : 0;

  // State field(s) for convSearch widget.
  FocusNode? convSearchFocusNode;
  TextEditingController? convSearchTextController;
  String? Function(BuildContext, String?)? convSearchTextControllerValidator;
  // Stores action output result for [Backend Call - API (search a private conversation)] action in convSearch widget.
  ApiCallResponse? privateConversation;
  Completer<List<ConversationDemandRow>>? requestCompleter;
  // Stores action output result for [Backend Call - API (find or create the conversation)] action in Icon widget.
  ApiCallResponse? newConversation;
  // Stores action output result for [Backend Call - Delete Row(s)] action in Icon widget.
  List<ConversationDemandRow>? deleteConversation;
  // Stores action output result for [Backend Call - Query Rows] action in Icon widget.
  List<ChatConversationRow>? queriedChat;
  Stream<List<ConversationParticipantRow>>? listViewSupabaseStream;
  // Models for chatUser dynamic component.
  late FlutterFlowDynamicModels<ChatUserModel> chatUserModels1;
  // Models for chatUser dynamic component.
  late FlutterFlowDynamicModels<ChatUserModel> chatUserModels2;
  // State field(s) for groupSearch widget.
  FocusNode? groupSearchFocusNode;
  TextEditingController? groupSearchTextController;
  String? Function(BuildContext, String?)? groupSearchTextControllerValidator;
  // Stores action output result for [Backend Call - API (search a group by name)] action in groupSearch widget.
  ApiCallResponse? filterGroupbyId;
  // Stores action output result for [Backend Call - API (search a group)] action in groupSearch widget.
  ApiCallResponse? filterGroup;
  // State field(s) for RadioButton widget.
  FormFieldController<String>? radioButtonValueController;
  // Stores action output result for [Backend Call - API (check if a user is in a group)] action in Row widget.
  ApiCallResponse? apiResultavh;
  // Stores action output result for [Backend Call - API (check if a user is in a group)] action in Row widget.
  ApiCallResponse? apiResultavh2;
  // Stores action output result for [Backend Call - API (check if a user is in a group)] action in Row widget.
  ApiCallResponse? apiResultavh1;
  // Stores action output result for [Backend Call - API (check if a user is in a group)] action in Row widget.
  ApiCallResponse? checkConversation;

  @override
  void initState(BuildContext context) {
    chatUserModels1 = FlutterFlowDynamicModels(() => ChatUserModel());
    chatUserModels2 = FlutterFlowDynamicModels(() => ChatUserModel());
  }

  @override
  void dispose() {
    tabBarController?.dispose();
    convSearchFocusNode?.dispose();
    convSearchTextController?.dispose();

    chatUserModels1.dispose();
    chatUserModels2.dispose();
    groupSearchFocusNode?.dispose();
    groupSearchTextController?.dispose();
  }

  /// Additional helper methods.
  Future waitForRequestCompleted({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = requestCompleter?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  String? get radioButtonValue => radioButtonValueController?.value;
}
