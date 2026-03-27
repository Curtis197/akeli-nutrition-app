import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/recipe_management/recipe_review/recipe_review_widget.dart';
import 'dart:ui';
import '/index.dart';
import 'dart:async';
import 'userprofile_widget.dart' show UserprofileWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class UserprofileModel extends FlutterFlowModel<UserprofileWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Query Rows] action in userprofile widget.
  List<ConversationParticipantRow>? conv1;
  // Stores action output result for [Backend Call - Query Rows] action in userprofile widget.
  List<ConversationParticipantRow>? conv2;
  // Stores action output result for [Backend Call - Query Rows] action in userprofile widget.
  List<ChatConversationRow>? privateConv;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  ConversationDemandRow? newDemand;
  Completer<List<ConversationDemandRow>>? requestCompleter;
  // Stores action output result for [Backend Call - API (conversation request)] action in Button widget.
  ApiCallResponse? conversationRequest;
  // Stores action output result for [Backend Call - Delete Row(s)] action in Button widget.
  List<ChatMessageRow>? deletedMessage;
  // Stores action output result for [Backend Call - Delete Row(s)] action in Button widget.
  List<ConversationParticipantRow>? deletedParticipant;
  // Stores action output result for [Backend Call - Delete Row(s)] action in Button widget.
  List<ChatConversationRow>? deletedConversation;
  Completer<ApiCallResponse>? apiRequestCompleter;
  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ? tabBarController!.previousIndex : 0;

  Stream<List<ReceipeLikesRow>>? containerSupabaseStream;
  // Models for Recipe_Review dynamic component.
  late FlutterFlowDynamicModels<RecipeReviewModel> recipeReviewModels;

  @override
  void initState(BuildContext context) {
    recipeReviewModels = FlutterFlowDynamicModels(() => RecipeReviewModel());
  }

  @override
  void dispose() {
    tabBarController?.dispose();
    recipeReviewModels.dispose();
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

  Future waitForApiRequestCompleted({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleter?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
