import '/a_i_assistant/ai_chat/ai_chat_widget.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'ai_thread_model.dart';
export 'ai_thread_model.dart';

class AiThreadWidget extends StatefulWidget {
  const AiThreadWidget({
    super.key,
    bool? parameter2,
    required this.users,
  }) : this.parameter2 = parameter2 ?? false;

  final bool parameter2;
  final UsersRow? users;

  @override
  State<AiThreadWidget> createState() => _AiThreadWidgetState();
}

class _AiThreadWidgetState extends State<AiThreadWidget> {
  late AiThreadModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AiThreadModel());

    // On component load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      logFirebaseEvent('AI_THREAD_COMP_ai_thread_ON_INIT_STATE');
      if (!(_model.listMessage.isNotEmpty)) {
        logFirebaseEvent('ai_thread_backend_call');
        _model.getMessage = await SupabaseGroup.getAiMessageCall.call(
          userId: valueOrDefault(currentUserDocument?.id, 0),
        );

        logFirebaseEvent('ai_thread_update_component_state');
        _model.listMessage = SupabaseGroup.getAiMessageCall
            .listMessage(
              (_model.getMessage?.jsonBody ?? ''),
            )!
            .toList()
            .cast<dynamic>();
        safeSetState(() {});
      }
    });

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Visibility(
      visible: widget!.parameter2,
      child: Align(
        alignment: AlignmentDirectional(1.0, 1.0),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 15.0, 120.0),
          child: FutureBuilder<List<ConversationRow>>(
            future: ConversationTable().querySingleRow(
              queryFn: (q) => q.eqOrNull(
                'user_id',
                widget!.users?.id,
              ),
            ),
            builder: (context, snapshot) {
              // Customize what your widget looks like when it's loading.
              if (!snapshot.hasData) {
                return Center(
                  child: SizedBox(
                    width: 50.0,
                    height: 50.0,
                    child: SpinKitDoubleBounce(
                      color: FlutterFlowTheme.of(context).tertiary,
                      size: 50.0,
                    ),
                  ),
                );
              }
              List<ConversationRow> containerConversationRowList =
                  snapshot.data!;

              final containerConversationRow =
                  containerConversationRowList.isNotEmpty
                      ? containerConversationRowList.first
                      : null;

              return Container(
                width: 275.0,
                height: 400.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).alternate,
                  borderRadius: BorderRadius.circular(15.0),
                ),
                alignment: AlignmentDirectional(0.0, 1.0),
                child: Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(10.0, 15.0, 10.0, 15.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final aIChatMesage = _model.listMessage.toList();

                            return ListView.builder(
                              padding: EdgeInsets.zero,
                              reverse: true,
                              primary: false,
                              shrinkWrap: true,
                              scrollDirection: Axis.vertical,
                              itemCount: aIChatMesage.length,
                              itemBuilder: (context, aIChatMesageIndex) {
                                final aIChatMesageItem =
                                    aIChatMesage[aIChatMesageIndex];
                                return wrapWithModel(
                                  model: _model.aiChatModels.getModel(
                                    aIChatMesageItem.toString(),
                                    aIChatMesageIndex,
                                  ),
                                  updateCallback: () => safeSetState(() {}),
                                  child: AiChatWidget(
                                    key: Key(
                                      'Keydjq_${aIChatMesageItem.toString()}',
                                    ),
                                    messageJSON: aIChatMesageItem,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  8.0, 0.0, 8.0, 0.0),
                              child: TextFormField(
                                controller: _model.textController,
                                focusNode: _model.textFieldFocusNode,
                                autofocus: true,
                                obscureText: false,
                                decoration: InputDecoration(
                                  labelText:
                                      FFLocalizations.of(context).getText(
                                    'xrgsrj8p' /* Poser une question */,
                                  ),
                                  labelStyle: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                        ),
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                  hintStyle: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                        ),
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0x00000000),
                                      width: 0.0,
                                    ),
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      width: 0.0,
                                    ),
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).error,
                                      width: 0.0,
                                    ),
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).error,
                                      width: 0.0,
                                    ),
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  filled: true,
                                  fillColor: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.poppins(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                maxLines: null,
                                validator: _model.textControllerValidator
                                    .asValidator(context),
                              ),
                            ),
                          ),
                          Container(
                            width: 50.0,
                            height: 50.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).secondary,
                              borderRadius: BorderRadius.circular(50.0),
                            ),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                logFirebaseEvent(
                                    'AI_THREAD_COMP_Icon_b9v6f1jd_ON_TAP');
                                logFirebaseEvent('Icon_update_component_state');
                                _model.insertAtIndexInListMessage(
                                    0,
                                    functions.aiMessageJON(
                                        _model.textController.text,
                                        'user',
                                        getCurrentTimestamp,
                                        'send')!);
                                _model.buttonOn = false;
                                safeSetState(() {});
                                logFirebaseEvent('Icon_update_component_state');
                                _model.insertAtIndexInListMessage(
                                    0,
                                    functions.aiMessageJON(
                                        _model.textController.text,
                                        'assistant',
                                        getCurrentTimestamp,
                                        'pending')!);
                                safeSetState(() {});
                                await Future.wait([
                                  Future(() async {
                                    logFirebaseEvent('Icon_backend_call');
                                    _model.aiMessage =
                                        await AIassistantCall.call(
                                      userContextJson: FFAppState().userContext,
                                      message: _model.textController.text,
                                      userId: valueOrDefault(
                                          currentUserDocument?.id, 0),
                                      conversationId:
                                          FFAppState().conversationId,
                                      listMesagesJson:
                                          functions.restrictListJson(
                                              _model.listMessage.toList()),
                                    );

                                    if ((_model.aiMessage?.succeeded ?? true)) {
                                      logFirebaseEvent(
                                          'Icon_update_component_state');
                                      _model.updateListMessageAtIndex(
                                        0,
                                        (_) => functions.aiMessageJON(
                                            AIassistantCall.reply(
                                              (_model.aiMessage?.jsonBody ??
                                                  ''),
                                            ),
                                            'assistant',
                                            getCurrentTimestamp,
                                            'send')!,
                                      );
                                      _model.buttonOn = true;
                                      safeSetState(() {});
                                    }
                                  }),
                                  Future(() async {
                                    logFirebaseEvent(
                                        'Icon_clear_text_fields_pin_codes');
                                    safeSetState(() {
                                      _model.textController?.clear();
                                    });
                                  }),
                                ]);

                                safeSetState(() {});
                              },
                              child: Icon(
                                Icons.send_rounded,
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                size: 26.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
