import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/backend/schema/structs/index.dart';
import '/index.dart';
import 'add_new_meal_widget.dart' show AddNewMealWidget;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AddNewMealModel extends FlutterFlowModel<AddNewMealWidget> {
  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - API (add a new meal)] action in Button widget.
  ApiCallResponse? newMeal1;
  // Stores action output result for [Backend Call - API (meal ingredients scale)] action in Button widget.
  ApiCallResponse? mealScaled;
  // Stores action output result for [Backend Call - API (shopping list)] action in Button widget.
  ApiCallResponse? shoppingList;
  // State field(s) for MealType widget.
  String? mealTypeValue;
  FormFieldController<String>? mealTypeValueController;
  // State field(s) for MeaDay widget.
  String? meaDayValue;
  FormFieldController<String>? meaDayValueController;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<MealPlanRow>? snackMealPlan;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<MealRow>? mappedSnack;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  MealRow? newSnackMeal;
  // Stores action output result for [Backend Call - API (add a new meal)] action in Button widget.
  ApiCallResponse? updatedSnack;
  // Stores action output result for [Backend Call - API (meal ingredients scale)] action in Button widget.
  ApiCallResponse? scaledSnack;
  // Stores action output result for [Backend Call - API (meal plan shopping list)] action in Button widget.
  ApiCallResponse? addedShoppingList;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<MealPlanRow>? mealPlan;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<MealRow>? meal;
  // Stores action output result for [Backend Call - API (add a new meal)] action in Button widget.
  ApiCallResponse? updatedMeal;
  // Stores action output result for [Backend Call - API (meal ingredients scale)] action in Button widget.
  ApiCallResponse? updateMealIngredients;
  // Stores action output result for [Backend Call - API (shopping list)] action in Button widget.
  ApiCallResponse? updatedShoppingList;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
