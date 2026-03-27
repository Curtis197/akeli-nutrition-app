import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'tag_and_or_widget.dart' show TagAndOrWidget;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class TagAndOrModel extends FlutterFlowModel<TagAndOrWidget> {
  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - API (updated recipe research)] action in Row widget.
  ApiCallResponse? requestReceipeTagOR;
  // Stores action output result for [Backend Call - API (updated recipe research)] action in Row widget.
  ApiCallResponse? requestReceipeTagAND;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
