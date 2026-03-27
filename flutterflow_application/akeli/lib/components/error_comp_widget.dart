import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'error_comp_model.dart';
export 'error_comp_model.dart';

class ErrorCompWidget extends StatefulWidget {
  const ErrorCompWidget({
    super.key,
    required this.errorContent,
    required this.functionName,
  });

  final dynamic errorContent;
  final String? functionName;

  @override
  State<ErrorCompWidget> createState() => _ErrorCompWidgetState();
}

class _ErrorCompWidgetState extends State<ErrorCompWidget> {
  late ErrorCompModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ErrorCompModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0.0),
          bottomRight: Radius.circular(0.0),
          topLeft: Radius.circular(12.0),
          topRight: Radius.circular(12.0),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(10.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: 50.0,
              height: 5.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).alternate,
                borderRadius: BorderRadius.circular(50.0),
              ),
            ),
            Text(
              FFLocalizations.of(context).getText(
                '8awx5h2q' /* Error */,
              ),
              style: FlutterFlowTheme.of(context).headlineLarge.override(
                    font: GoogleFonts.outfit(
                      fontWeight:
                          FlutterFlowTheme.of(context).headlineLarge.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).headlineLarge.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).error,
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).headlineLarge.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).headlineLarge.fontStyle,
                  ),
            ),
            Text(
              valueOrDefault<String>(
                widget!.functionName,
                'function name',
              ),
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.poppins(
                      fontWeight:
                          FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
            ),
            Text(
              valueOrDefault<String>(
                widget!.errorContent?.toString(),
                'no error',
              ),
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.poppins(
                      fontWeight:
                          FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
            ),
          ].divide(SizedBox(height: 10.0)),
        ),
      ),
    );
  }
}
