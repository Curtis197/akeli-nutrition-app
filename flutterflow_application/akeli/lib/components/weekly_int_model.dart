import '/auth/firebase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/components/weeklyrecap_copy_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'weekly_int_widget.dart' show WeeklyIntWidget;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class WeeklyIntModel extends FlutterFlowModel<WeeklyIntWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for weeklyrecapCopy component.
  late WeeklyrecapCopyModel weeklyrecapCopyModel;

  @override
  void initState(BuildContext context) {
    weeklyrecapCopyModel = createModel(context, () => WeeklyrecapCopyModel());
  }

  @override
  void dispose() {
    weeklyrecapCopyModel.dispose();
  }
}
