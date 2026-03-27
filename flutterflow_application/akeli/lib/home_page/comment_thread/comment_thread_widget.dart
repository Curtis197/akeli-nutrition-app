import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/home_page/comment/comment_widget.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'comment_thread_model.dart';
export 'comment_thread_model.dart';

class CommentThreadWidget extends StatefulWidget {
  const CommentThreadWidget({
    super.key,
    required this.receipe,
  });

  final ReceipeRow? receipe;

  @override
  State<CommentThreadWidget> createState() => _CommentThreadWidgetState();
}

class _CommentThreadWidgetState extends State<CommentThreadWidget> {
  late CommentThreadModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CommentThreadModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(0.0),
            bottomRight: Radius.circular(0.0),
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: 100.0,
                height: 7.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).alternate,
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              Text(
                FFLocalizations.of(context).getText(
                  'h2s0jdcf' /* Comments */,
                ),
                style: FlutterFlowTheme.of(context).labelLarge.override(
                      font: GoogleFonts.poppins(
                        fontWeight:
                            FlutterFlowTheme.of(context).labelLarge.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).labelLarge.fontStyle,
                      ),
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).labelLarge.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelLarge.fontStyle,
                    ),
              ),
              FutureBuilder<List<ReceipeCommentsRow>>(
                future: ReceipeCommentsTable().queryRows(
                  queryFn: (q) => q.eqOrNull(
                    'receipe_id',
                    widget!.receipe?.id,
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
                  List<ReceipeCommentsRow> listViewReceipeCommentsRowList =
                      snapshot.data!;

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    primary: false,
                    shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    itemCount: listViewReceipeCommentsRowList.length,
                    itemBuilder: (context, listViewIndex) {
                      final listViewReceipeCommentsRow =
                          listViewReceipeCommentsRowList[listViewIndex];
                      return wrapWithModel(
                        model: _model.commentModels.getModel(
                          listViewReceipeCommentsRow.id.toString(),
                          listViewIndex,
                        ),
                        updateCallback: () => safeSetState(() {}),
                        child: CommentWidget(
                          key: Key(
                            'Keydgc_${listViewReceipeCommentsRow.id.toString()}',
                          ),
                          receipeComment: listViewReceipeCommentsRow,
                        ),
                      );
                    },
                  );
                },
              ),
            ].divide(SizedBox(height: 15.0)).addToStart(SizedBox(height: 20.0)),
          ),
        ),
      ),
    );
  }
}
