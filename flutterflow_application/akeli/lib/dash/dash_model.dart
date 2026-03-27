import '/analytics/daily_recap_copy/daily_recap_copy_widget.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/components/daily_recap_widget.dart';
import '/components/weekly_int_copy_widget.dart';
import '/components/weekly_int_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'dash_widget.dart' show DashWidget;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DashModel extends FlutterFlowModel<DashWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ? tabBarController!.previousIndex : 0;

  // Model for dailyRecapCopy component.
  late DailyRecapCopyModel dailyRecapCopyModel;
  // Models for dailyRecap dynamic component.
  late FlutterFlowDynamicModels<DailyRecapModel> dailyRecapModels;
  // Model for weeklyInt component.
  late WeeklyIntModel weeklyIntModel;
  // Models for weeklyIntCopy dynamic component.
  late FlutterFlowDynamicModels<WeeklyIntCopyModel> weeklyIntCopyModels;

  @override
  void initState(BuildContext context) {
    dailyRecapCopyModel = createModel(context, () => DailyRecapCopyModel());
    dailyRecapModels = FlutterFlowDynamicModels(() => DailyRecapModel());
    weeklyIntModel = createModel(context, () => WeeklyIntModel());
    weeklyIntCopyModels = FlutterFlowDynamicModels(() => WeeklyIntCopyModel());
  }

  @override
  void dispose() {
    tabBarController?.dispose();
    dailyRecapCopyModel.dispose();
    dailyRecapModels.dispose();
    weeklyIntModel.dispose();
    weeklyIntCopyModels.dispose();
  }
}
