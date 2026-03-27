import 'dart:convert';
import 'dart:typed_data';
import '../schema/structs/index.dart';

import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

/// Start Supabase  Group Code

class SupabaseGroup {
  static String getBaseUrl({
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    return '${apiUrl}';
  }

  static Map<String, String> headers = {
    'Authorization': 'Bearer [apiKey]',
  };
  static SearchAPrivateConversationCall searchAPrivateConversationCall =
      SearchAPrivateConversationCall();
  static SearchAGroupByNameCall searchAGroupByNameCall =
      SearchAGroupByNameCall();
  static SearchAGroupCall searchAGroupCall = SearchAGroupCall();
  static AddANewMealCall addANewMealCall = AddANewMealCall();
  static CustomMealCall customMealCall = CustomMealCall();
  static MealIngredientsScaleCall mealIngredientsScaleCall =
      MealIngredientsScaleCall();
  static ShoppingListCall shoppingListCall = ShoppingListCall();
  static DietPlanCall dietPlanCall = DietPlanCall();
  static PersonalMealPlanCall personalMealPlanCall = PersonalMealPlanCall();
  static CustomSnackCall customSnackCall = CustomSnackCall();
  static MealPlanScaleCall mealPlanScaleCall = MealPlanScaleCall();
  static MealPlanShoppingListCall mealPlanShoppingListCall =
      MealPlanShoppingListCall();
  static SearchAConversationCall searchAConversationCall =
      SearchAConversationCall();
  static FindOrCreateTheConversationCall findOrCreateTheConversationCall =
      FindOrCreateTheConversationCall();
  static CheckIfAUserIsInAGroupCall checkIfAUserIsInAGroupCall =
      CheckIfAUserIsInAGroupCall();
  static CreateAReferralCall createAReferralCall = CreateAReferralCall();
  static UpdatedRecipeResearchCall updatedRecipeResearchCall =
      UpdatedRecipeResearchCall();
  static RecommandedReceipeCall recommandedReceipeCall =
      RecommandedReceipeCall();
  static ChatNotiificationCall chatNotiificationCall = ChatNotiificationCall();
  static RequestBodyCall requestBodyCall = RequestBodyCall();
  static ConversationRequestCall conversationRequestCall =
      ConversationRequestCall();
  static ConversationAcceptedCall conversationAcceptedCall =
      ConversationAcceptedCall();
  static ImageRecognitionCall imageRecognitionCall = ImageRecognitionCall();
  static PersonalMealPlanNoMealCall personalMealPlanNoMealCall =
      PersonalMealPlanNoMealCall();
  static CalculateRegimeTimeCall calculateRegimeTimeCall =
      CalculateRegimeTimeCall();
  static UserContextCall userContextCall = UserContextCall();
  static GetAiMessageCall getAiMessageCall = GetAiMessageCall();
  static GetChatMessagesCall getChatMessagesCall = GetChatMessagesCall();
  static SendAMessageCall sendAMessageCall = SendAMessageCall();
}

class SearchAPrivateConversationCall {
  Future<ApiCallResponse> call({
    String? name = '',
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "user_id": "${userId}",
  "name": "${escapeStringForJson(name)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'search a private conversation',
      apiUrl: '${baseUrl}/functions/v1/search-a-chat_conversation',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  List? conversation(dynamic response) => getJsonField(
        response,
        r'''$.conversations''',
        true,
      ) as List?;
  int? user1ID(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.conversations[:].requester_id''',
      ));
  int? id(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.conversations[:].conversation_id''',
      ));
  String? user2name(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.conversations[:].other_user_name''',
      ));
  int? user2ID(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.conversations[:].other_user_id''',
      ));
}

class SearchAGroupByNameCall {
  Future<ApiCallResponse> call({
    String? name = '',
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "name": "${escapeStringForJson(name)}",
  "user_id": "${userId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'search a group by name',
      apiUrl: '${baseUrl}/functions/v1/search-a-grouped-conversation',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  List? conversation(dynamic response) => getJsonField(
        response,
        r'''$.conversations''',
        true,
      ) as List?;
  int? userID(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.conversations[:].requester_id''',
      ));
  int? conversationID(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.conversations[:].conversation_id''',
      ));
  String? name(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.conversations[:].group_name''',
      ));
}

class SearchAGroupCall {
  Future<ApiCallResponse> call({
    String? name = '',
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "name": "${escapeStringForJson(name)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'search a group',
      apiUrl: '${baseUrl}/functions/v1/get_conversation_grouped_by_user_id',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  List? conversation(dynamic response) => getJsonField(
        response,
        r'''$.conversations''',
        true,
      ) as List?;
  List<int>? id(dynamic response) => (getJsonField(
        response,
        r'''$.conversations[:].id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  List<String>? date(dynamic response) => (getJsonField(
        response,
        r'''$.conversations[:].created_at''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? name(dynamic response) => (getJsonField(
        response,
        r'''$.conversations[:].name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? description(dynamic response) => (getJsonField(
        response,
        r'''$.conversations[:].description''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List? image(dynamic response) => getJsonField(
        response,
        r'''$.conversations[:].image_url''',
        true,
      ) as List?;
  List<int>? conversationID(dynamic response) => (getJsonField(
        response,
        r'''$.conversations[:].conversation_id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
}

class AddANewMealCall {
  Future<ApiCallResponse> call({
    int? mealId,
    int? receipeId,
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "user_id": ${userId},
  "meal_id": ${mealId},
  "receipe_id": ${receipeId}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'add a new meal',
      apiUrl: '${baseUrl}/functions/v1/add-a-new-meal',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? newMealCal(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.adjusted_calories''',
      ));
  int? newMealProt(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.adjusted_protein''',
      ));
  int? newMealCarb(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.adjusted_carbs''',
      ));
  int? newMealFat(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.adjusted_fat''',
      ));
  List? newMealIngredients(dynamic response) => getJsonField(
        response,
        r'''$.ingredients''',
        true,
      ) as List?;
  double? newMealScaleFactor(dynamic response) =>
      castToType<double>(getJsonField(
        response,
        r'''$.scale_factor''',
      ));
  int? newMealTagretCalorie(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.target_calories_used''',
      ));
  dynamic? newMealDebugInfon(dynamic response) => getJsonField(
        response,
        r'''$.debug_info''',
      );
  String? newMealType(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.meal_type''',
      ));
  int? newMealID(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.meal_id''',
      ));
  dynamic? newMealJsonMacro(dynamic response) => getJsonField(
        response,
        r'''$.debug_info.scaled_macros''',
      );
  int? receipeID(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.debug_info.receipe_id_searched''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.ui_message''',
      ));
  bool? suucess(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.success''',
      ));
  String? error(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.error''',
      ));
}

class CustomMealCall {
  Future<ApiCallResponse> call({
    int? mealId,
    String? textInput = '',
    String? imageUrl = '',
    String? imagetest = '',
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "user_id": "${userId}",
  "meal_id": "${mealId}",
  "text_input": "${escapeStringForJson(textInput)}",
  "image_url": "${escapeStringForJson(imageUrl)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'custom meal',
      apiUrl: '${baseUrl}/functions/v1/custom_meal',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? mealID(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.meal_id''',
      ));
  String? mealSummary(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.summary''',
      ));
  int? mealCalorie(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.estimated_calories''',
      ));
  dynamic? mealMacro(dynamic response) => getJsonField(
        response,
        r'''$.macros''',
      );
  int? mealProtein(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.macros.protein''',
      ));
  int? mealCarb(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.macros.carbs''',
      ));
  int? mealFat(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.macros.fat''',
      ));
  dynamic body(dynamic response) => getJsonField(
        response,
        r'''$''',
      );
  int? mealUserID(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.meal_info.user_id''',
      ));
  String? mealDate(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.meal_info.meal_date''',
      ));
  String? mealType(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.meal_info.meal_type''',
      ));
  dynamic? mealInfo(dynamic response) => getJsonField(
        response,
        r'''$.meal_info''',
      );
  bool? succes(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.success''',
      ));
}

class MealIngredientsScaleCall {
  Future<ApiCallResponse> call({
    int? mealId,
    String? mealType = '',
    int? receipeId,
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "user_id": "${userId}",
  "meal_id": "${mealId}",
  "meal_type": "${escapeStringForJson(mealType)}",
  "receipe_id": "${receipeId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'meal ingredients scale',
      apiUrl: '${baseUrl}/functions/v1/receipe_scaling_test',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? mealID(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.test_info.meal_id''',
      ));
  List<int>? mealIds(dynamic response) => (getJsonField(
        response,
        r'''$.database_results.inserted_records[:].meal_id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  List<int>? upsertMealsId(dynamic response) => (getJsonField(
        response,
        r'''$.database_results.upserted_records[:].meal_id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
}

class ShoppingListCall {
  Future<ApiCallResponse> call({
    int? mealId,
    int? shoppingListId,
    int? mealPlanId,
    String? updateMode = '',
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "user_id": ${userId},
  "meal_id": ${mealId},
  "update_mode": "${escapeStringForJson(updateMode)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'shopping list',
      apiUrl: '${baseUrl}/functions/v1/shopping_list_test',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? mealID(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.summary.meal_id''',
      ));
  List<int>? ingredientsId(dynamic response) => (getJsonField(
        response,
        r'''$.shopping_ingredients[:].id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  int? mealPlanId(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.shopping_list.meal_plan_id''',
      ));
  int? shoppingListId(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.shopping_list.id''',
      ));
}

class DietPlanCall {
  Future<ApiCallResponse> call({
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{"user_id": "${userId}"}''';
    return ApiManager.instance.makeApiCall(
      callName: 'diet plan',
      apiUrl: '${baseUrl}/functions/v1/diet-plan-generation',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  bool? success(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.success''',
      ));
  String? errorMessage(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.error_message''',
      ));
  String? missingTable(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.missing_table''',
      ));
  List<String>? missingField(dynamic response) => (getJsonField(
        response,
        r'''$.missing_fields''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? tables(dynamic response) => (getJsonField(
        response,
        r'''$.missing_tables''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class PersonalMealPlanCall {
  Future<ApiCallResponse> call({
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "user_id": "${userId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'personal meal plan',
      apiUrl: '${baseUrl}/functions/v1/personnal-meal-plan',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? startDate(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.start_date''',
      ));
  String? endDate(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.end_date''',
      ));
  String? action(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.action''',
      ));
  int? mealPlanId(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.meal_plan_id''',
      ));
  String? error(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.error''',
      ));
  String? reason(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.reason''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.ui_message''',
      ));
  String? missingField(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.missing_field''',
      ));
}

class CustomSnackCall {
  Future<ApiCallResponse> call({
    String? mealDay = '',
    int? mealPlanId,
    String? textInput = '',
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "meal_plan_id": "${mealPlanId}",
  "day": "${escapeStringForJson(mealDay)}",
  "text_input": "${escapeStringForJson(textInput)}",
  "user_id": "${userId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'custom snack',
      apiUrl: '${baseUrl}/functions/v1/custom_snack',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? mealID(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.meal_id''',
      ));
}

class MealPlanScaleCall {
  Future<ApiCallResponse> call({
    int? mealPlanId,
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "user_id": "${userId}",
  "meal_plan_id": "${mealPlanId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'meal plan scale',
      apiUrl: '${baseUrl}/functions/v1/meal_plan_meal_scalling',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? mealPlanId(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.meal_plan.id''',
      ));
}

class MealPlanShoppingListCall {
  Future<ApiCallResponse> call({
    int? mealPlanId,
    String? updateMode = '',
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "user_id": "${userId}",
  "meal_plan_id": "${mealPlanId}",
  "update_mode": "${escapeStringForJson(updateMode)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'meal plan shopping list',
      apiUrl: '${baseUrl}/functions/v1/meal_plan_shopping_list',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? shoppingListId(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.shopping_list.id''',
      ));
  List<int>? shoppingIngredientsId(dynamic response) => (getJsonField(
        response,
        r'''$.data.shopping_ingredients[:].id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  int? mealPlanId(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.summary.meal_plan_id''',
      ));
}

class SearchAConversationCall {
  Future<ApiCallResponse> call({
    int? destinedUserId,
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "user2_id": "${userId}",
  "user1_id": "${destinedUserId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'search a conversation',
      apiUrl: '${baseUrl}/functions/v1/get-a-chat-between-2-users',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  bool? found(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.found''',
      ));
  int? conversationId(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.conversation_id''',
      ));
}

class FindOrCreateTheConversationCall {
  Future<ApiCallResponse> call({
    int? destinedUserId,
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "user1_id": "${userId}",
  "user2_id": "${destinedUserId}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'find or create the conversation',
      apiUrl: '${baseUrl}/functions/v1/find-or-create-a-conversation-',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? conversationId(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.conversation_id''',
      ));
  bool? created(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.created''',
      ));
}

class CheckIfAUserIsInAGroupCall {
  Future<ApiCallResponse> call({
    int? conversationId,
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "user_id": ${userId},
  "conversation_id": ${conversationId}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'check if a user is in a group',
      apiUrl: '${baseUrl}/functions/v1/check_users_group',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  bool? result(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.result''',
      ));
}

class CreateAReferralCall {
  Future<ApiCallResponse> call({
    String? name = '',
    String? customName = '',
    String? action = '',
    String? firebaseAuthId = '',
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "action": "${escapeStringForJson(action)}",
  "custom_name": "${escapeStringForJson(customName)}",
  "name": "${escapeStringForJson(name)}",
  "firebase_auth_id": "${escapeStringForJson(firebaseAuthId)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'create a referral',
      apiUrl: '${baseUrl}/functions/v1/get_-a_referral',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class UpdatedRecipeResearchCall {
  Future<ApiCallResponse> call({
    String? name = '',
    int? calMin = 0,
    int? calMax = 6000,
    bool? sansPorc,
    dynamic? typeJson,
    dynamic? tagsJson,
    String? foodRegion = '',
    String? orderBy = '',
    String? orderAscend = '',
    int? timeOfCooking,
    dynamic? difficultyLevelsJson,
    String? tagLogic = '',
    String? typeLogic = '',
    dynamic? bodyJson,
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final type = _serializeJson(typeJson);
    final tags = _serializeJson(tagsJson);
    final difficultyLevels = _serializeJson(difficultyLevelsJson);
    final body = _serializeJson(bodyJson);
    final ffApiRequestBody = '''
${body}''';
    return ApiManager.instance.makeApiCall(
      callName: 'updated recipe research',
      apiUrl: '${baseUrl}/functions/v1/updated_receipe_research',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  List? receipes(dynamic response) => getJsonField(
        response,
        r'''$.recipes''',
        true,
      ) as List?;
  List<int>? ids(dynamic response) => (getJsonField(
        response,
        r'''$.recipes[:].id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  List? filters(dynamic response) => getJsonField(
        response,
        r'''$.applied_filters''',
        true,
      ) as List?;
  bool? hasFilters(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.has_active_filters''',
      ));
}

class RecommandedReceipeCall {
  Future<ApiCallResponse> call({
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "user_id": ${userId}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'recommanded receipe',
      apiUrl: '${baseUrl}/functions/v1/receipe-recommandation',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  List<int>? receipeIDs(dynamic response) => (getJsonField(
        response,
        r'''$.recommendations[:].recipe_id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
}

class ChatNotiificationCall {
  Future<ApiCallResponse> call({
    int? conversationId,
    int? senderId,
    String? messageContent = '',
    int? messageId,
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "conversation_id": ${conversationId},
  "sender_user_id": ${senderId},
  "message_content": "${escapeStringForJson(messageContent)}",
  "message_id": ${messageId}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'chat notiification',
      apiUrl: '${baseUrl}/functions/v1/chat_notification',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class RequestBodyCall {
  Future<ApiCallResponse> call({
    dynamic? testJson,
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final test = _serializeJson(testJson);
    final ffApiRequestBody = '''
${test}''';
    return ApiManager.instance.makeApiCall(
      callName: 'request body',
      apiUrl: '${baseUrl}/functions/v1/body_request',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ConversationRequestCall {
  Future<ApiCallResponse> call({
    int? demandId,
    int? destinedUserId,
    int? conversationId,
    bool? grouped,
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "user_id": ${userId},
  "demand_id": ${demandId},
  "destined_user": ${destinedUserId},
  "converstion_id": ${conversationId},
  "grouped": ${grouped}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'conversation request',
      apiUrl: '${baseUrl}/functions/v1/conversation_request',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ConversationAcceptedCall {
  Future<ApiCallResponse> call({
    int? demandId,
    int? responderUserId,
    int? conversationId,
    bool? grouped,
    bool? accepted,
    int? destinedUserId,
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "demand_id": ${demandId},
  "user_id": ${userId},
  "conversation_id": ${conversationId},
  "destined_user": ${destinedUserId},
  "grouped": ${grouped},
  "accepted": ${accepted},
  "responder_user_id": ${responderUserId}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'conversation accepted',
      apiUrl: '${baseUrl}/functions/v1/conversation_accepted',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ImageRecognitionCall {
  Future<ApiCallResponse> call({
    int? mealPlanId,
    String? imageUrl = '',
    String? description = '',
    String? date = '',
    String? day = '',
    String? mealType = '',
    bool? consumed,
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "image_url": "${escapeStringForJson(imageUrl)}",
  "user_id": ${userId},
  "meal_type": "${escapeStringForJson(mealType)}",
  "meal_date": "${escapeStringForJson(date)}",
  "day": "${escapeStringForJson(day)}",
  "consumed": ${consumed},
  "description": "${escapeStringForJson(description)}",
  "meal_plan_id": ${mealPlanId}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'image recognition',
      apiUrl: '${baseUrl}/functions/v1/meal_image_recognition',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  bool? success(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.success''',
      ));
  dynamic? data(dynamic response) => getJsonField(
        response,
        r'''$.data''',
      );
  dynamic? meal(dynamic response) => getJsonField(
        response,
        r'''$.data.meal''',
      );
  int? id(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.meal.id''',
      ));
  String? name(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.meal.name''',
      ));
  int? calorie(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.meal.adjusted_calories''',
      ));
  String? date(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.meal.meal_date''',
      ));
  String? type(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.meal.meal_type''',
      ));
  int? userID(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.meal.user_id''',
      ));
  int? mealPlanID(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.meal.meal_plan_id''',
      ));
  String? day(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.meal.day''',
      ));
  bool? consumed(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.data.meal.consumed''',
      ));
  String? descrition(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.meal.description''',
      ));
  int? protein(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.meal.adjusted_protein''',
      ));
  int? carb(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.meal.adjusted_carbs''',
      ));
  int? fat(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.meal.adjusted_fat''',
      ));
  bool? personal(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.data.meal.personal''',
      ));
  String? imageURL(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.meal.image_url''',
      ));
  bool? generated(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.data.meal.generated''',
      ));
  int? confidence(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.analysis.confidence''',
      ));
}

class PersonalMealPlanNoMealCall {
  Future<ApiCallResponse> call({
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "user_id": ${userId}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'personal meal plan no meal',
      apiUrl: '${baseUrl}/functions/v1/free_personal_meal_plan',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  bool? success(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  int? mealPlanID(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.meal_plan_id''',
      ));
  int? userID(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.user_id''',
      ));
  String? startDate(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.start_date''',
      ));
  String? endDate(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.end_date''',
      ));
  bool? mealGenerated(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.meal_generated''',
      ));
  bool? ingredientGenerated(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.ingredients_generated''',
      ));
  bool? shoppingListCreated(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.shopping_list_created''',
      ));
  bool? alreadyExist(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.already_exists''',
      ));
}

class CalculateRegimeTimeCall {
  Future<ApiCallResponse> call({
    double? timeGoal,
    int? weightGoal,
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "user_id": ${userId},
  "time_goal": "${timeGoal}",
  "weight_goal": "${weightGoal}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'calculate regime time',
      apiUrl: '${baseUrl}/functions/v1/calculate-regime-time',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? mode(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.mode''',
      ));
  String? weightGoal(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.weight_goal''',
      ));
  String? time(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.time_goal_months''',
      ));
  double? weeklyWeightLoss(dynamic response) => castToType<double>(getJsonField(
        response,
        r'''$.weekly_weight_loss''',
      ));
  String? riskLevel(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.risk_level''',
      ));
  String? riskMessage(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.risk_message''',
      ));
  int? recommandedTime(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.recommended_time_months''',
      ));
}

class UserContextCall {
  Future<ApiCallResponse> call({
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "user_id": ${userId}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'userContext',
      apiUrl: '${baseUrl}/functions/v1/user_context',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  dynamic? userContext(dynamic response) => getJsonField(
        response,
        r'''$.userContext''',
      );
}

class GetAiMessageCall {
  Future<ApiCallResponse> call({
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "user_id": ${userId}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'get ai message',
      apiUrl: '${baseUrl}/functions/v1/get_ai_message',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  List? listMessage(dynamic response) => getJsonField(
        response,
        r'''$.list_ai_message''',
        true,
      ) as List?;
  List? aiMessage(dynamic response) => getJsonField(
        response,
        r'''$.list_ai_message[:].ai_chat_message''',
        true,
      ) as List?;
}

class GetChatMessagesCall {
  Future<ApiCallResponse> call({
    int? conversationId,
    int? limit,
    String? oldestTimeMessage = '',
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "conversation_id": ${conversationId},
  "limit": ${limit},
  "before_time": "${escapeStringForJson(oldestTimeMessage)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'get chat messages',
      apiUrl: '${baseUrl}/functions/v1/get-chat-messages',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  List? listMessage(dynamic response) => getJsonField(
        response,
        r'''$.messages''',
        true,
      ) as List?;
  String? oldestTim(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.oldest_time''',
      ));
  int? count(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.count''',
      ));
  bool? hasMore(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.has_more''',
      ));
}

