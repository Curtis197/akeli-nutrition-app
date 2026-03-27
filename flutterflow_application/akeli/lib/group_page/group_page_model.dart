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
import 'group_page_widget.dart' show GroupPageWidget;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class GroupPageModel extends FlutterFlowModel<GroupPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Delete Row(s)] action in Button widget.
  List<ConversationDemandRow>? demandDelete;
  Completer<List<ConversationDemandRow>>? requestCompleter3;
  Completer<List<ConversationParticipantRow>>? requestCompleter2;
  Completer<List<ConversationDemandRow>>? requestCompleter1;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  ConversationDemandRow? groupDemand;
  // Stores action output result for [Backend Call - API (conversation request)] action in Button widget.
  ApiCallResponse? apiResultek0;
  // Stores action output result for [Backend Call - API (conversation accepted)] action in Icon widget.
  ApiCallResponse? apiResultgsl;
  // Stores action output result for [Backend Call - Delete Row(s)] action in Icon widget.
  List<ConversationDemandRow>? acceptedGroupedDemand;
  // Stores action output result for [Backend Call - API (conversation accepted)] action in Icon widget.
  ApiCallResponse? acceptedDemandNotification;
  Stream<List<ConversationParticipantRow>>? containerSupabaseStream;
  // Models for conversationMessage dynamic component.
  late FlutterFlowDynamicModels<ConversationMessageModel>
      conversationMessageModels;

  @override
  void initState(BuildContext context) {
    conversationMessageModels =
        FlutterFlowDynamicModels(() => ConversationMessageModel());
  }

  @override
  void dispose() {
    conversationMessageModels.dispose();
  }

  /// Additional helper methods.
  Future waitForRequestCompleted3({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = requestCompleter3?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  Future waitForRequestCompleted2({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = requestCompleter2?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  Future waitForRequestCompleted1({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = requestCompleter1?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
