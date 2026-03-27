import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/home_page/comment/comment_widget.dart';
import 'dart:ui';
import 'comment_thread_widget.dart' show CommentThreadWidget;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CommentThreadModel extends FlutterFlowModel<CommentThreadWidget> {
  ///  State fields for stateful widgets in this component.

  // Models for comment dynamic component.
  late FlutterFlowDynamicModels<CommentModel> commentModels;

  @override
  void initState(BuildContext context) {
    commentModels = FlutterFlowDynamicModels(() => CommentModel());
  }

  @override
  void dispose() {
    commentModels.dispose();
  }
}
