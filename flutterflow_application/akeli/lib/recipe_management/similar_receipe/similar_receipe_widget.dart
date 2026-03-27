import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/recipe_management/recipe_card_mini/recipe_card_mini_widget.dart';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'similar_receipe_model.dart';
export 'similar_receipe_model.dart';

class SimilarReceipeWidget extends StatefulWidget {
  const SimilarReceipeWidget({
    super.key,
    required this.receipeID,
  });

  final int? receipeID;

  @override
  State<SimilarReceipeWidget> createState() => _SimilarReceipeWidgetState();
}

class _SimilarReceipeWidgetState extends State<SimilarReceipeWidget> {
  late SimilarReceipeModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SimilarReceipeModel());

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
      width: MediaQuery.sizeOf(context).width * 1.0,
      decoration: BoxDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            FFLocalizations.of(context).getText(
              'mcxjkote' /* Recette similaire */,
            ),
            style: FlutterFlowTheme.of(context).titleLarge.override(
                  font: GoogleFonts.outfit(
                    fontWeight:
                        FlutterFlowTheme.of(context).titleLarge.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleLarge.fontStyle,
                  ),
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).titleLarge.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).titleLarge.fontStyle,
                ),
          ),
          FutureBuilder<List<ReceipeTagsRow>>(
            future: ReceipeTagsTable().queryRows(
              queryFn: (q) => q.eqOrNull(
                'receipe_id',
                widget!.receipeID,
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
              List<ReceipeTagsRow> containerReceipeTagsRowList = snapshot.data!;

              return Container(
                decoration: BoxDecoration(),
                child: Visibility(
                  visible: containerReceipeTagsRowList.isNotEmpty,
                  child: FlutterFlowChoiceChips(
                    options: containerReceipeTagsRowList
                        .map((e) => e.name)
                        .withoutNulls
                        .toList()
                        .map((label) => ChipData(label))
                        .toList(),
                    onChanged: (val) async {
                      safeSetState(
                          () => _model.choiceChipsValue = val?.firstOrNull);
                      logFirebaseEvent(
                          'SIMILAR_RECEIPE_ChoiceChips_5e6e2bcv_ON_');
                      logFirebaseEvent('ChoiceChips_refresh_database_request');
                      safeSetState(() => _model.requestCompleter = null);
                      await _model.waitForRequestCompleted();
                    },
                    selectedChipStyle: ChipStyle(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      textStyle:
                          FlutterFlowTheme.of(context).bodyMedium.override(
                                font: GoogleFonts.poppins(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                                color: FlutterFlowTheme.of(context).info,
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                      iconColor: FlutterFlowTheme.of(context).info,
                      iconSize: 16.0,
                      elevation: 0.0,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    unselectedChipStyle: ChipStyle(
                      backgroundColor:
                          FlutterFlowTheme.of(context).secondaryBackground,
                      textStyle: FlutterFlowTheme.of(context)
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
                            color: FlutterFlowTheme.of(context).secondaryText,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                      iconColor: FlutterFlowTheme.of(context).secondaryText,
                      iconSize: 16.0,
                      elevation: 0.0,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    chipSpacing: 8.0,
                    rowSpacing: 8.0,
                    multiselect: false,
                    initialized: _model.choiceChipsValue != null,
                    alignment: WrapAlignment.start,
                    controller: _model.choiceChipsValueController ??=
                        FormFieldController<List<String>>(
                      [
                        containerReceipeTagsRowList.isNotEmpty
                            ? containerReceipeTagsRowList.firstOrNull!.name!
                            : ''
                      ],
                    ),
                    wrapped: true,
                  ),
                ),
              );
            },
          ),
          if (_model.choiceChipsValue != null && _model.choiceChipsValue != '')
            FutureBuilder<List<ReceipeTagsRow>>(
              future:
                  (_model.requestCompleter ??= Completer<List<ReceipeTagsRow>>()
                        ..complete(ReceipeTagsTable().queryRows(
                          queryFn: (q) => q.eqOrNull(
                            'name',
                            valueOrDefault<String>(
                              _model.choiceChipsValue,
                              'none',
                            ),
                          ),
                        )))
                      .future,
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
                List<ReceipeTagsRow> rowReceipeTagsRowList = snapshot.data!;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children:
                        List.generate(rowReceipeTagsRowList.length, (rowIndex) {
                      final rowReceipeTagsRow = rowReceipeTagsRowList[rowIndex];
                      return Visibility(
                        visible: rowReceipeTagsRow.receipeId != null,
                        child: FutureBuilder<List<ReceipeRow>>(
                          future: ReceipeTable().querySingleRow(
                            queryFn: (q) => q.eqOrNull(
                              'id',
                              rowReceipeTagsRow.receipeId,
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
                                    color:
                                        FlutterFlowTheme.of(context).tertiary,
                                    size: 50.0,
                                  ),
                                ),
                              );
                            }
                            List<ReceipeRow> recipeCardMiniReceipeRowList =
                                snapshot.data!;

                            final recipeCardMiniReceipeRow =
                                recipeCardMiniReceipeRowList.isNotEmpty
                                    ? recipeCardMiniReceipeRowList.first
                                    : null;

                            return wrapWithModel(
                              model: _model.recipeCardMiniModels.getModel(
                                recipeCardMiniReceipeRow!.id.toString(),
                                rowIndex,
                              ),
                              updateCallback: () => safeSetState(() {}),
                              child: RecipeCardMiniWidget(
                                key: Key(
                                  'Keyhro_${recipeCardMiniReceipeRow!.id.toString()}',
                                ),
                                recipe: recipeCardMiniReceipeRow!,
                              ),
                            );
                          },
                        ),
                      );
                    }).divide(
                      SizedBox(width: 10.0),
                      filterFn: (rowIndex) {
                        final rowReceipeTagsRow =
                            rowReceipeTagsRowList[rowIndex];
                        return rowReceipeTagsRow.receipeId != null;
                      },
                    ),
                  ),
                );
              },
            ),
        ].divide(SizedBox(height: 10.0)),
      ),
    );
  }
}
