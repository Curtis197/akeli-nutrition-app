import '/auth/firebase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/components/notification_chat_widget.dart';
import '/components/notification_demand_widget.dart';
import '/components/notification_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'notifications_widget.dart' show NotificationsWidget;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class NotificationsModel extends FlutterFlowModel<NotificationsWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ? tabBarController!.previousIndex : 0;

  // Models for notification dynamic component.
  late FlutterFlowDynamicModels<NotificationModel> notificationModels;
  // Models for notification_chat dynamic component.
  late FlutterFlowDynamicModels<NotificationChatModel> notificationChatModels;
  // Models for notification_demand dynamic component.
  late FlutterFlowDynamicModels<NotificationDemandModel>
      notificationDemandModels;

  @override
  void initState(BuildContext context) {
    notificationModels = FlutterFlowDynamicModels(() => NotificationModel());
    notificationChatModels =
        FlutterFlowDynamicModels(() => NotificationChatModel());
    notificationDemandModels =
        FlutterFlowDynamicModels(() => NotificationDemandModel());
  }

  @override
  void dispose() {
    tabBarController?.dispose();
    notificationModels.dispose();
    notificationChatModels.dispose();
    notificationDemandModels.dispose();
  }
}
