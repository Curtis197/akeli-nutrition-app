import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:from_css_color/from_css_color.dart';

import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';

import '/backend/supabase/supabase.dart';

import '../../flutter_flow/lat_lng.dart';
import '../../flutter_flow/place.dart';
import '../../flutter_flow/uploaded_file.dart';

/// SERIALIZATION HELPERS

String dateTimeRangeToString(DateTimeRange dateTimeRange) {
  final startStr = dateTimeRange.start.millisecondsSinceEpoch.toString();
  final endStr = dateTimeRange.end.millisecondsSinceEpoch.toString();
  return '$startStr|$endStr';
}

String placeToString(FFPlace place) => jsonEncode({
      'latLng': place.latLng.serialize(),
      'name': place.name,
      'address': place.address,
      'city': place.city,
      'state': place.state,
      'country': place.country,
      'zipCode': place.zipCode,
    });

String uploadedFileToString(FFUploadedFile uploadedFile) =>
    uploadedFile.serialize();

/// Converts the input value into a value that can be JSON encoded.
dynamic serializeParameter(dynamic value) {
  switch (value.runtimeType) {
    case DateTime:
      return (value as DateTime).millisecondsSinceEpoch;
    case DateTimeRange:
      return dateTimeRangeToString(value as DateTimeRange);
    case LatLng:
      return (value as LatLng).serialize();
    case Color:
      return (value as Color).toCssString();
    case FFPlace:
      return placeToString(value as FFPlace);
    case FFUploadedFile:
      return uploadedFileToString(value as FFUploadedFile);
    case SupabaseDataRow:
      return json.encode((value as SupabaseDataRow).data);
  }

  if (value is DocumentReference) {
    return value.path;
  }

  if (value is FirestoreRecord) {
    return (value as dynamic).reference.path;
  }

  return value;
}

String serializeParameterData(Map<String, dynamic> parameterData) => jsonEncode(
      parameterData.map(
        (key, value) => MapEntry(
          key,
          serializeParameter(value),
        ),
      )..removeWhere((k, v) => k == null || v == null),
    );

/// END SERIALIZATION HELPERS

/// DESERIALIZATION HELPERS

DateTimeRange? dateTimeRangeFromString(String dateTimeRangeStr) {
  final pieces = dateTimeRangeStr.split('|');
  if (pieces.length != 2) {
    return null;
  }
  return DateTimeRange(
    start: DateTime.fromMillisecondsSinceEpoch(int.parse(pieces.first)),
    end: DateTime.fromMillisecondsSinceEpoch(int.parse(pieces.last)),
  );
}

LatLng? latLngFromString(String? latLngStr) {
  final pieces = latLngStr?.split(',');
  if (pieces == null || pieces.length != 2) {
    return null;
  }
  return LatLng(
    double.parse(pieces.first.trim()),
    double.parse(pieces.last.trim()),
  );
}

FFPlace placeFromString(String placeStr) {
  final serializedData = jsonDecode(placeStr) as Map<String, dynamic>;
  final data = {
    'latLng': serializedData.containsKey('latLng')
        ? latLngFromString(serializedData['latLng'] as String)
        : const LatLng(0.0, 0.0),
    'name': serializedData['name'] ?? '',
    'address': serializedData['address'] ?? '',
    'city': serializedData['city'] ?? '',
    'state': serializedData['state'] ?? '',
    'country': serializedData['country'] ?? '',
    'zipCode': serializedData['zipCode'] ?? '',
  };
  return FFPlace(
    latLng: data['latLng'] as LatLng,
    name: data['name'] as String,
    address: data['address'] as String,
    city: data['city'] as String,
    state: data['state'] as String,
    country: data['country'] as String,
    zipCode: data['zipCode'] as String,
  );
}

FFUploadedFile uploadedFileFromString(String uploadedFileStr) =>
    FFUploadedFile.deserialize(uploadedFileStr);

