import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/backend/schema/structs/index.dart';
import '/index.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'recipe_card_j_s_o_n_copy_model.dart';
export 'recipe_card_j_s_o_n_copy_model.dart';

class RecipeCardJSONCopyWidget extends StatefulWidget {
  const RecipeCardJSONCopyWidget({
    super.key,
    required this.receipe,
  });

  final dynamic receipe;

  @override
  State<RecipeCardJSONCopyWidget> createState() =>
      _RecipeCardJSONCopyWidgetState();
}

class _RecipeCardJSONCopyWidgetState extends State<RecipeCardJSONCopyWidget> {
  late RecipeCardJSONCopyModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RecipeCardJSONCopyModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () async {
            logFirebaseEvent('RECIPE_CARD_J_S_O_N_COPY_Container_zq5kt');
            logFirebaseEvent('Container_navigate_to');

            context.pushNamed(
              ReceipeDetailWidget.routeName,
              queryParameters: {
                'receipeID': serializeParam(
                  getJsonField(
                    widget!.receipe,
                    r'''$.id''',
                  ),
                  ParamType.int,
                ),
              }.withoutNulls,
            );
          },
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: 800.0,
            ),
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
                mainAxisSize: MainAxisSize.max,
                children: [
                  FutureBuilder<List<ReceipeImageRow>>(
                    future: ReceipeImageTable().querySingleRow(
                      queryFn: (q) => q
                          .eqOrNull(
                            'receipe_id',
                            RecipesStruct.maybeFromMap(widget!.receipe)?.id,
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

                      // Return an empty Container when the item does not exist.
                      if (snapshot.data!.isEmpty) {
                        return Container();
                      }
                      final imageReceipeImageRow =
                          imageReceipeImageRowList.isNotEmpty
                              ? imageReceipeImageRowList.first
                              : null;

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: Image.network(
                          imageReceipeImageRow!.url!,
                          width: double.infinity,
                          height: 200.0,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: AlignmentDirectional(0.0, 0.0),
                                child: Text(
                                  valueOrDefault<String>(
                                    RecipesStruct.maybeFromMap(widget!.receipe)
                                        ?.name,
                                    'receipe name',
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .titleLarge
                                      .override(
                                        font: GoogleFonts.outfit(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .titleLarge
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleLarge
                                                  .fontStyle,
                                        ),
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .titleLarge
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleLarge
                                            .fontStyle,
                                      ),
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(0.0, 0.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    RichText(
                                      textScaler:
                                          MediaQuery.of(context).textScaler,
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: valueOrDefault<String>(
                                              RecipesStruct.maybeFromMap(
                                                      widget!.receipe)
                                                  ?.calorie
                                                  ?.toString(),
                                              '0',
                                            ),
                                            style: TextStyle(),
                                          ),
                                          TextSpan(
                                            text: FFLocalizations.of(context)
                                                .getText(
                                              '4sxujsvr' /*  kcal */,
                                            ),
                                            style: TextStyle(),
                                          ),
                                          TextSpan(
                                            text: FFLocalizations.of(context)
                                                .getText(
                                              'r5edujhj' /*  ||  */,
                                            ),
                                            style: TextStyle(),
                                          ),
                                          TextSpan(
                                            text: valueOrDefault<String>(
                                              RecipesStruct.maybeFromMap(
                                                      widget!.receipe)
                                                  ?.timeOfCookingHour
                                                  ?.toString(),
                                              '0',
                                            ),
                                            style: TextStyle(),
                                          ),
                                          TextSpan(
                                            text: FFLocalizations.of(context)
                                                .getText(
                                              '1qlxqfck' /*  h  */,
                                            ),
                                            style: TextStyle(),
                                          ),
                                          TextSpan(
                                            text: valueOrDefault<String>(
                                              RecipesStruct.maybeFromMap(
                                                      widget!.receipe)
                                                  ?.timeOfCookingMin
                                                  ?.toString(),
                                              '0',
                                            ),
                                            style: TextStyle(),
                                          ),
                                          TextSpan(
                                            text: FFLocalizations.of(context)
                                                .getText(
                                              '7ve6xmmk' /*  min */,
                                            ),
                                            style: TextStyle(),
                                          )
                                        ],
                                        style: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .override(
                                              font: GoogleFonts.poppins(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .labelSmall
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelSmall
                                                        .fontStyle,
                                              ),
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        RatingBarIndicator(
                                          itemBuilder: (context, index) => Icon(
                                            Icons.star_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .secondary,
                                          ),
                                          direction: Axis.horizontal,
                                          rating: RecipesStruct.maybeFromMap(
                                                          widget!.receipe)
                                                      ?.totalRate !=
                                                  null
                                              ? RecipesStruct.maybeFromMap(
                                                      widget!.receipe!)!
                                                  .totalRate
                                              : 0.0,
                                          unratedColor: Color(0x3DFF9F1C),
                                          itemCount: 5,
                                          itemSize: 24.0,
                                        ),
                                        RichText(
                                          textScaler:
                                              MediaQuery.of(context).textScaler,
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text:
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                  'bhip5886' /*  */,
                                                ),
                                                style: TextStyle(),
                                              )
                                            ],
                                            style: FlutterFlowTheme.of(context)
                                                .labelMedium
                                                .override(
                                                  font: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .labelMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .labelMedium
                                                            .fontStyle,
                                                  ),
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelMedium
                                                          .fontStyle,
                                                ),
                                          ),
                                        ),
                                      ].divide(SizedBox(width: 10.0)),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Icon(
                                    Icons.favorite_sharp,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 24.0,
                                  ),
                                  Text(
                                    valueOrDefault<String>(
                                      RecipesStruct.maybeFromMap(
                                              widget!.receipe)
                                          ?.likeCount
                                          ?.toString(),
                                      '0',
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.poppins(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                  Icon(
                                    Icons.comment,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 24.0,
                                  ),
                                  Text(
                                    valueOrDefault<String>(
                                      RecipesStruct.maybeFromMap(
                                              widget!.receipe)
                                          ?.commentCount
                                          ?.toString(),
                                      '0',
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.poppins(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                  Icon(
                                    Icons.local_dining,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 24.0,
                                  ),
                                  Text(
                                    valueOrDefault<String>(
                                      RecipesStruct.maybeFromMap(
                                              widget!.receipe)
                                          ?.mealConsumed
                                          ?.toString(),
                                      '0',
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.poppins(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          valueOrDefault<String>(
                                            getJsonField(
                                              widget!.receipe,
                                              r'''$["Food Region"]''',
                                            )?.toString(),
                                            'food region',
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.poppins(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ].divide(SizedBox(width: 5.0)),
                              ),
                            ].divide(SizedBox(height: 4.0)),
                          ),
                        ),
                      ].divide(SizedBox(width: 8.0)),
                    ),
                  ),
                ].divide(SizedBox(height: 8.0)),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(5.0),
          child: FutureBuilder<List<ReceipeTagsRow>>(
            future: ReceipeTagsTable().queryRows(
              queryFn: (q) => q.eqOrNull(
                'receipe_id',
                RecipesStruct.maybeFromMap(widget!.receipe)?.id,
              ),
              limit: 3,
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
              List<ReceipeTagsRow> rowReceipeTagsRowList = snapshot.data!;

              return Row(
                mainAxisSize: MainAxisSize.max,
                children:
                    List.generate(rowReceipeTagsRowList.length, (rowIndex) {
                  final rowReceipeTagsRow = rowReceipeTagsRowList[rowIndex];
                  return Container(
                    decoration: BoxDecoration(
                      color: Color(0x76FFFFFF),
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    child: Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(8.0, 5.0, 8.0, 5.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            valueOrDefault<String>(
                              rowReceipeTagsRow.name,
                              'name',
                            ),
                            style: FlutterFlowTheme.of(context)
                                .labelSmall
                                .override(
                                  font: GoogleFonts.poppins(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontStyle,
                                  ),
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .labelSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .labelSmall
                                      .fontStyle,
                                ),
                          ),
                        ].divide(SizedBox(width: 10.0)),
                      ),
                    ),
                  );
                }).divide(SizedBox(width: 5.0)),
              );
            },
          ),
        ),
      ],
    );
  }
}
