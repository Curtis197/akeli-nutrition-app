import '/auth/firebase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'comment_model.dart';
export 'comment_model.dart';

class CommentWidget extends StatefulWidget {
  const CommentWidget({
    super.key,
    required this.receipeComment,
  });

  final ReceipeCommentsRow? receipeComment;

  @override
  State<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  late CommentModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CommentModel());

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
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(15.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<List<UsersRow>>(
              future: UsersTable().querySingleRow(
                queryFn: (q) => q.eqOrNull(
                  'id',
                  widget!.receipeComment?.userId,
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
                List<UsersRow> rowUsersRowList = snapshot.data!;

                final rowUsersRow =
                    rowUsersRowList.isNotEmpty ? rowUsersRowList.first : null;

                return Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    if (rowUsersRow?.profilImageUrl != null &&
                        rowUsersRow?.profilImageUrl != '')
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40.0),
                        child: Image.network(
                          rowUsersRow!.profilImageUrl!,
                          width: 40.0,
                          height: 40.0,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (rowUsersRow?.profilImageUrl == null ||
                        rowUsersRow?.profilImageUrl == '')
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40.0),
                        child: Image.network(
                          'https://jfbfymiyqlyciapfloug.supabase.co/storage/v1/object/public/images/group_photo/360_F_65772719_A1UV5kLi5nCEWI0BNLLiFaBPEkUbv5Fv.jpg',
                          width: 40.0,
                          height: 40.0,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 0.0, 0.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              valueOrDefault<String>(
                                rowUsersRow?.userName,
                                'User Name',
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .override(
                                    font: GoogleFonts.poppins(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyLarge
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyLarge
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyLarge
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyLarge
                                        .fontStyle,
                                  ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 4.0, 0.0, 0.0),
                              child: Text(
                                dateTimeFormat(
                                  "relative",
                                  widget!.receipeComment!.createdAt!,
                                  locale:
                                      FFLocalizations.of(context).languageCode,
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
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            Text(
              valueOrDefault<String>(
                widget!.receipeComment?.text,
                'Commentaire',
              ),
              style: FlutterFlowTheme.of(context).labelMedium.override(
                    font: GoogleFonts.poppins(
                      fontWeight:
                          FlutterFlowTheme.of(context).labelMedium.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelMedium.fontStyle,
                    ),
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).labelMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelMedium.fontStyle,
                  ),
            ),
            RatingBar.builder(
              onRatingUpdate: (newValue) =>
                  safeSetState(() => _model.ratingBarValue = newValue),
              itemBuilder: (context, index) => Icon(
                Icons.star_rounded,
                color: FlutterFlowTheme.of(context).secondary,
              ),
              direction: Axis.horizontal,
              initialRating: _model.ratingBarValue ??=
                  widget!.receipeComment!.rate!,
              unratedColor: FlutterFlowTheme.of(context).alternate,
              itemCount: 5,
              itemSize: 24.0,
              glowColor: FlutterFlowTheme.of(context).secondary,
            ),
            FutureBuilder<List<CommentLikeRow>>(
              future: (_model.requestCompleter1 ??=
                      Completer<List<CommentLikeRow>>()
                        ..complete(CommentLikeTable().queryRows(
                          queryFn: (q) => q.eqOrNull(
                            'receipe_comment_id',
                            widget!.receipeComment?.id,
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
                List<CommentLikeRow> containerCommentLikeRowList =
                    snapshot.data!;

                return Container(
                  decoration: BoxDecoration(),
                  child: AuthUserStreamWidget(
                    builder: (context) => FutureBuilder<List<CommentLikeRow>>(
                      future: (_model.requestCompleter2 ??=
                              Completer<List<CommentLikeRow>>()
                                ..complete(CommentLikeTable().querySingleRow(
                                  queryFn: (q) => q
                                      .eqOrNull(
                                        'user_id',
                                        valueOrDefault(
                                            currentUserDocument?.id, 0),
                                      )
                                      .eqOrNull(
                                        'receipe_comment_id',
                                        widget!.receipeComment?.id,
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
                        List<CommentLikeRow> commentLikeCommentLikeRowList =
                            snapshot.data!;

                        final commentLikeCommentLikeRow =
                            commentLikeCommentLikeRowList.isNotEmpty
                                ? commentLikeCommentLikeRowList.first
                                : null;

                        return Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            if (commentLikeCommentLikeRow?.id != null)
                              InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  logFirebaseEvent(
                                      'COMMENT_COMP_Icon_6zfc2igp_ON_TAP');
                                  logFirebaseEvent('Icon_backend_call');
                                  await CommentLikeTable().delete(
                                    matchingRows: (rows) => rows.eqOrNull(
                                      'id',
                                      commentLikeCommentLikeRow?.id,
                                    ),
                                  );
                                  logFirebaseEvent(
                                      'Icon_refresh_database_request');
                                  safeSetState(
                                      () => _model.requestCompleter2 = null);
                                  await _model.waitForRequestCompleted2();
                                  logFirebaseEvent(
                                      'Icon_refresh_database_request');
                                  safeSetState(
                                      () => _model.requestCompleter1 = null);
                                  await _model.waitForRequestCompleted1();
                                },
                                child: Icon(
                                  Icons.favorite_rounded,
                                  color: FlutterFlowTheme.of(context).secondary,
                                  size: 24.0,
                                ),
                              ),
                            if (commentLikeCommentLikeRow?.id == null)
                              InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  logFirebaseEvent(
                                      'COMMENT_COMP_Icon_zvbye148_ON_TAP');
                                  logFirebaseEvent('Icon_backend_call');
                                  await CommentLikeTable().insert({
                                    'user_id': valueOrDefault(
                                        currentUserDocument?.id, 0),
                                    'receipe_comment_id':
                                        widget!.receipeComment?.id,
                                  });
                                  logFirebaseEvent(
                                      'Icon_refresh_database_request');
                                  safeSetState(
                                      () => _model.requestCompleter2 = null);
                                  await _model.waitForRequestCompleted2();
                                  logFirebaseEvent(
                                      'Icon_refresh_database_request');
                                  safeSetState(
                                      () => _model.requestCompleter1 = null);
                                  await _model.waitForRequestCompleted1();
                                },
                                child: Icon(
                                  Icons.favorite_border_rounded,
                                  color: FlutterFlowTheme.of(context).secondary,
                                  size: 24.0,
                                ),
                              ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Text(
                                  valueOrDefault<String>(
                                    containerCommentLikeRowList.length
                                        .toString(),
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
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'l4y9h9lb' /* J'aime */,
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
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ].divide(SizedBox(width: 5.0)),
                            ),
                          ].divide(SizedBox(width: 10.0)),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(),
            ),
          ],
        ),
      ),
    );
  }
}
