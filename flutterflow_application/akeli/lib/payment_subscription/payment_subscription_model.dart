import '/auth/firebase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'payment_subscription_widget.dart' show PaymentSubscriptionWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PaymentSubscriptionModel
    extends FlutterFlowModel<PaymentSubscriptionWidget> {
  ///  Local state fields for this page.

  bool subbed = true;

  bool suppressAccount = false;

  bool cancelSubscription = false;

  bool getSubscription = false;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Query Rows] action in paymentSubscription widget.
  List<UsersRow>? userData;
  // State field(s) for CheckboxListTile widget.
  bool? checkboxListTileValue1;
  // State field(s) for CheckboxListTile widget.
  bool? checkboxListTileValue2;
  // State field(s) for CheckboxListTile widget.
  bool? checkboxListTileValue3;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
