import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/backend.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/library_values.dart';

dynamic listToJson(
  List<String>? item,
  String? name,
) {
  // return "tags": ["tag"] tags is a json array based on a list of string (tag)
  var list = <String>[];
  return {
    name ?? "name": item ?? list,
  };
}

double? newCustomFunction(double? num) {
  // round num to 0.5
  if (num == null) return null;
  return (num * 2).round() / 2; // Rounds the number to the nearest 0.5
}

dynamic buildResearchRequest(
  String? name,
  int? calMin,
  int? calMax,
  String? type,
  String? typeLogic,
  String? tags,
  String? tagLogic,
  String? foodRegion,
  String? difficultyLevels,
  int? totalCookingTimeMinutes,
  String? orderBy,
  String? orderDirection,
  bool? sansPorc,
) {
  var list = [];
  return {
    "filters": {
      "name_like": name,
      "calorie_gte": calMin,
      "calorie_lte": calMax,
      "sans porc": sansPorc,
      "type": type,
      "type_logic": typeLogic,
      "tags": tags,
      "tag_logic": tagLogic,
      "food_region": foodRegion, // ← Single string, not list
      "food_region_like": false,
      "difficulty_levels": difficultyLevels,
      "difficulty_logic": "OR",
      "total_cooking_time_minutes_lte":
          totalCookingTimeMinutes // ← Fixed variable name
    },
    "orderBy": orderBy,
    "orderDirection": orderDirection ?? "desc"
  };
}

dynamic buildResearchRequestCopy(
  String? name,
  int? calMin,
  int? calMax,
  List<String>? type,
  String? typeLogic,
  List<String>? tags,
  String? tagLogic,
  List<String>? foodRegion,
  List<String>? difficultyLevels,
  int? totalCookingTimeMinutes,
  String? orderBy,
  String? orderDirection,
  bool? sansPorc,
) {
  var list = [];
  return {
    "filters": {
      "name_like": name,
      "calorie_gte": calMin,
      "calorie_lte": calMax,
      "sans porc": sansPorc,
      "type": type ?? [],
      "type_logic": typeLogic,
      "tags": tags ?? [],
      "tag_logic": tagLogic,
      "Food Region": foodRegion ?? [], // ← Single string, not list
      "food_region_like": false,
      "difficulty_levels": difficultyLevels ?? [],
      "difficulty_logic": "OR",
      "total_cooking_time_minutes_lte":
          totalCookingTimeMinutes // ← Fixed variable name
    },
    "orderBy": orderBy,
    "orderDirection": orderDirection ?? "desc"
  };
}

dynamic encodeJson(List<String>? item) {
  // return a json from a list of string
  if (item == null) return null; // Return null if the input list is null
  return jsonEncode(item); // Convert the list of strings to JSON
}

dynamic aiMessageJON(
  String? message,
  String? role,
  DateTime? time,
  String? status,
) {
  // create json object "ai_chat_message":{"role": role, "message":message, "time": time, "status": status}
  return {
    "ai_chat_message": {
      "role": role,
      "message": message,
      "time": time?.toIso8601String(),
      "status": status,
    }
  };
}

DateTime? ajdustedTime(DateTime? time) {
  // adjuste utc time to paris time zone
  DateTime? adjustedTime(DateTime? time) {
    if (time == null) return null;
    // Paris is UTC+1, and during daylight saving time (DST) it's UTC+2
    // Check if the date is in DST (last Sunday in March to last Sunday in October)
    bool isDST = time.isAfter(DateTime(time.year, 3, 31)
            .subtract(Duration(days: DateTime(time.year, 3, 31).weekday))) &&
        time.isBefore(DateTime(time.year, 10, 31)
            .subtract(Duration(days: DateTime(time.year, 10, 31).weekday)));

    // Adjust time to Paris timezone
    return time.toUtc().add(Duration(hours: isDST ? 2 : 1));
  }
}

dynamic chatMessage(
  DateTime? createdAtParis,
  String? content,
  int? userId,
  int? conversationId,
  bool? received,
  List<int>? readBy,
) {
  // create "chat_message":{ "created_at_paris": createdAtParis, "content":content, "user_id":userId, "received":received, "conversation_id":conversationId, "read_by": readBy}
  return {
    "created_at": createdAtParis?.toIso8601String(),
    "content": content,
    "user_id": userId,
    "received": received,
    "conversation_id": conversationId,
    "read_by": readBy,
  };
}