T? getParameter<T>(Map<String, dynamic> data, String paramName) {
  try {
    if (!data.containsKey(paramName)) {
      return null;
    }
    final param = data[paramName];
    switch (T) {
      case String:
        return param;
      case double:
        return param.toDouble();
      case DateTime:
        return DateTime.fromMillisecondsSinceEpoch(param) as T;
      case DateTimeRange:
        return dateTimeRangeFromString(param) as T;
      case LatLng:
        return latLngFromString(param) as T;
      case Color:
        return fromCssColor(param) as T;
      case FFPlace:
        return placeFromString(param) as T;
      case FFUploadedFile:
        return uploadedFileFromString(param) as T;
      case ActivityLevelRow:
        return ActivityLevelRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case AiAssistantActionRow:
        return AiAssistantActionRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case AiChatMessageRow:
        return AiChatMessageRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case AiMemoryRow:
        return AiMemoryRow(json.decode(param) as Map<String, dynamic>) as T;
      case AiPlanFeedbackRow:
        return AiPlanFeedbackRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case AllCreatorRecipesRow:
        return AllCreatorRecipesRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case ChatConversationRow:
        return ChatConversationRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case ChatMessageRow:
        return ChatMessageRow(json.decode(param) as Map<String, dynamic>) as T;
      case ChatNotificationsRow:
        return ChatNotificationsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case CommentLikeRow:
        return CommentLikeRow(json.decode(param) as Map<String, dynamic>) as T;
      case ContactMessagesRow:
        return ContactMessagesRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case ConversationRow:
        return ConversationRow(json.decode(param) as Map<String, dynamic>) as T;
      case ConversationDemandRow:
        return ConversationDemandRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case ConversationDemandDeleteRow:
        return ConversationDemandDeleteRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case ConversationGroupRow:
        return ConversationGroupRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case ConversationGroupByNameRow:
        return ConversationGroupByNameRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case ConversationParticipantRow:
        return ConversationParticipantRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case CreatorRow:
        return CreatorRow(json.decode(param) as Map<String, dynamic>) as T;
      case CreatorCommentRow:
        return CreatorCommentRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case CreatorCommunityGroupRow:
        return CreatorCommunityGroupRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case CreatorCommunityMemberRow:
        return CreatorCommunityMemberRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case CreatorCommunityPostRow:
        return CreatorCommunityPostRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case CreatorCommunityPostLikeRow:
        return CreatorCommunityPostLikeRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case CreatorDashboardStatsRow:
        return CreatorDashboardStatsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case CreatorDietSpecialtyRow:
        return CreatorDietSpecialtyRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case CreatorFoodSpecialtyRow:
        return CreatorFoodSpecialtyRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case CreatorImageRow:
        return CreatorImageRow(json.decode(param) as Map<String, dynamic>) as T;
      case CreatorLikesRow:
        return CreatorLikesRow(json.decode(param) as Map<String, dynamic>) as T;
      case CreatorMonthlyRevenueRow:
        return CreatorMonthlyRevenueRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case CreatorPayoutRow:
        return CreatorPayoutRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case CreatorPerformanceSummaryRow:
        return CreatorPerformanceSummaryRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case CreatorRecipeSummaryRow:
        return CreatorRecipeSummaryRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case CreatorRevenueRow:
        return CreatorRevenueRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case CreatorStripeAccountRow:
        return CreatorStripeAccountRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case CreatorWeeklyRevenueRow:
        return CreatorWeeklyRevenueRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case CreatorWeeklyRevenueChartRow:
        return CreatorWeeklyRevenueChartRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case DailyUserTrackRow:
        return DailyUserTrackRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case DemandNotificationsRow:
        return DemandNotificationsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case DietQuestionnaryRow:
        return DietQuestionnaryRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case DietTypeRow:
        return DietTypeRow(json.decode(param) as Map<String, dynamic>) as T;
      case DifficultyRow:
        return DifficultyRow(json.decode(param) as Map<String, dynamic>) as T;
      case DirectConversationsWithOtherUserRow:
        return DirectConversationsWithOtherUserRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case EatingStyleRow:
        return EatingStyleRow(json.decode(param) as Map<String, dynamic>) as T;
      case FoodRegionRow:
        return FoodRegionRow(json.decode(param) as Map<String, dynamic>) as T;
      case GetReferralRevenueRow:
        return GetReferralRevenueRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case IngredientCategoryRow:
        return IngredientCategoryRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case IngredientsRow:
        return IngredientsRow(json.decode(param) as Map<String, dynamic>) as T;
      case LanguageRow:
        return LanguageRow(json.decode(param) as Map<String, dynamic>) as T;
      case LastMessageTimeRow:
        return LastMessageTimeRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case MealRow:
        return MealRow(json.decode(param) as Map<String, dynamic>) as T;
      case MealConsumedRow:
        return MealConsumedRow(json.decode(param) as Map<String, dynamic>) as T;
      case MealIngredientsRow:
        return MealIngredientsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case MealNotificationsRow:
        return MealNotificationsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case MealPlanRow:
        return MealPlanRow(json.decode(param) as Map<String, dynamic>) as T;
      case MealTypeRow:
        return MealTypeRow(json.decode(param) as Map<String, dynamic>) as T;
      case MessageReadRow:
        return MessageReadRow(json.decode(param) as Map<String, dynamic>) as T;
      case MessageTimeRow:
        return MessageTimeRow(json.decode(param) as Map<String, dynamic>) as T;
      case NotificationGroupsRow:
        return NotificationGroupsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case NotificationPreferencesRow:
        return NotificationPreferencesRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case NotificationTemplatesRow:
        return NotificationTemplatesRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case NotificationTriggersRow:
        return NotificationTriggersRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case NotificationsRow:
        return NotificationsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case PaymentHistoryEnrichedRow:
        return PaymentHistoryEnrichedRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case PrivateConversationRow:
        return PrivateConversationRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case ReceipeRow:
        return ReceipeRow(json.decode(param) as Map<String, dynamic>) as T;
      case ReceipeCommentsRow:
        return ReceipeCommentsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case ReceipeDifficultyRow:
        return ReceipeDifficultyRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case ReceipeImageRow:
        return ReceipeImageRow(json.decode(param) as Map<String, dynamic>) as T;
      case ReceipeLikesRow:
        return ReceipeLikesRow(json.decode(param) as Map<String, dynamic>) as T;
      case ReceipeMacroRow:
        return ReceipeMacroRow(json.decode(param) as Map<String, dynamic>) as T;
      case ReceipeTagsRow:
        return ReceipeTagsRow(json.decode(param) as Map<String, dynamic>) as T;
      case RecipeDetailedPerformanceRow:
        return RecipeDetailedPerformanceRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case RecipePerformanceRow:
        return RecipePerformanceRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case RecipePerformanceLatestRow:
        return RecipePerformanceLatestRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case RecipePerformanceSummaryRow:
        return RecipePerformanceSummaryRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case RecipeWeeklyRevenueRow:
        return RecipeWeeklyRevenueRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case RecipeWeeklyRevenueChartRow:
        return RecipeWeeklyRevenueChartRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case RecomandedReceipeRow:
        return RecomandedReceipeRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case ReferralRow:
        return ReferralRow(json.decode(param) as Map<String, dynamic>) as T;
      case ReferralViewRow:
        return ReferralViewRow(json.decode(param) as Map<String, dynamic>) as T;
      case RoundTypeRow:
        return RoundTypeRow(json.decode(param) as Map<String, dynamic>) as T;
      case ShoppingIngredientRow:
        return ShoppingIngredientRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case ShoppingListRow:
        return ShoppingListRow(json.decode(param) as Map<String, dynamic>) as T;
      case ShoppingListSummaryRow:
        return ShoppingListSummaryRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case ShoppingListTotalsRow:
        return ShoppingListTotalsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case StepRow:
        return StepRow(json.decode(param) as Map<String, dynamic>) as T;
      case SupportRow:
        return SupportRow(json.decode(param) as Map<String, dynamic>) as T;
      case TagsRow:
        return TagsRow(json.decode(param) as Map<String, dynamic>) as T;
      case TemporaryReceipeRow:
        return TemporaryReceipeRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case TestIndexRow:
        return TestIndexRow(json.decode(param) as Map<String, dynamic>) as T;
      case TestLogRow:
        return TestLogRow(json.decode(param) as Map<String, dynamic>) as T;
      case TopRecipesByRevenueRow:
        return TopRecipesByRevenueRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case TotalNotificationsRow:
        return TotalNotificationsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case UnitRow:
        return UnitRow(json.decode(param) as Map<String, dynamic>) as T;
      case UpdatedWeightRow:
        return UpdatedWeightRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case UserAllergiesRow:
        return UserAllergiesRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case UserFanRow:
        return UserFanRow(json.decode(param) as Map<String, dynamic>) as T;
      case UserGoalRow:
        return UserGoalRow(json.decode(param) as Map<String, dynamic>) as T;
      case UserHealthParameterRow:
        return UserHealthParameterRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case UserMoodRow:
        return UserMoodRow(json.decode(param) as Map<String, dynamic>) as T;
      case UserMoodInfoRow:
        return UserMoodInfoRow(json.decode(param) as Map<String, dynamic>) as T;
      case UserPreferencesRow:
        return UserPreferencesRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case UserReferralRow:
        return UserReferralRow(json.decode(param) as Map<String, dynamic>) as T;
      case UserReferralCodeRow:
        return UserReferralCodeRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case UserReferralMonthlyStatsRow:
        return UserReferralMonthlyStatsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case UserSubscriptionRow:
        return UserSubscriptionRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case UserTrackRow:
        return UserTrackRow(json.decode(param) as Map<String, dynamic>) as T;
      case UsersRow:
        return UsersRow(json.decode(param) as Map<String, dynamic>) as T;
      case WaitlistRow:
        return WaitlistRow(json.decode(param) as Map<String, dynamic>) as T;
      case WeeklySummaryRow:
        return WeeklySummaryRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case WeeklyUserTrackRow:
        return WeeklyUserTrackRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case WeightGraphDataRow:
        return WeightGraphDataRow(json.decode(param) as Map<String, dynamic>)
            as T;
    }
    if (param is String) {
      return FirebaseFirestore.instance.doc(param) as T;
    }
    return param;
  } catch (e) {
    print('Error parsing parameter "$paramName": $e');
    return null;
  }
}

Future<T?> getDocumentParameter<T>(
  Map<String, dynamic> data,
  String paramName,
  RecordBuilder<T> recordBuilder,
) {
  if (!data.containsKey(paramName)) {
    return Future.value(null);
  }
  return FirebaseFirestore.instance
      .doc(data[paramName])
      .get()
      .then((s) => recordBuilder(s));
}

/// END DESERIALIZATION HELPERS
