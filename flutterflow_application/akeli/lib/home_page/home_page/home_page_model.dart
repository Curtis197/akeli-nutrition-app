import '/a_i_assistant/ai_thread/ai_thread_widget.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_count_controller.dart';
import '/flutter_flow/flutter_flow_radio_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/home_page/weight_graph/weight_graph_widget.dart';
import '/recipe_management/recipe_card_mini/recipe_card_mini_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'home_page_widget.dart' show HomePageWidget;
import 'package:badges/badges.dart' as badges;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class HomePageModel extends FlutterFlowModel<HomePageWidget> {
  ///  Local state fields for this page.

  bool aiChat = false;

  bool error = false;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (userContext)] action in HomePage widget.
  ApiCallResponse? userContext;
  // Stores action output result for [Backend Call - Query Rows] action in HomePage widget.
  List<MealPlanRow>? querriedMealPlan;
  // Stores action output result for [Backend Call - Update Row(s)] action in HomePage widget.
  List<UserSubscriptionRow>? lastConnection;
  // Model for WeightGraph component.
  late WeightGraphModel weightGraphModel;
  // State field(s) for CountController widget.
  int? countControllerValue;
  // Stores action output result for [Backend Call - Query Rows] action in CountController widget.
  List<UpdatedWeightRow>? currentWeightUpdate;
  // Stores action output result for [Backend Call - Update Row(s)] action in CountController widget.
  List<UpdatedWeightRow>? updatedWeight2;
  // Stores action output result for [Backend Call - Insert Row] action in CountController widget.
  UpdatedWeightRow? insertWeight;
  Completer<List<UpdatedWeightRow>>? requestCompleter2;
  Completer<List<WeightGraphDataRow>>? requestCompleter3;
  Completer<List<UserHealthParameterRow>>? requestCompleter1;
  // Stores action output result for [Backend Call - Delete Row(s)] action in Icon widget.
  List<ConversationDemandRow>? deletedDemand;
  Completer<List<ConversationDemandRow>>? requestCompleter6;
  // Stores action output result for [Backend Call - API (conversation accepted)] action in Icon widget.
  ApiCallResponse? apiResultxvc;
  // Stores action output result for [Backend Call - API (find or create the conversation)] action in Button widget.
  ApiCallResponse? newConversation;
  // Stores action output result for [Backend Call - Delete Row(s)] action in Button widget.
  List<ConversationDemandRow>? deleteConversation;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<ChatConversationRow>? queriedChat;
  // Stores action output result for [Backend Call - API (conversation accepted)] action in Button widget.
  ApiCallResponse? apiResultw69;
  // State field(s) for Carousel widget.
  CarouselSliderController? carouselController;
  int carouselCurrentIndex = 1;

  Completer<List<MealRow>>? requestCompleter4;
  // State field(s) for RadioButton widget.
  FormFieldController<String>? radioButtonValueController;
  Completer<List<ShoppingIngredientRow>>? requestCompleter8;
  Completer<List<ShoppingIngredientRow>>? requestCompleter5;
  Completer<List<ShoppingIngredientRow>>? requestCompleter7;
  // Models for RecipeCardMini dynamic component.
  late FlutterFlowDynamicModels<RecipeCardMiniModel> recipeCardMiniModels;
  // Model for ai_thread component.
  late AiThreadModel aiThreadModel;

  @override
  void initState(BuildContext context) {
    weightGraphModel = createModel(context, () => WeightGraphModel());
    recipeCardMiniModels =
        FlutterFlowDynamicModels(() => RecipeCardMiniModel());
    aiThreadModel = createModel(context, () => AiThreadModel());
  }

  @override
  void dispose() {
    weightGraphModel.dispose();
    recipeCardMiniModels.dispose();
    aiThreadModel.dispose();
  }

  /// Additional helper methods.
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

  Future waitForRequestCompleted6({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = requestCompleter6?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  Future waitForRequestCompleted4({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = requestCompleter4?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  String? get radioButtonValue => radioButtonValueController?.value;
  Future waitForRequestCompleted8({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = requestCompleter8?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  Future waitForRequestCompleted5({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = requestCompleter5?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  Future waitForRequestCompleted7({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = requestCompleter7?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
