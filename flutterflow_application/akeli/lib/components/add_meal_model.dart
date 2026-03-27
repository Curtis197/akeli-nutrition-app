import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/index.dart';
import 'add_meal_widget.dart' show AddMealWidget;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AddMealModel extends FlutterFlowModel<AddMealWidget> {
  ///  Local state fields for this component.

  bool imageEdit = false;

  ///  State fields for stateful widgets in this component.

  bool isDataUploading_customMealImage = false;
  FFUploadedFile uploadedLocalFile_customMealImage =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  bool isDataUploading_uploadDataY65 = false;
  FFUploadedFile uploadedLocalFile_uploadDataY65 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataY65 = '';

  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<MealRow>? querriedMeal;
  // Stores action output result for [Backend Call - API (image recognition)] action in Button widget.
  ApiCallResponse? customMeal;
  // Stores action output result for [Backend Call - API (meal plan shopping list)] action in Button widget.
  ApiCallResponse? updatedShopList;
  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<MealRow>? updatedMEal;
  // Stores action output result for [Backend Call - API (custom meal)] action in Button widget.
  ApiCallResponse? customMeal2;
  // Stores action output result for [Backend Call - API (meal plan shopping list)] action in Button widget.
  ApiCallResponse? updatedShopList2;
  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<MealRow>? updatedMeal2;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
