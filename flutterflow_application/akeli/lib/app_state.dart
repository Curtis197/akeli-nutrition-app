import 'package:flutter/material.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/api_requests/api_manager.dart';
import 'backend/supabase/supabase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'dart:convert';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {}

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  int _mealID = 0;
  int get mealID => _mealID;
  set mealID(int value) {
    _mealID = value;
  }

  int _newSnack = 0;
  int get newSnack => _newSnack;
  set newSnack(int value) {
    _newSnack = value;
  }

  bool _snack = false;
  bool get snack => _snack;
  set snack(bool value) {
    _snack = value;
  }

  bool _trialOver = false;
  bool get trialOver => _trialOver;
  set trialOver(bool value) {
    _trialOver = value;
  }

  List<String> _tags = [];
  List<String> get tags => _tags;
  set tags(List<String> value) {
    _tags = value;
  }

  void addToTags(String value) {
    tags.add(value);
  }

  void removeFromTags(String value) {
    tags.remove(value);
  }

  void removeAtIndexFromTags(int index) {
    tags.removeAt(index);
  }

  void updateTagsAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    tags[index] = updateFn(_tags[index]);
  }

  void insertAtIndexInTags(int index, String value) {
    tags.insert(index, value);
  }

  int _calMin = 0;
  int get calMin => _calMin;
  set calMin(int value) {
    _calMin = value;
  }

  int _calMax = 6000000;
  int get calMax => _calMax;
  set calMax(int value) {
    _calMax = value;
  }

  bool _sansPorc = false;
  bool get sansPorc => _sansPorc;
  set sansPorc(bool value) {
    _sansPorc = value;
  }

  List<String> _type = [];
  List<String> get type => _type;
  set type(List<String> value) {
    _type = value;
  }

  void addToType(String value) {
    type.add(value);
  }

  void removeFromType(String value) {
    type.remove(value);
  }

  void removeAtIndexFromType(int index) {
    type.removeAt(index);
  }

  void updateTypeAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    type[index] = updateFn(_type[index]);
  }

  void insertAtIndexInType(int index, String value) {
    type.insert(index, value);
  }

  String _orderBy = '';
  String get orderBy => _orderBy;
  set orderBy(String value) {
    _orderBy = value;
  }

  String _orderAscend = '';
  String get orderAscend => _orderAscend;
  set orderAscend(String value) {
    _orderAscend = value;
  }

  String _tagJSON = '';
  String get tagJSON => _tagJSON;
  set tagJSON(String value) {
    _tagJSON = value;
  }

  List<String> _tagsJSON = [];
  List<String> get tagsJSON => _tagsJSON;
  set tagsJSON(List<String> value) {
    _tagsJSON = value;
  }

  void addToTagsJSON(String value) {
    tagsJSON.add(value);
  }

  void removeFromTagsJSON(String value) {
    tagsJSON.remove(value);
  }

  void removeAtIndexFromTagsJSON(int index) {
    tagsJSON.removeAt(index);
  }

  void updateTagsJSONAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    tagsJSON[index] = updateFn(_tagsJSON[index]);
  }

  void insertAtIndexInTagsJSON(int index, String value) {
    tagsJSON.insert(index, value);
  }

  List<int> _readby = [];
  List<int> get readby => _readby;
  set readby(List<int> value) {
    _readby = value;
  }

  void addToReadby(int value) {
    readby.add(value);
  }

  void removeFromReadby(int value) {
    readby.remove(value);
  }

  void removeAtIndexFromReadby(int index) {
    readby.removeAt(index);
  }

  void updateReadbyAtIndex(
    int index,
    int Function(int) updateFn,
  ) {
    readby[index] = updateFn(_readby[index]);
  }

  void insertAtIndexInReadby(int index, int value) {
    readby.insert(index, value);
  }

  List<int> _conversationParticipants = [];
  List<int> get conversationParticipants => _conversationParticipants;
  set conversationParticipants(List<int> value) {
    _conversationParticipants = value;
  }

  void addToConversationParticipants(int value) {
    conversationParticipants.add(value);
  }

  void removeFromConversationParticipants(int value) {
    conversationParticipants.remove(value);
  }

  void removeAtIndexFromConversationParticipants(int index) {
    conversationParticipants.removeAt(index);
  }

  void updateConversationParticipantsAtIndex(
    int index,
    int Function(int) updateFn,
  ) {
    conversationParticipants[index] =
        updateFn(_conversationParticipants[index]);
  }

  void insertAtIndexInConversationParticipants(int index, int value) {
    conversationParticipants.insert(index, value);
  }

  bool _TypeAndOr = false;
  bool get TypeAndOr => _TypeAndOr;
  set TypeAndOr(bool value) {
    _TypeAndOr = value;
  }

  bool _TagAndOR = false;
  bool get TagAndOR => _TagAndOR;
  set TagAndOR(bool value) {
    _TagAndOR = value;
  }

  int _cookingTIme = 600000;
  int get cookingTIme => _cookingTIme;
  set cookingTIme(int value) {
    _cookingTIme = value;
  }

  List<String> _dificulty = [];
  List<String> get dificulty => _dificulty;
  set dificulty(List<String> value) {
    _dificulty = value;
  }

  void addToDificulty(String value) {
    dificulty.add(value);
  }

  void removeFromDificulty(String value) {
    dificulty.remove(value);
  }

  void removeAtIndexFromDificulty(int index) {
    dificulty.removeAt(index);
  }

  void updateDificultyAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    dificulty[index] = updateFn(_dificulty[index]);
  }

  void insertAtIndexInDificulty(int index, String value) {
    dificulty.insert(index, value);
  }

  List<String> _foodRegion = [];
  List<String> get foodRegion => _foodRegion;
  set foodRegion(List<String> value) {
    _foodRegion = value;
  }

  void addToFoodRegion(String value) {
    foodRegion.add(value);
  }

  void removeFromFoodRegion(String value) {
    foodRegion.remove(value);
  }

  void removeAtIndexFromFoodRegion(int index) {
    foodRegion.removeAt(index);
  }

  void updateFoodRegionAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    foodRegion[index] = updateFn(_foodRegion[index]);
  }

  void insertAtIndexInFoodRegion(int index, String value) {
    foodRegion.insert(index, value);
  }

  dynamic _foodRegionJson;
  dynamic get foodRegionJson => _foodRegionJson;
  set foodRegionJson(dynamic value) {
    _foodRegionJson = value;
  }

  dynamic _difficultyJson;
  dynamic get difficultyJson => _difficultyJson;
  set difficultyJson(dynamic value) {
    _difficultyJson = value;
  }

  dynamic _typeJson;
  dynamic get typeJson => _typeJson;
  set typeJson(dynamic value) {
    _typeJson = value;
  }

  bool _ordering = false;
  bool get ordering => _ordering;
  set ordering(bool value) {
    _ordering = value;
  }

  bool _orderMenu = false;
  bool get orderMenu => _orderMenu;
  set orderMenu(bool value) {
    _orderMenu = value;
  }

  bool _filtering = false;
  bool get filtering => _filtering;
  set filtering(bool value) {
    _filtering = value;
  }

  dynamic _receipeReserchResponse;
  dynamic get receipeReserchResponse => _receipeReserchResponse;
  set receipeReserchResponse(dynamic value) {
    _receipeReserchResponse = value;
  }

  List<dynamic> _receipes = [];
  List<dynamic> get receipes => _receipes;
  set receipes(List<dynamic> value) {
    _receipes = value;
  }

  void addToReceipes(dynamic value) {
    receipes.add(value);
  }

  void removeFromReceipes(dynamic value) {
    receipes.remove(value);
  }

  void removeAtIndexFromReceipes(int index) {
    receipes.removeAt(index);
  }

  void updateReceipesAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    receipes[index] = updateFn(_receipes[index]);
  }

  void insertAtIndexInReceipes(int index, dynamic value) {
    receipes.insert(index, value);
  }

  String _name = '';
  String get name => _name;
  set name(String value) {
    _name = value;
  }

  String _typeLogic = 'OR';
  String get typeLogic => _typeLogic;
  set typeLogic(String value) {
    _typeLogic = value;
  }

  String _tagLogic = 'OR';
  String get tagLogic => _tagLogic;
  set tagLogic(String value) {
    _tagLogic = value;
  }

  List<dynamic> _filter = [];
  List<dynamic> get filter => _filter;
  set filter(List<dynamic> value) {
    _filter = value;
  }

  void addToFilter(dynamic value) {
    filter.add(value);
  }

  void removeFromFilter(dynamic value) {
    filter.remove(value);
  }

  void removeAtIndexFromFilter(int index) {
    filter.removeAt(index);
  }

  void updateFilterAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    filter[index] = updateFn(_filter[index]);
  }

  void insertAtIndexInFilter(int index, dynamic value) {
    filter.insert(index, value);
  }

  String _hasFilters = '';
  String get hasFilters => _hasFilters;
  set hasFilters(String value) {
    _hasFilters = value;
  }

  String _calGte = '';
  String get calGte => _calGte;
  set calGte(String value) {
    _calGte = value;
  }

  int _mealPlan = 0;
  int get mealPlan => _mealPlan;
  set mealPlan(int value) {
    _mealPlan = value;
  }

  List<String> _missingTable = [];
  List<String> get missingTable => _missingTable;
  set missingTable(List<String> value) {
    _missingTable = value;
  }

  void addToMissingTable(String value) {
    missingTable.add(value);
  }

  void removeFromMissingTable(String value) {
    missingTable.remove(value);
  }

  void removeAtIndexFromMissingTable(int index) {
    missingTable.removeAt(index);
  }

  void updateMissingTableAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    missingTable[index] = updateFn(_missingTable[index]);
  }

  void insertAtIndexInMissingTable(int index, String value) {
    missingTable.insert(index, value);
  }

  String _sex = 'sex';
  String get sex => _sex;
  set sex(String value) {
    _sex = value;
  }

  String _weight = 'weight';
  String get weight => _weight;
  set weight(String value) {
    _weight = value;
  }

  String _height = 'height';
  String get height => _height;
  set height(String value) {
    _height = value;
  }

  String _age = 'age';
  String get age => _age;
  set age(String value) {
    _age = value;
  }

  String _activityLevels = 'activity_level';
  String get activityLevels => _activityLevels;
  set activityLevels(String value) {
    _activityLevels = value;
  }

  String _targetWeight = 'target_weight';
  String get targetWeight => _targetWeight;
  set targetWeight(String value) {
    _targetWeight = value;
  }

  String _objectif = 'objectif';
  String get objectif => _objectif;
  set objectif(String value) {
    _objectif = value;
  }

  String _userGoal = 'user_goal';
  String get userGoal => _userGoal;
  set userGoal(String value) {
    _userGoal = value;
  }

  String _userParameter = 'user_health_parameter';
  String get userParameter => _userParameter;
  set userParameter(String value) {
    _userParameter = value;
  }

  List<String> _missingField = [];
  List<String> get missingField => _missingField;
  set missingField(List<String> value) {
    _missingField = value;
  }

  void addToMissingField(String value) {
    missingField.add(value);
  }

  void removeFromMissingField(String value) {
    missingField.remove(value);
  }

  void removeAtIndexFromMissingField(int index) {
    missingField.removeAt(index);
  }

  void updateMissingFieldAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    missingField[index] = updateFn(_missingField[index]);
  }

  void insertAtIndexInMissingField(int index, String value) {
    missingField.insert(index, value);
  }

  List<String> _allergies = [];
  List<String> get allergies => _allergies;
  set allergies(List<String> value) {
    _allergies = value;
  }

  void addToAllergies(String value) {
    allergies.add(value);
  }

  void removeFromAllergies(String value) {
    allergies.remove(value);
  }

  void removeAtIndexFromAllergies(int index) {
    allergies.removeAt(index);
  }

  void updateAllergiesAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    allergies[index] = updateFn(_allergies[index]);
  }

  void insertAtIndexInAllergies(int index, String value) {
    allergies.insert(index, value);
  }

  double _targetProtein = 0.0;
  double get targetProtein => _targetProtein;
  set targetProtein(double value) {
    _targetProtein = value;
  }

  double _tagetCarb = 0.0;
  double get tagetCarb => _tagetCarb;
  set tagetCarb(double value) {
    _tagetCarb = value;
  }

  double _targetFat = 0.0;
  double get targetFat => _targetFat;
  set targetFat(double value) {
    _targetFat = value;
  }

  bool _userHalal = false;
  bool get userHalal => _userHalal;
  set userHalal(bool value) {
    _userHalal = value;
  }

  String _userFavoritRegion = '';
  String get userFavoritRegion => _userFavoritRegion;
  set userFavoritRegion(String value) {
    _userFavoritRegion = value;
  }

  double _userWeight = 0.0;
  double get userWeight => _userWeight;
  set userWeight(double value) {
    _userWeight = value;
  }

  double _UserTagetWeight = 0.0;
  double get UserTagetWeight => _UserTagetWeight;
  set UserTagetWeight(double value) {
    _UserTagetWeight = value;
  }

  double _userHeight = 0.0;
  double get userHeight => _userHeight;
  set userHeight(double value) {
    _userHeight = value;
  }

  double _userIMC = 0.0;
  double get userIMC => _userIMC;
  set userIMC(double value) {
    _userIMC = value;
  }

  String _userActivityLevel = '';
  String get userActivityLevel => _userActivityLevel;
  set userActivityLevel(String value) {
    _userActivityLevel = value;
  }

  String _userSex = '';
  String get userSex => _userSex;
  set userSex(String value) {
    _userSex = value;
  }

  dynamic _userContext;
  dynamic get userContext => _userContext;
  set userContext(dynamic value) {
    _userContext = value;
  }

  String _conversationId = '';
  String get conversationId => _conversationId;
  set conversationId(String value) {
    _conversationId = value;
  }

  bool _messagePending = false;
  bool get messagePending => _messagePending;
  set messagePending(bool value) {
    _messagePending = value;
  }

  bool _messageSucceded = false;
  bool get messageSucceded => _messageSucceded;
  set messageSucceded(bool value) {
    _messageSucceded = value;
  }

  int _displayedWeight = 0;
  int get displayedWeight => _displayedWeight;
  set displayedWeight(int value) {
    _displayedWeight = value;
  }
}
