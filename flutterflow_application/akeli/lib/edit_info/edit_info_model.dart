import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/components/textfield_widget.dart';
import '/diet_plan/diet_plan_error/diet_plan_error_widget.dart';
import '/flutter_flow/flutter_flow_checkbox_group.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/backend/schema/structs/index.dart';
import '/index.dart';
import 'dart:async';
import 'edit_info_widget.dart' show EditInfoWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class EditInfoModel extends FlutterFlowModel<EditInfoWidget> {
  ///  Local state fields for this page.

  List<String> allergie = [];
  void addToAllergie(String item) => allergie.add(item);
  void removeFromAllergie(String item) => allergie.remove(item);
  void removeAtIndexFromAllergie(int index) => allergie.removeAt(index);
  void insertAtIndexInAllergie(int index, String item) =>
      allergie.insert(index, item);
  void updateAllergieAtIndex(int index, Function(String) updateFn) =>
      allergie[index] = updateFn(allergie[index]);

  double? dailyCal;

  bool error = false;

  double? totalCal;

  bool modification = false;

  bool edit = false;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Query Rows] action in EditInfo widget.
  List<UserGoalRow>? userGoal;
  // State field(s) for age widget.
  FocusNode? ageFocusNode1;
  TextEditingController? ageTextController1;
  String? Function(BuildContext, String?)? ageTextController1Validator;
  // State field(s) for age widget.
  FocusNode? ageFocusNode2;
  TextEditingController? ageTextController2;
  String? Function(BuildContext, String?)? ageTextController2Validator;
  // State field(s) for weight widget.
  FocusNode? weightFocusNode1;
  TextEditingController? weightTextController1;
  String? Function(BuildContext, String?)? weightTextController1Validator;
  // State field(s) for weight widget.
  FocusNode? weightFocusNode2;
  TextEditingController? weightTextController2;
  String? Function(BuildContext, String?)? weightTextController2Validator;
  // State field(s) for height widget.
  FocusNode? heightFocusNode1;
  TextEditingController? heightTextController1;
  String? Function(BuildContext, String?)? heightTextController1Validator;
  // State field(s) for height widget.
  FocusNode? heightFocusNode2;
  TextEditingController? heightTextController2;
  String? Function(BuildContext, String?)? heightTextController2Validator;
  // State field(s) for Gender widget.
  String? genderValue1;
  FormFieldController<String>? genderValueController1;
  // State field(s) for Gender widget.
  String? genderValue2;
  FormFieldController<String>? genderValueController2;
  // State field(s) for activityLevel widget.
  String? activityLevelValue1;
  FormFieldController<String>? activityLevelValueController1;
  // State field(s) for activityLevel widget.
  String? activityLevelValue2;
  FormFieldController<String>? activityLevelValueController2;
  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<UserHealthParameterRow>? updateHealthParameterError;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  UserHealthParameterRow? newHealthParameterError;
  Completer<List<UserHealthParameterRow>>? requestCompleter2;
  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<UserHealthParameterRow>? updateHealthParameter;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  UserHealthParameterRow? newHealthParameter;
  // State field(s) for SansViande widget.
  bool? sansViandeValue;
  // State field(s) for sansPorc widget.
  bool? sansPorcValue;
  // Models for textfield dynamic component.
  late FlutterFlowDynamicModels<TextfieldModel> textfieldModels;
  Completer<List<UserAllergiesRow>>? requestCompleter4;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController7;
  String? Function(BuildContext, String?)? textController7Validator;
  // State field(s) for favoriteRegion widget.
  FormFieldController<List<String>>? favoriteRegionValueController;
  List<String>? get favoriteRegionValues =>
      favoriteRegionValueController?.value;
  set favoriteRegionValues(List<String>? v) =>
      favoriteRegionValueController?.value = v;

  // State field(s) for ParticularDiet widget.
  FocusNode? particularDietFocusNode;
  TextEditingController? particularDietTextController;
  String? Function(BuildContext, String?)?
      particularDietTextControllerValidator;
  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<UserPreferencesRow>? updatePreferences;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  UserPreferencesRow? newPreferences;
  Completer<List<UserPreferencesRow>>? requestCompleter1;
  // State field(s) for targetWeight widget.
  FocusNode? targetWeightFocusNode1;
  TextEditingController? targetWeightTextController1;
  String? Function(BuildContext, String?)? targetWeightTextController1Validator;
  // State field(s) for targetWeight widget.
  FocusNode? targetWeightFocusNode2;
  TextEditingController? targetWeightTextController2;
  String? Function(BuildContext, String?)? targetWeightTextController2Validator;
  // State field(s) for targetTime widget.
  double? targetTimeValue;
  // State field(s) for Objectif widget.
  FocusNode? objectifFocusNode1;
  TextEditingController? objectifTextController1;
  String? Function(BuildContext, String?)? objectifTextController1Validator;
  // State field(s) for Objectif widget.
  FocusNode? objectifFocusNode2;
  TextEditingController? objectifTextController2;
  String? Function(BuildContext, String?)? objectifTextController2Validator;
  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<UserGoalRow>? updateGoalError;
  Completer<List<UserGoalRow>>? requestCompleter3;
  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<UserGoalRow>? updateGoal;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  UserGoalRow? insertGoal;
  // State field(s) for DailyCal widget.
  FocusNode? dailyCalFocusNode;
  TextEditingController? dailyCalTextController;
  String? Function(BuildContext, String?)? dailyCalTextControllerValidator;
  // State field(s) for BreakfastCal widget.
  FocusNode? breakfastCalFocusNode;
  TextEditingController? breakfastCalTextController;
  String? Function(BuildContext, String?)? breakfastCalTextControllerValidator;
  // State field(s) for LunchCal widget.
  FocusNode? lunchCalFocusNode;
  TextEditingController? lunchCalTextController;
  String? Function(BuildContext, String?)? lunchCalTextControllerValidator;
  // State field(s) for DinerCal widget.
  FocusNode? dinerCalFocusNode;
  TextEditingController? dinerCalTextController;
  String? Function(BuildContext, String?)? dinerCalTextControllerValidator;
  // State field(s) for SnackCal widget.
  FocusNode? snackCalFocusNode;
  TextEditingController? snackCalTextController;
  String? Function(BuildContext, String?)? snackCalTextControllerValidator;
  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<UserGoalRow>? updateCalGoal;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  UserGoalRow? newCalGoal;
  // Stores action output result for [Backend Call - API (diet plan)] action in Button widget.
  ApiCallResponse? dietPlan;

  @override
  void initState(BuildContext context) {
    textfieldModels = FlutterFlowDynamicModels(() => TextfieldModel());
  }

  @override
  void dispose() {
    ageFocusNode1?.dispose();
    ageTextController1?.dispose();

    ageFocusNode2?.dispose();
    ageTextController2?.dispose();

    weightFocusNode1?.dispose();
    weightTextController1?.dispose();

    weightFocusNode2?.dispose();
    weightTextController2?.dispose();

    heightFocusNode1?.dispose();
    heightTextController1?.dispose();

    heightFocusNode2?.dispose();
    heightTextController2?.dispose();

    textfieldModels.dispose();
    textFieldFocusNode?.dispose();
    textController7?.dispose();

    particularDietFocusNode?.dispose();
    particularDietTextController?.dispose();

    targetWeightFocusNode1?.dispose();
    targetWeightTextController1?.dispose();

    targetWeightFocusNode2?.dispose();
    targetWeightTextController2?.dispose();

    objectifFocusNode1?.dispose();
    objectifTextController1?.dispose();

    objectifFocusNode2?.dispose();
    objectifTextController2?.dispose();

    dailyCalFocusNode?.dispose();
    dailyCalTextController?.dispose();

    breakfastCalFocusNode?.dispose();
    breakfastCalTextController?.dispose();

    lunchCalFocusNode?.dispose();
    lunchCalTextController?.dispose();

    dinerCalFocusNode?.dispose();
    dinerCalTextController?.dispose();

    snackCalFocusNode?.dispose();
    snackCalTextController?.dispose();
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
}
