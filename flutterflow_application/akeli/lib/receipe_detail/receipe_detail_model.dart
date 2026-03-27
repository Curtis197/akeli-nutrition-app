import '/auth/firebase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_expanded_image_view.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/home_page/comment/comment_widget.dart';
import '/home_page/comment_thread/comment_thread_widget.dart';
import '/meal_planner/add_new_meal/add_new_meal_widget.dart';
import '/recipe_management/add_comment/add_comment_widget.dart';
import '/recipe_management/similar_receipe/similar_receipe_widget.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:carousel_slider/carousel_slider.dart';
import 'receipe_detail_widget.dart' show ReceipeDetailWidget;
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class ReceipeDetailModel extends FlutterFlowModel<ReceipeDetailWidget> {
  ///  Local state fields for this page.
  /// type
  String breakfast = 'Petit-déjeuner';

  String lunch = 'Déjeuner';

  String dinner = 'Dîner';

  String collation = 'Collation';

  ///  State fields for stateful widgets in this page.

  // State field(s) for Carousel widget.
  CarouselSliderController? carouselController;
  int carouselCurrentIndex = 1;

  // State field(s) for RatingBar widget.
  double? ratingBarValue;
  // Models for comment dynamic component.
  late FlutterFlowDynamicModels<CommentModel> commentModels;
  // Model for similarReceipe component.
  late SimilarReceipeModel similarReceipeModel;

  @override
  void initState(BuildContext context) {
    commentModels = FlutterFlowDynamicModels(() => CommentModel());
    similarReceipeModel = createModel(context, () => SimilarReceipeModel());
  }

  @override
  void dispose() {
    commentModels.dispose();
    similarReceipeModel.dispose();
  }
}