List<dynamic>? prependMessage(
  List<dynamic>? oldMessages,
  List<dynamic>? currentMessages,
) {
  // create "prepended_mesages": [olderMessages+currentMessages]
  if (oldMessages == null && currentMessages == null) {
    return null;
  }
  return [
    ...?oldMessages, // Spread old messages if they exist
    ...?currentMessages // Spread current messages if they exist
  ];
}

List<int>? integerToArray(int? number) {
  // convert an integer to a list of one integer
  if (number == null) return null; // Return null if the input is null
  return [number]; // Return a list containing the integer
}

DateTime? timestampzToDateTime(String? time) {
  // convert timestampz to date time
  if (time == null) return null;
  return DateTime.parse(time);
}

DateTime? timestampzToLocalDateTime(String? time) {
  // convert a timestampz string to local datetime
  if (time == null) return null;
  // Parse the timestampz string to DateTime
  DateTime utcDateTime = DateTime.parse(time);
  // Convert UTC DateTime to local DateTime
  return utcDateTime.toLocal();
}

List<int>? arrayToListInteger(dynamic array) {
  // convert an array of integer to a list of integer
  if (array is List) {
    return array
        .map((item) {
          if (item is int) {
            return item;
          }
          return null; // or handle the case where item is not an int
        })
        .whereType<int>()
        .toList();
  }
  return null; // return null if input is not a List
}

String? jsonToString(dynamic json) {
  // convert a json to a string
  try {
    return jsonEncode(json); // Convert JSON to string
  } catch (e) {
    return null; // Return null if conversion fails
  }
}

bool? jsonToBoolean(bool? json) {
  // convert a json to boolean
  return json == null ? null : json;
}

List<dynamic>? newCustomFunction2(List<ChatMessageRow>? receipe) {
  // convert a chat_messade list of  rows into a json list [{"id":0,"id":1,"created_at":"2025-05-20 17:26:46.655974+00","content":"test","user_id":1,"conversation_id":22,"received":null,"read_by":2}]
  if (receipe == null) return null;

  return receipe.map((message) {
    return {
      "id": message.id,
      "created_at": message.createdAt.toString(),
      "content": message.content,
      "user_id": message.userId,
      "conversation_id": message.conversationId,
      "received": message.received,
      "read_by": message.readBy,
    };
  }).toList();
}

List<dynamic>? restrictListJson(List<dynamic>? list) {
  // return the 10 first item
  if (list == null) return null; // Return null if the input list is null
  return list.take(10).toList(); // Return the first 10 items as a new list
}

String? formatIngredientQuantity(
  double? quantity,
  String? unit,
) {
  if (quantity == null) return '0';

  // Arrondir automatiquement
  final roundedQuantity = autoRoundIngredient(quantity);

  // Formater
  String formattedValue;

  if (roundedQuantity == roundedQuantity.toInt()) {
    formattedValue = roundedQuantity.toInt().toString();
  } else {
    formattedValue = roundedQuantity.toStringAsFixed(2);
    formattedValue = formattedValue.replaceAll(RegExp(r'0*$'), '');
    formattedValue = formattedValue.replaceAll(RegExp(r'\.$'), '');
  }

  // Ajouter l'unité
  if (unit != null && unit.isNotEmpty) {
    return '$formattedValue $unit';
  }

  return formattedValue;
}

String? smartFormatNumber(double? value) {
  if (value == null) return '0';

  if (value == value.toInt()) {
    return value.toInt().toString();
  }

  String formatted = value.toStringAsFixed(2);
  formatted = formatted.replaceAll(RegExp(r'0*$'), '');
  formatted = formatted.replaceAll(RegExp(r'\.$'), '');

  return formatted;
}

double autoRoundIngredient(double quantity) {
  // Cas spécial : 0 reste 0
  if (quantity <= 0) {
    return 0.0;
  }

  // Pour < 1, arrondir à 0.5 (demi) avec MINIMUM 0.5
  if (quantity < 1) {
    // Si entre 0 et 0.5 (exclus) → forcer à 0.5
    if (quantity < 0.5) {
      return 0.5;
    }
    // Sinon arrondir normalement à 0.5
    return (quantity * 2).round() / 2;
  }
  // Auto rounding pour >= 1
  else if (quantity < 5) {
    return (quantity * 2).round() / 2;
  } else if (quantity < 20) {
    return quantity.roundToDouble();
  } else if (quantity < 50) {
    return ((quantity / 5).round() * 5).toDouble();
  } else if (quantity < 100) {
    return ((quantity / 10).round() * 10).toDouble();
  } else if (quantity < 500) {
    return ((quantity / 25).round() * 25).toDouble();
  } else {
    return ((quantity / 50).round() * 50).toDouble();
  }
}
