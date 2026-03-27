import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/components/oredering_selector_widget.dart';
import '/components/tag_and_or_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/recipe_management/recipe_card_j_s_o_n_copy/recipe_card_j_s_o_n_copy_widget.dart';
import '/recipe_management/recipe_filters_copy/recipe_filters_copy_widget.dart';
import 'dart:ui';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import 'recipe_researching_list_widget.dart' show RecipeResearchingListWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class RecipeResearchingListModel
    extends FlutterFlowModel<RecipeResearchingListWidget> {
  ///  Local state fields for this page.

  bool orderMenu = false;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (updated recipe research)] action in recipeResearchingList widget.
  ApiCallResponse? requestReceipePage;
  // State field(s) for name widget.
  FocusNode? nameFocusNode;
  TextEditingController? nameTextController;
  String? Function(BuildContext, String?)? nameTextControllerValidator;
  // Stores action output result for [Backend Call - API (updated recipe research)] action in name widget.
  ApiCallResponse? requestReceipeName;
  // Model for orederingSelector component.
  late OrederingSelectorModel orederingSelectorModel;
  // Stores action output result for [Backend Call - API (updated recipe research)] action in Icon widget.
  ApiCallResponse? requestReceipeClearTag;
  // Stores action output result for [Backend Call - API (request body)] action in Icon widget.
  ApiCallResponse? bodyClearTag;
  // Model for TagAndOr component.
  late TagAndOrModel tagAndOrModel;
  // Stores action output result for [Backend Call - API (updated recipe research)] action in TagAndOr widget.
  ApiCallResponse? requestReceipe;
  // Stores action output result for [Backend Call - API (updated recipe research)] action in Container widget.
  ApiCallResponse? requestReceipeTag;
  // Models for RecipeCardJSONCopy dynamic component.
  late FlutterFlowDynamicModels<RecipeCardJSONCopyModel>
      recipeCardJSONCopyModels;

  @override
  void initState(BuildContext context) {
    orederingSelectorModel =
        createModel(context, () => OrederingSelectorModel());
    tagAndOrModel = createModel(context, () => TagAndOrModel());
    recipeCardJSONCopyModels =
        FlutterFlowDynamicModels(() => RecipeCardJSONCopyModel());
  }

  @override
  void dispose() {
    nameFocusNode?.dispose();
    nameTextController?.dispose();

    orederingSelectorModel.dispose();
    tagAndOrModel.dispose();
    recipeCardJSONCopyModels.dispose();
  }
}
