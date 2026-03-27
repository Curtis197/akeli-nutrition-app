import '/auth/firebase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/components/weeklyrecap_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'weekly_int_copy_widget.dart' show WeeklyIntCopyWidget;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class WeeklyIntCopyModel extends FlutterFlowModel<WeeklyIntCopyWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for weeklyrecap component.
  late WeeklyrecapModel weeklyrecapModel;

  @override
  void initState(BuildContext context) {
    weeklyrecapModel = createModel(context, () => WeeklyrecapModel());
  }

  @override
  void dispose() {
    weeklyrecapModel.dispose();
  }
}
