import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_checkbox_group.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/recipe_management/type_and_or/type_and_or_widget.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'recipe_filters_widget.dart' show RecipeFiltersWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class RecipeFiltersModel extends FlutterFlowModel<RecipeFiltersWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for calMin widget.
  FocusNode? calMinFocusNode;
  TextEditingController? calMinTextController;
  String? Function(BuildContext, String?)? calMinTextControllerValidator;
  // State field(s) for calMax widget.
  FocusNode? calMaxFocusNode;
  TextEditingController? calMaxTextController;
  String? Function(BuildContext, String?)? calMaxTextControllerValidator;
  // State field(s) for sansPorc widget.
  FormFieldController<List<String>>? sansPorcValueController;
  List<String>? get sansPorcValues => sansPorcValueController?.value;
  set sansPorcValues(List<String>? v) => sansPorcValueController?.value = v;

  // Model for TypeAndOr component.
  late TypeAndOrModel typeAndOrModel;
  // State field(s) for type widget.
  FormFieldController<List<String>>? typeValueController;
  List<String>? get typeValues => typeValueController?.value;
  set typeValues(List<String>? v) => typeValueController?.value = v;

  // State field(s) for difficulty widget.
  FormFieldController<List<String>>? difficultyValueController;
  List<String>? get difficultyValues => difficultyValueController?.value;
  set difficultyValues(List<String>? v) => difficultyValueController?.value = v;

  // State field(s) for FoodRegion widget.
  FormFieldController<List<String>>? foodRegionValueController;
  List<String>? get foodRegionValues => foodRegionValueController?.value;
  set foodRegionValues(List<String>? v) => foodRegionValueController?.value = v;

  // State field(s) for cookingTime widget.
  FocusNode? cookingTimeFocusNode1;
  TextEditingController? cookingTimeTextController1;
  String? Function(BuildContext, String?)? cookingTimeTextController1Validator;
  // State field(s) for cookingTime widget.
  FocusNode? cookingTimeFocusNode2;
  TextEditingController? cookingTimeTextController2;
  String? Function(BuildContext, String?)? cookingTimeTextController2Validator;
  // Stores action output result for [Backend Call - API (updated recipe research)] action in Button widget.
  ApiCallResponse? requestReceipe;

  @override
  void initState(BuildContext context) {
    typeAndOrModel = createModel(context, () => TypeAndOrModel());
  }

  @override
  void dispose() {
    calMinFocusNode?.dispose();
    calMinTextController?.dispose();

    calMaxFocusNode?.dispose();
    calMaxTextController?.dispose();

    typeAndOrModel.dispose();
    cookingTimeFocusNode1?.dispose();
    cookingTimeTextController1?.dispose();

    cookingTimeFocusNode2?.dispose();
    cookingTimeTextController2?.dispose();
  }
}
