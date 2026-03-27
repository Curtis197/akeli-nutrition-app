// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class RegimeTimeStruct extends FFFirebaseStruct {
  RegimeTimeStruct({
    String? mode,
    int? currentWeight,
    String? weightGoal,
    int? totalWeightLoss,
    int? timeGoalMonths,
    double? weeklyWeightLoss,
    int? dailyCalorieDeficit,
    String? riskLevel,
    String? riskMessage,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _mode = mode,
        _currentWeight = currentWeight,
        _weightGoal = weightGoal,
        _totalWeightLoss = totalWeightLoss,
        _timeGoalMonths = timeGoalMonths,
        _weeklyWeightLoss = weeklyWeightLoss,
        _dailyCalorieDeficit = dailyCalorieDeficit,
        _riskLevel = riskLevel,
        _riskMessage = riskMessage,
        super(firestoreUtilData);

  // "mode" field.
  String? _mode;
  String get mode => _mode ?? '';
  set mode(String? val) => _mode = val;

  bool hasMode() => _mode != null;

  // "current_weight" field.
  int? _currentWeight;
  int get currentWeight => _currentWeight ?? 0;
  set currentWeight(int? val) => _currentWeight = val;

  void incrementCurrentWeight(int amount) =>
      currentWeight = currentWeight + amount;

  bool hasCurrentWeight() => _currentWeight != null;

  // "weight_goal" field.
  String? _weightGoal;
  String get weightGoal => _weightGoal ?? '';
  set weightGoal(String? val) => _weightGoal = val;

  bool hasWeightGoal() => _weightGoal != null;

  // "total_weight_loss" field.
  int? _totalWeightLoss;
  int get totalWeightLoss => _totalWeightLoss ?? 0;
  set totalWeightLoss(int? val) => _totalWeightLoss = val;

  void incrementTotalWeightLoss(int amount) =>
      totalWeightLoss = totalWeightLoss + amount;

  bool hasTotalWeightLoss() => _totalWeightLoss != null;

  // "time_goal_months" field.
  int? _timeGoalMonths;
  int get timeGoalMonths => _timeGoalMonths ?? 0;
  set timeGoalMonths(int? val) => _timeGoalMonths = val;

  void incrementTimeGoalMonths(int amount) =>
      timeGoalMonths = timeGoalMonths + amount;

  bool hasTimeGoalMonths() => _timeGoalMonths != null;

  // "weekly_weight_loss" field.
  double? _weeklyWeightLoss;
  double get weeklyWeightLoss => _weeklyWeightLoss ?? 0.0;
  set weeklyWeightLoss(double? val) => _weeklyWeightLoss = val;

  void incrementWeeklyWeightLoss(double amount) =>
      weeklyWeightLoss = weeklyWeightLoss + amount;

  bool hasWeeklyWeightLoss() => _weeklyWeightLoss != null;

  // "daily_calorie_deficit" field.
  int? _dailyCalorieDeficit;
  int get dailyCalorieDeficit => _dailyCalorieDeficit ?? 0;
  set dailyCalorieDeficit(int? val) => _dailyCalorieDeficit = val;

  void incrementDailyCalorieDeficit(int amount) =>
      dailyCalorieDeficit = dailyCalorieDeficit + amount;

  bool hasDailyCalorieDeficit() => _dailyCalorieDeficit != null;

  // "risk_level" field.
  String? _riskLevel;
  String get riskLevel => _riskLevel ?? '';
  set riskLevel(String? val) => _riskLevel = val;

  bool hasRiskLevel() => _riskLevel != null;

  // "risk_message" field.
  String? _riskMessage;
  String get riskMessage => _riskMessage ?? '';
  set riskMessage(String? val) => _riskMessage = val;

  bool hasRiskMessage() => _riskMessage != null;

  static RegimeTimeStruct fromMap(Map<String, dynamic> data) =>
      RegimeTimeStruct(
        mode: data['mode'] as String?,
        currentWeight: castToType<int>(data['current_weight']),
        weightGoal: data['weight_goal'] as String?,
        totalWeightLoss: castToType<int>(data['total_weight_loss']),
        timeGoalMonths: castToType<int>(data['time_goal_months']),
        weeklyWeightLoss: castToType<double>(data['weekly_weight_loss']),
        dailyCalorieDeficit: castToType<int>(data['daily_calorie_deficit']),
        riskLevel: data['risk_level'] as String?,
        riskMessage: data['risk_message'] as String?,
      );

  static RegimeTimeStruct? maybeFromMap(dynamic data) => data is Map
      ? RegimeTimeStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'mode': _mode,
        'current_weight': _currentWeight,
        'weight_goal': _weightGoal,
        'total_weight_loss': _totalWeightLoss,
        'time_goal_months': _timeGoalMonths,
        'weekly_weight_loss': _weeklyWeightLoss,
        'daily_calorie_deficit': _dailyCalorieDeficit,
        'risk_level': _riskLevel,
        'risk_message': _riskMessage,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'mode': serializeParam(
          _mode,
          ParamType.String,
        ),
        'current_weight': serializeParam(
          _currentWeight,
          ParamType.int,
        ),
        'weight_goal': serializeParam(
          _weightGoal,
          ParamType.String,
        ),
        'total_weight_loss': serializeParam(
          _totalWeightLoss,
          ParamType.int,
        ),
        'time_goal_months': serializeParam(
          _timeGoalMonths,
          ParamType.int,
        ),
        'weekly_weight_loss': serializeParam(
          _weeklyWeightLoss,
          ParamType.double,
        ),
        'daily_calorie_deficit': serializeParam(
          _dailyCalorieDeficit,
          ParamType.int,
        ),
        'risk_level': serializeParam(
          _riskLevel,
          ParamType.String,
        ),
        'risk_message': serializeParam(
          _riskMessage,
          ParamType.String,
        ),
      }.withoutNulls;

  static RegimeTimeStruct fromSerializableMap(Map<String, dynamic> data) =>
      RegimeTimeStruct(
        mode: deserializeParam(
          data['mode'],
          ParamType.String,
          false,
        ),
        currentWeight: deserializeParam(
          data['current_weight'],
          ParamType.int,
          false,
        ),
        weightGoal: deserializeParam(
          data['weight_goal'],
          ParamType.String,
          false,
        ),
        totalWeightLoss: deserializeParam(
          data['total_weight_loss'],
          ParamType.int,
          false,
        ),
        timeGoalMonths: deserializeParam(
          data['time_goal_months'],
          ParamType.int,
          false,
        ),
        weeklyWeightLoss: deserializeParam(
          data['weekly_weight_loss'],
          ParamType.double,
          false,
        ),
        dailyCalorieDeficit: deserializeParam(
          data['daily_calorie_deficit'],
          ParamType.int,
          false,
        ),
        riskLevel: deserializeParam(
          data['risk_level'],
          ParamType.String,
          false,
        ),
        riskMessage: deserializeParam(
          data['risk_message'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'RegimeTimeStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is RegimeTimeStruct &&
        mode == other.mode &&
        currentWeight == other.currentWeight &&
        weightGoal == other.weightGoal &&
        totalWeightLoss == other.totalWeightLoss &&
        timeGoalMonths == other.timeGoalMonths &&
        weeklyWeightLoss == other.weeklyWeightLoss &&
        dailyCalorieDeficit == other.dailyCalorieDeficit &&
        riskLevel == other.riskLevel &&
        riskMessage == other.riskMessage;
  }

  @override
  int get hashCode => const ListEquality().hash([
        mode,
        currentWeight,
        weightGoal,
        totalWeightLoss,
        timeGoalMonths,
        weeklyWeightLoss,
        dailyCalorieDeficit,
        riskLevel,
        riskMessage
      ]);
}

RegimeTimeStruct createRegimeTimeStruct({
  String? mode,
  int? currentWeight,
  String? weightGoal,
  int? totalWeightLoss,
  int? timeGoalMonths,
  double? weeklyWeightLoss,
  int? dailyCalorieDeficit,
  String? riskLevel,
  String? riskMessage,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    RegimeTimeStruct(
      mode: mode,
      currentWeight: currentWeight,
      weightGoal: weightGoal,
      totalWeightLoss: totalWeightLoss,
      timeGoalMonths: timeGoalMonths,
      weeklyWeightLoss: weeklyWeightLoss,
      dailyCalorieDeficit: dailyCalorieDeficit,
      riskLevel: riskLevel,
      riskMessage: riskMessage,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

RegimeTimeStruct? updateRegimeTimeStruct(
  RegimeTimeStruct? regimeTime, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    regimeTime
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addRegimeTimeStructData(
  Map<String, dynamic> firestoreData,
  RegimeTimeStruct? regimeTime,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (regimeTime == null) {
    return;
  }
  if (regimeTime.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && regimeTime.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final regimeTimeData = getRegimeTimeFirestoreData(regimeTime, forFieldValue);
  final nestedData = regimeTimeData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = regimeTime.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getRegimeTimeFirestoreData(
  RegimeTimeStruct? regimeTime, [
  bool forFieldValue = false,
]) {
  if (regimeTime == null) {
    return {};
  }
  final firestoreData = mapToFirestore(regimeTime.toMap());

  // Add any Firestore field values
  regimeTime.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getRegimeTimeListFirestoreData(
  List<RegimeTimeStruct>? regimeTimes,
) =>
    regimeTimes?.map((e) => getRegimeTimeFirestoreData(e, true)).toList() ?? [];
