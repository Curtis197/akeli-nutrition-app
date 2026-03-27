import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/supabase/supabase.dart';
import '/components/meal_plan_error_widget.dart';
import '/components/textfield_widget.dart';
import '/diet_plan/diet_plan_error/diet_plan_error_widget.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_radio_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/backend/schema/structs/index.dart';
import '/index.dart';
import 'dart:async';
import 'inscriptionpage_widget.dart' show InscriptionpageWidget;
import 'package:smooth_page_indicator/smooth_page_indicator.dart'
    as smooth_page_indicator;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class InscriptionpageModel extends FlutterFlowModel<InscriptionpageWidget> {
  ///  Local state fields for this page.

  bool edit = false;

  String? riskLevel;

  String? riskMessgae;

  int? time;

  double? weeklyLoss;

  int? age;

  int? height;

  int? weight;

  ///  State fields for stateful widgets in this page.

  // State field(s) for PageView widget.
  PageController? pageViewController;

  int get pageViewCurrentIndex => pageViewController != null &&
          pageViewController!.hasClients &&
          pageViewController!.page != null
      ? pageViewController!.page!.round()
      : 0;
  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  // State field(s) for CheckboxRGPD widget.
  bool? checkboxRGPDValue;
  // State field(s) for CheckboxCGU widget.
  bool? checkboxCGUValue;
  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<UsersRow>? usersUpdateCguConfidentiality;
  // State field(s) for name widget.
  FocusNode? nameFocusNode;
  TextEditingController? nameTextController;
  String? Function(BuildContext, String?)? nameTextControllerValidator;
  // State field(s) for age widget.
  FocusNode? ageFocusNode;
  TextEditingController? ageTextController;
  String? Function(BuildContext, String?)? ageTextControllerValidator;
  // State field(s) for sexe widget.
  String? sexeValue;
  FormFieldController<String>? sexeValueController;
  // State field(s) for weight widget.
  FocusNode? weightFocusNode;
  TextEditingController? weightTextController;
  String? Function(BuildContext, String?)? weightTextControllerValidator;
  // State field(s) for height widget.
  FocusNode? heightFocusNode;
  TextEditingController? heightTextController;
  String? Function(BuildContext, String?)? heightTextControllerValidator;
  // State field(s) for activity widget.
  FormFieldController<String>? activityValueController;
  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<UserHealthParameterRow>? updatedHealthParameter;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  UserHealthParameterRow? newHealthParameter;
  // State field(s) for targetWeight widget.
  FocusNode? targetWeightFocusNode;
  TextEditingController? targetWeightTextController;
  String? Function(BuildContext, String?)? targetWeightTextControllerValidator;
  // Stores action output result for [Backend Call - API (calculate regime time)] action in targetWeight widget.
  ApiCallResponse? recommandedWeight;
  // Stores action output result for [Backend Call - API (calculate regime time)] action in targetWeight widget.
  ApiCallResponse? recommandedWeight2;
  // State field(s) for time widget.
  double? timeValue;
  // Stores action output result for [Backend Call - API (calculate regime time)] action in time widget.
  ApiCallResponse? modificationWeight;
  // State field(s) for motivation widget.
  FocusNode? motivationFocusNode;
  TextEditingController? motivationTextController;
  String? Function(BuildContext, String?)? motivationTextControllerValidator;
  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<UserGoalRow>? updatedGoal;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  UserGoalRow? newGoal;
  // State field(s) for CheckboxListTile widget.
  bool? checkboxListTileValue;
  // State field(s) for sans_viande widget.
  bool? sansViandeValue;
  // Models for textfield dynamic component.
  late FlutterFlowDynamicModels<TextfieldModel> textfieldModels;
  Completer<List<UserAllergiesRow>>? requestCompleter;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController7;
  String? Function(BuildContext, String?)? textController7Validator;
  // State field(s) for foodRegion widget.
  FormFieldController<String>? foodRegionValueController;
  // State field(s) for regimeparticulier widget.
  FocusNode? regimeparticulierFocusNode;
  TextEditingController? regimeparticulierTextController;
  String? Function(BuildContext, String?)?
      regimeparticulierTextControllerValidator;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  UserPreferencesRow? newPreference;
  // Stores action output result for [Backend Call - API (diet plan)] action in Button widget.
  ApiCallResponse? dietPlan;
  // Stores action output result for [Backend Call - API (personal meal plan)] action in Button widget.
  ApiCallResponse? apiResultgee;

  @override
  void initState(BuildContext context) {
    textfieldModels = FlutterFlowDynamicModels(() => TextfieldModel());
  }

  @override
  void dispose() {
    nameFocusNode?.dispose();
    nameTextController?.dispose();

    ageFocusNode?.dispose();
    ageTextController?.dispose();

    weightFocusNode?.dispose();
    weightTextController?.dispose();

    heightFocusNode?.dispose();
    heightTextController?.dispose();

    targetWeightFocusNode?.dispose();
    targetWeightTextController?.dispose();

    motivationFocusNode?.dispose();
    motivationTextController?.dispose();

    textfieldModels.dispose();
    textFieldFocusNode?.dispose();
    textController7?.dispose();

    regimeparticulierFocusNode?.dispose();
    regimeparticulierTextController?.dispose();
  }

  /// Additional helper methods.
  String? get activityValue => activityValueController?.value;
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

  String? get foodRegionValue => foodRegionValueController?.value;
}
