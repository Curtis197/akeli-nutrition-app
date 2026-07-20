import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/logger.dart';
import '../models/multimedia_models.dart';

final _logger = appLogger;

/// Service for handling media uploads to Supabase Storage via edge functions
class MediaUploadService {
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String edgeFunctionUrl;

  MediaUploadService({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.edgeFunctionUrl,
  });

  /// Pick an image from gallery or camera
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    _logger.userAction('Pick image tapped | source: $source', screen: 'MediaUploadService');
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e, st) {
      _logger.edge('process-media-upload', 'ERROR | pickImage | $e', error: e, stackTrace: st);
      return null;
    }
  }

  /// Upload media for a recipe step. Returns the media URL on success.
  Future<String?> uploadStepMedia({
    required String stepId,
    required File file,
    required MediaType mediaType,
  }) async {
    final fileName = file.path.split('/').last;
    final contentType = mediaType.isVideo ? 'video/mp4' : 'image/jpeg';

    _logger.edge('process-media-upload', 'BEFORE | stepId: $stepId | file: $fileName');
    try {
      final response = await http.post(
        Uri.parse('$edgeFunctionUrl/process-media-upload'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $supabaseAnonKey',
        },
        body: jsonEncode({
          'step_id': stepId,
          'media_type': mediaType.isVideo ? 'video' : 'image',
          'file_name': fileName,
          'content_type': contentType,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get upload URL: ${response.body}');
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      final uploadUrl = responseData['upload_url'] as String;
      final mediaUrl = responseData['media_url'] as String;

      await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': contentType},
        body: await file.readAsBytes(),
      );

      _logger.edge('process-media-upload', 'AFTER | url: $mediaUrl');
      return mediaUrl;
    } catch (e, st) {
      _logger.edge('process-media-upload', 'ERROR | $e', error: e, stackTrace: st);
      return null;
    }
  }

  /// Upload an ingredient image. Returns the public URL on success.
  Future<String?> uploadIngredientImage({
    required String ingredientId,
    required File file,
  }) async {
    final fileName = file.path.split('/').last;

    _logger.edge('process-media-upload', 'BEFORE | ingredientId: $ingredientId | file: $fileName');
    try {
      final response = await http.post(
        Uri.parse('$edgeFunctionUrl/process-media-upload'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $supabaseAnonKey',
        },
        body: jsonEncode({
          'ingredient_id': ingredientId,
          'media_type': 'image',
          'file_name': fileName,
          'content_type': 'image/jpeg',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get upload URL: ${response.body}');
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      final uploadUrl = responseData['upload_url'] as String;
      final filePath = responseData['file_path'] as String;
      final publicUrl = '$supabaseUrl/storage/v1/object/public/ingredient-images/$filePath';

      await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': 'image/jpeg'},
        body: await file.readAsBytes(),
      );

      _logger.edge('process-media-upload', 'AFTER | url: $publicUrl');
      return publicUrl;
    } catch (e, st) {
      _logger.edge('process-media-upload', 'ERROR | $e', error: e, stackTrace: st);
      return null;
    }
  }
}