class SendAMessageCall {
  Future<ApiCallResponse> call({
    String? content = '',
    int? conversationId,
    bool? received,
    int? userId,
    String? apiUrl,
    String? apiKey,
  }) async {
    apiUrl ??= FFDevEnvironmentValues().apiUrl;
    apiKey ??= FFDevEnvironmentValues().ApiKey;
    final baseUrl = SupabaseGroup.getBaseUrl(
      userId: userId,
      apiUrl: apiUrl,
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "user_id": ${userId},
  "conversation_id": ${conversationId},
  "content": "${escapeStringForJson(content)}",
  "received": true
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'send a message',
      apiUrl: '${baseUrl}/functions/v1/send-a-message',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  dynamic? message(dynamic response) => getJsonField(
        response,
        r'''$.message''',
      );
  int? id(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.message.id''',
      ));
  String? content(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message.content''',
      ));
  bool? success(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.success''',
      ));
  bool? received(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.message.received''',
      ));
  int? converationID(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.message.conversation_id''',
      ));
  int? userID(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.message.user_id''',
      ));
  String? createdAt(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message.created_at''',
      ));
}

/// End Supabase  Group Code

class AIassistantCall {
  static Future<ApiCallResponse> call({
    String? message = '',
    dynamic? userContextJson,
    String? apiUrl1,
    String? apiKey,
    String? conversationId = '',
    int? userId,
    dynamic? listMesagesJson,
  }) async {
    apiUrl1 ??= FFDevEnvironmentValues().apiUrl1;
    apiKey ??= FFDevEnvironmentValues().ApiKey1;

    final userContext = _serializeJson(userContextJson);
    final listMesages = _serializeJson(listMesagesJson, true);
    final ffApiRequestBody = '''
{
  "userId": ${userId},
  "message": "${escapeStringForJson(message)}",
  "userContext": ${userContext},
  "conversation_id": "${escapeStringForJson(conversationId)}",
  "conversationHistory": ${listMesages}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'AIassistant',
      apiUrl: '${apiUrl1}',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? reply(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.reply''',
      ));
  static String? conversationId(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.conversation_id''',
      ));
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  if (item is DocumentReference) {
    return item.path;
  }
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}
