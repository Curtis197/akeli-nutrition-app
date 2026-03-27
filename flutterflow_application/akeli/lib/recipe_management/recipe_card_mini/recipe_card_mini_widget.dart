import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'recipe_card_mini_model.dart';
export 'recipe_card_mini_model.dart';

class RecipeCardMiniWidget extends StatefulWidget {
  const RecipeCardMiniWidget({
    super.key,
    required this.recipe,
  });

  final ReceipeRow? recipe;

  @override
  State<RecipeCardMiniWidget> createState() => _RecipeCardMiniWidgetState();
}

class _RecipeCardMiniWidgetState extends State<RecipeCardMiniWidget> {
  late RecipeCardMiniModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RecipeCardMiniModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () async {
        logFirebaseEvent('RECIPE_CARD_MINI_Container_kdp4lv68_ON_T');
        logFirebaseEvent('Container_navigate_to');

        context.pushNamed(
          ReceipeDetailWidget.routeName,
          queryParameters: {
            'receipeID': serializeParam(
              widget!.recipe?.id,
              ParamType.int,
            ),
          }.withoutNulls,
        );
      },
      child: Container(
        width: 200.0,
        height: 175.0,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: FlutterFlowTheme.of(context).alternate,
            width: 1.0,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<List<ReceipeImageRow>>(
                future: ReceipeImageTable().querySingleRow(
                  queryFn: (q) => q
                      .eqOrNull(
                        'receipe_id',
                        widget!.recipe?.id,
                      )
                      .eqOrNull(
                        'type',
                        'main',
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
                  List<ReceipeImageRow> imageReceipeImageRowList =
                      snapshot.data!;

                  final imageReceipeImageRow =
                      imageReceipeImageRowList.isNotEmpty
                          ? imageReceipeImageRowList.first
                          : null;

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Image.network(
                      valueOrDefault<String>(
                        imageReceipeImageRow?.url,
                        'https://images.unsplash.com/photo-1470162656305-6f429ba817bf?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHNlYXJjaHwyMnx8dGVhfGVufDB8fHx8MTcwNjU2MTE2OHww&ixlib=rb-4.0.3&q=80&w=400',
                      ),
                      width: double.infinity,
                      height: 100.0,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
              Padding(
                padding: EdgeInsets.all(4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            valueOrDefault<String>(
                              widget!.recipe?.name,
                              'Nom de la recette',
                            ),
                            maxLines: 1,
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ].divide(SizedBox(height: 8.0)),
          ),
        ),
      ),
    );
  }
}
