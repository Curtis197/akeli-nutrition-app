import '/auth/firebase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'chat_widget.dart' show ChatWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ChatModel extends FlutterFlowModel<ChatWidget> {
  ///  Local state fields for this component.

  List<int> readBy = [];
  void addToReadBy(int item) => readBy.add(item);
  void removeFromReadBy(int item) => readBy.remove(item);
  void removeAtIndexFromReadBy(int index) => readBy.removeAt(index);
  void insertAtIndexInReadBy(int index, int item) => readBy.insert(index, item);
  void updateReadByAtIndex(int index, Function(int) updateFn) =>
      readBy[index] = updateFn(readBy[index]);

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - Delete Row(s)] action in chat widget.
  List<ChatNotificationsRow>? deleteNotification;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
