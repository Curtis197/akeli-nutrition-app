import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import 'group_creation_widget.dart' show GroupCreationWidget;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class GroupCreationModel extends FlutterFlowModel<GroupCreationWidget> {
  ///  Local state fields for this component.

  String image = 'https://picsum.photos/seed/425/600';

  ///  State fields for stateful widgets in this component.

  // State field(s) for goup_name widget.
  FocusNode? goupNameFocusNode;
  TextEditingController? goupNameTextController;
  String? Function(BuildContext, String?)? goupNameTextControllerValidator;
  // State field(s) for group_description widget.
  FocusNode? groupDescriptionFocusNode;
  TextEditingController? groupDescriptionTextController;
  String? Function(BuildContext, String?)?
      groupDescriptionTextControllerValidator;
  bool isDataUploading_uploadDataHts = false;
  FFUploadedFile uploadedLocalFile_uploadDataHts =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  ChatConversationRow? newChatConversation;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  ConversationGroupRow? newChatConversationGroup;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  ConversationParticipantRow? newChatConversationParticipant;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    goupNameFocusNode?.dispose();
    goupNameTextController?.dispose();

    groupDescriptionFocusNode?.dispose();
    groupDescriptionTextController?.dispose();
  }
}
