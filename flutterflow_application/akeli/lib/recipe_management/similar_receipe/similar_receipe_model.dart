import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/recipe_management/recipe_card_mini/recipe_card_mini_widget.dart';
import 'dart:ui';
import 'dart:async';
import 'similar_receipe_widget.dart' show SimilarReceipeWidget;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SimilarReceipeModel extends FlutterFlowModel<SimilarReceipeWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for ChoiceChips widget.
  FormFieldController<List<String>>? choiceChipsValueController;
  String? get choiceChipsValue =>
      choiceChipsValueController?.value?.firstOrNull;
  set choiceChipsValue(String? val) =>
      choiceChipsValueController?.value = val != null ? [val] : [];
  Completer<List<ReceipeTagsRow>>? requestCompleter;
  // Models for RecipeCardMini dynamic component.
  late FlutterFlowDynamicModels<RecipeCardMiniModel> recipeCardMiniModels;

  @override
  void initState(BuildContext context) {
    recipeCardMiniModels =
        FlutterFlowDynamicModels(() => RecipeCardMiniModel());
  }

  @override
  void dispose() {
    recipeCardMiniModels.dispose();
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
}
