import 'dart:convert';
import 'package:flutter/services.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFDevEnvironmentValues {
  static const String currentEnvironment = 'Production';
  static const String environmentValuesPath =
      'assets/environment_values/environment.json';

  static final FFDevEnvironmentValues _instance =
      FFDevEnvironmentValues._internal();

  factory FFDevEnvironmentValues() {
    return _instance;
  }

  FFDevEnvironmentValues._internal();

  Future<void> initialize() async {
    try {
      final String response =
          await rootBundle.loadString(environmentValuesPath);
      final data = await json.decode(response);
      _apiUrl1 = data['apiUrl1'];
      _apiUrl2 = data['apiUrl2'];
      _ApiKey1 = data['ApiKey1'];
      _ApiKey2 = data['ApiKey2'];
      _ApiKey = data['ApiKey'];
      _apiUrl = data['apiUrl'];
      _GeminiApiKey = data['GeminiApiKey'];
    } catch (e) {
      print('Error loading environment values: $e');
    }
  }

  String _apiUrl1 = '';
  String get apiUrl1 => _apiUrl1;

  String _apiUrl2 = '';
  String get apiUrl2 => _apiUrl2;

  String _ApiKey1 = '';
  String get ApiKey1 => _ApiKey1;

  String _ApiKey2 = '';
  String get ApiKey2 => _ApiKey2;

  String _ApiKey = '';
  String get ApiKey => _ApiKey;

  String _apiUrl = '';
  String get apiUrl => _apiUrl;

  String _GeminiApiKey = '';
  String get GeminiApiKey => _GeminiApiKey;
}
