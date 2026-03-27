import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'add_meal_model.dart';
export 'add_meal_model.dart';

class AddMealWidget extends StatefulWidget {
  const AddMealWidget({
    super.key,
    required this.meal,
    required this.user,
    required this.mea,
  });

  final int? meal;
  final int? user;
  final int? mea;

  @override
  State<AddMealWidget> createState() => _AddMealWidgetState();
}

class _AddMealWidgetState extends State<AddMealWidget> {
  late AddMealModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddMealModel());

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

    return Container(
      width: double.infinity,
      height: 500.0,
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
        padding: EdgeInsetsDirectional.fromSTEB(20.0, 20.0, 20.0, 30.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: 50.0,
                height: 5.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).alternate,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              Text(
                FFLocalizations.of(context).getText(
                  '6n1e7cqn' /* Dites nous ce que vous avez ma... */,
                ),
                textAlign: TextAlign.center,
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
                      fontStyle:
                          FlutterFlowTheme.of(context).titleLarge.fontStyle,
                    ),
              ),
              AuthUserStreamWidget(
                builder: (context) => FutureBuilder<List<UsersRow>>(
                  future: UsersTable().querySingleRow(
                    queryFn: (q) => q
                        .eqOrNull(
                          'id',
                          valueOrDefault(currentUserDocument?.id, 0),
                        )
                        .eqOrNull(
                          'paid_plan',
                          true,
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

                    // Return an empty Container when the item does not exist.
                    if (snapshot.data!.isEmpty) {
                      return Container();
                    }
                    final rowUsersRow = rowUsersRowList.isNotEmpty
                        ? rowUsersRowList.first
                        : null;

                    return Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_model.uploadedLocalFile_customMealImage == null ||
                            (_model.uploadedLocalFile_customMealImage.bytes
                                    ?.isEmpty ??
                                true))
                          InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              logFirebaseEvent(
                                  'ADD_MEAL_COMP_Container_z1b3vz9t_ON_TAP');
                              logFirebaseEvent(
                                  'Container_store_media_for_upload');
                              final selectedMedia =
                                  await selectMediaWithSourceBottomSheet(
                                context: context,
                                allowPhoto: true,
                              );
                              if (selectedMedia != null &&
                                  selectedMedia.every((m) => validateFileFormat(
                                      m.storagePath, context))) {
                                safeSetState(() => _model
                                    .isDataUploading_customMealImage = true);
                                var selectedUploadedFiles = <FFUploadedFile>[];

                                try {
                                  selectedUploadedFiles = selectedMedia
                                      .map((m) => FFUploadedFile(
                                            name: m.storagePath.split('/').last,
                                            bytes: m.bytes,
                                            height: m.dimensions?.height,
                                            width: m.dimensions?.width,
                                            blurHash: m.blurHash,
                                            originalFilename:
                                                m.originalFilename,
                                          ))
                                      .toList();
                                } finally {
                                  _model.isDataUploading_customMealImage =
                                      false;
                                }
                                if (selectedUploadedFiles.length ==
                                    selectedMedia.length) {
                                  safeSetState(() {
                                    _model.uploadedLocalFile_customMealImage =
                                        selectedUploadedFiles.first;
                                  });
                                } else {
                                  safeSetState(() {});
                                  return;
                                }
                              }
                            },
                            child: Container(
                              width: 100.0,
                              height: 100.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_sharp,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      size: 40.0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (_model.uploadedLocalFile_customMealImage != null &&
                            (_model.uploadedLocalFile_customMealImage.bytes
                                    ?.isNotEmpty ??
                                false))
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.memory(
                              _model.uploadedLocalFile_customMealImage.bytes ??
                                  Uint8List.fromList([]),
                              width: 100.0,
                              height: 100.0,
                              fit: BoxFit.cover,
                            ),
                          ),
                        if (_model.uploadedLocalFile_customMealImage != null &&
                            (_model.uploadedLocalFile_customMealImage.bytes
                                    ?.isNotEmpty ??
                                false))
                          InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              logFirebaseEvent(
                                  'ADD_MEAL_COMP_Icon_aqu783js_ON_TAP');
                              logFirebaseEvent('Icon_clear_uploaded_data');
                              safeSetState(() {
                                _model.isDataUploading_customMealImage = false;
                                _model.uploadedLocalFile_customMealImage =
                                    FFUploadedFile(
                                        bytes: Uint8List.fromList([]),
                                        originalFilename: '');
                              });
                            },
                            child: Icon(
                              Icons.clear_rounded,
                              color: FlutterFlowTheme.of(context).primaryText,
                              size: 24.0,
                            ),
                          ),
                      ].divide(SizedBox(width: 30.0)),
                    );
                  },
                ),
              ),
              if (FFAppState().snack)
                FlutterFlowDropDown<String>(
                  controller: _model.dropDownValueController ??=
                      FormFieldController<String>(null),
                  options: [
                    FFLocalizations.of(context).getText(
                      'rn8u7l0w' /* Lundi */,
                    ),
                    FFLocalizations.of(context).getText(
                      '4p4v2q72' /* Mardi */,
                    ),
                    FFLocalizations.of(context).getText(
                      'le170mhw' /* Mercredi */,
                    ),
                    FFLocalizations.of(context).getText(
                      'k5akgqvl' /* Jeudi */,
                    ),
                    FFLocalizations.of(context).getText(
                      'r590ixfc' /* Vendredi */,
                    ),
                    FFLocalizations.of(context).getText(
                      '1vt10hp7' /* Samedi */,
                    ),
                    FFLocalizations.of(context).getText(
                      'rr7ersgx' /* Dimanche */,
                    )
                  ],
                  onChanged: (val) =>
                      safeSetState(() => _model.dropDownValue = val),
                  width: 200.0,
                  height: 40.0,
                  textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.poppins(
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                  hintText: FFLocalizations.of(context).getText(
                    'pq4rcykr' /* Choisissez le jour */,
                  ),
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: FlutterFlowTheme.of(context).secondaryText,
                    size: 24.0,
                  ),
                  fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                  elevation: 2.0,
                  borderColor: FlutterFlowTheme.of(context).alternate,
                  borderWidth: 0.0,
                  borderRadius: 8.0,
                  margin: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
                  hidesUnderline: true,
                  isOverButton: false,
                  isSearchable: false,
                  isMultiSelect: false,
                ),
              Container(
                width: 250.0,
                child: TextFormField(
                  controller: _model.textController,
                  focusNode: _model.textFieldFocusNode,
                  autofocus: false,
                  obscureText: false,
                  decoration: InputDecoration(
                    isDense: true,
                    labelStyle:
                        FlutterFlowTheme.of(context).labelMedium.override(
                              font: GoogleFonts.poppins(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
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
                    hintText: FFLocalizations.of(context).getText(
                      'pttwysxu' /* Pour avoir une meilleur estima... */,
                    ),
                    hintStyle:
                        FlutterFlowTheme.of(context).labelMedium.override(
                              font: GoogleFonts.poppins(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
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
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0x00000000),
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).error,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).error,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: FlutterFlowTheme.of(context).primaryBackground,
                  ),
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.poppins(
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                  maxLines: 6,
                  cursorColor: FlutterFlowTheme.of(context).primaryText,
                  validator:
                      _model.textControllerValidator.asValidator(context),
                ),
              ),
              FFButtonWidget(
                onPressed: () async {
                  logFirebaseEvent('ADD_MEAL_COMP_CONFIRMER_BTN_ON_TAP');
                  if (_model.uploadedLocalFile_customMealImage != null &&
                      (_model.uploadedLocalFile_customMealImage.bytes
                              ?.isNotEmpty ??
                          false)) {
                    logFirebaseEvent('Button_upload_media_to_supabase');
                    {
                      safeSetState(
                          () => _model.isDataUploading_uploadDataY65 = true);
                      var selectedUploadedFiles = <FFUploadedFile>[];
                      var selectedMedia = <SelectedFile>[];
                      var downloadUrls = <String>[];
                      try {
                        selectedUploadedFiles = _model
                                .uploadedLocalFile_customMealImage
                                .bytes!
                                .isNotEmpty
                            ? [_model.uploadedLocalFile_customMealImage]
                            : <FFUploadedFile>[];
                        selectedMedia = selectedFilesFromUploadedFiles(
                          selectedUploadedFiles,
                          storageFolderPath: 'image',
                        );
                        downloadUrls = await uploadSupabaseStorageFiles(
                          bucketName: 'meal',
                          selectedFiles: selectedMedia,
                        );
                      } finally {
                        _model.isDataUploading_uploadDataY65 = false;
                      }
                      if (selectedUploadedFiles.length ==
                              selectedMedia.length &&
                          downloadUrls.length == selectedMedia.length) {
                        safeSetState(() {
                          _model.uploadedLocalFile_uploadDataY65 =
                              selectedUploadedFiles.first;
                          _model.uploadedFileUrl_uploadDataY65 =
                              downloadUrls.first;
                        });
                      } else {
                        safeSetState(() {});
                        return;
                      }
                    }

                    logFirebaseEvent('Button_backend_call');
                    _model.querriedMeal = await MealTable().queryRows(
                      queryFn: (q) => q.eqOrNull(
                        'id',
                        widget!.meal,
                      ),
                    );
                    logFirebaseEvent('Button_backend_call');
                    _model.customMeal =
                        await SupabaseGroup.imageRecognitionCall.call(
                      mealPlanId: _model.querriedMeal?.lastOrNull?.mealPlanId,
                      imageUrl: _model.uploadedFileUrl_uploadDataY65,
                      description: _model.textController.text,
                      date: _model.querriedMeal?.firstOrNull?.mealDate
                          ?.toString(),
                      mealType: _model.querriedMeal?.firstOrNull?.mealType,
                      day: _model.querriedMeal?.firstOrNull?.day,
                      consumed: _model.querriedMeal?.firstOrNull?.consumed,
                    );

                    if ((_model.customMeal?.succeeded ?? true)) {
                      logFirebaseEvent('Button_backend_call');
                      _model.updatedShopList =
                          await SupabaseGroup.mealPlanShoppingListCall.call(
                        mealPlanId: widget!.mea,
                        updateMode: 'replace',
                        userId: valueOrDefault(currentUserDocument?.id, 0),
                      );

                      if ((_model.updatedShopList?.succeeded ?? true)) {
                        logFirebaseEvent('Button_backend_call');
                        await MealTable().update(
                          data: {
                            'personal': true,
                          },
                          matchingRows: (rows) => rows.eqOrNull(
                            'id',
                            widget!.meal,
                          ),
                        );
                        logFirebaseEvent('Button_bottom_sheet');
                        Navigator.pop(context);
                        logFirebaseEvent('Button_navigate_to');

                        context.pushNamed(MealPlannerWidget.routeName);
                      }
                    }
                  } else {
                    logFirebaseEvent('Button_backend_call');
                    _model.customMeal2 =
                        await SupabaseGroup.customMealCall.call(
                      userId: widget!.user,
                      mealId: widget!.meal,
                      textInput: _model.textController.text,
                    );

                    if ((_model.customMeal?.succeeded ?? true)) {
                      logFirebaseEvent('Button_backend_call');
                      _model.updatedShopList2 =
                          await SupabaseGroup.mealPlanShoppingListCall.call(
                        mealPlanId: FFAppState().mealPlan,
                        updateMode: 'replace',
                        userId: valueOrDefault(currentUserDocument?.id, 0),
                      );

                      if ((_model.updatedShopList2?.succeeded ?? true)) {
                        logFirebaseEvent('Button_backend_call');
                        await MealTable().update(
                          data: {
                            'personal': true,
                          },
                          matchingRows: (rows) => rows.eqOrNull(
                            'id',
                            widget!.meal,
                          ),
                        );
                        logFirebaseEvent('Button_bottom_sheet');
                        Navigator.pop(context);
                        logFirebaseEvent('Button_navigate_to');

                        context.pushNamed(MealPlannerWidget.routeName);
                      }
                    }
                  }

                  logFirebaseEvent('Button_backend_call');
                  await MealTable().update(
                    data: {
                      'generated': true,
                    },
                    matchingRows: (rows) => rows.eqOrNull(
                      'id',
                      widget!.meal,
                    ),
                  );

                  safeSetState(() {});
                },
                text: FFLocalizations.of(context).getText(
                  'v7gvf7rj' /* Confirmer */,
                ),
                options: FFButtonOptions(
                  height: 40.0,
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                  iconPadding:
                      EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                  color: FlutterFlowTheme.of(context).primary,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        font: GoogleFonts.poppins(
                          fontWeight: FlutterFlowTheme.of(context)
                              .titleSmall
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).titleSmall.fontStyle,
                        ),
                        color: Colors.white,
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).titleSmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleSmall.fontStyle,
                      ),
                  elevation: 0.0,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ].divide(SizedBox(height: 30.0)),
          ),
        ),
      ),
    );
  }
}
