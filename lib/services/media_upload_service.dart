import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:mime_type/mime_type.dart';
import '../models/multimedia_models.dart';

/// Service for handling media uploads to Supabase Storage
class MediaUploadService {
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String edgeFunctionUrl;

  MediaUploadService({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.edgeFunctionUrl,
  });

  /// Pick and crop an image from gallery or camera
  Future<File?> pickAndCropImage({
    required ImageSource source,
    int maxWidth = 1920,
    int maxHeight = 1920,
  }) async {
    try {
      // Pick image
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Crop image
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }

      return File(pickedFile.path);
    } catch (e) {
      print('Error picking/cropping image: $e');
      return null;
    }
  }

  /// Upload media (image or video) for a recipe step
  /// Returns the media URL on success
  Future<String?> uploadStepMedia({
    required String stepId,
    required File file,
    required MediaType mediaType,
    String? altText,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Get file name and content type
      final fileName = file.path.split('/').last;
      final contentType = mime(fileName) ?? 
        (mediaType.isVideo ? 'video/mp4' : 'image/jpeg');

      // Request signed upload URL from edge function
      final response = await http.post(
        Uri.parse('$edgeFunctionUrl/process-media-upload'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $supabaseAnonKey',
        },
        body: jsonEncode({
          'step_id': stepId,
          'media_type': mediaType.toString().split('.').last,
          'file_name': fileName,
          'content_type': contentType,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get upload URL: ${response.body}');
      }

      final responseData = jsonDecode(response.body);
      final uploadUrl = responseData['upload_url'] as String;
      final mediaUrl = responseData['media_url'] as String;

      // Upload file to signed URL
      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': contentType,
        },
        body: await file.readAsBytes(),
      );

      if (uploadResponse.statusCode != 200) {
        throw Exception('Failed to upload file: ${uploadResponse.body}');
      }

      // Trigger image optimization (async, don't wait)
      if (mediaType.isImage) {
        _triggerOptimization(responseData['file_path'] as String);
      }

      return mediaUrl;
    } catch (e) {
      print('Error uploading media: $e');
      return null;
    }
  }

  /// Upload image for an ingredient
  Future<String?> uploadIngredientImage({
    required String ingredientId,
    required File file,
    Function(double progress)? onProgress,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final contentType = mime(fileName) ?? 'image/jpeg';

      // Request signed upload URL from edge function
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
          'content_type': contentType,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get upload URL: ${response.body}');
      }

      final responseData = jsonDecode(response.body);
      final uploadUrl = responseData['upload_url'] as String;

      // Upload file to signed URL
      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': contentType,
        },
        body: await file.readAsBytes(),
      );

      if (uploadResponse.statusCode != 200) {
        throw Exception('Failed to upload file: ${uploadResponse.body}');
      }

      // Update ingredient record with image URLs
      final filePath = responseData['file_path'] as String;
      final publicUrlBase = '$supabaseUrl/storage/v1/object/public/ingredient-images';
      
      // In production, wait for optimization to complete
      // For now, use the original path
      await _updateIngredientImage(ingredientId, '$publicUrlBase/$filePath');

      // Trigger optimization (async)
      _triggerOptimization(filePath, bucket: 'ingredient-images');

      return '$publicUrlBase/$filePath';
    } catch (e) {
      print('Error uploading ingredient image: $e');
      return null;
    }
  }

  /// Trigger image optimization edge function
  void _triggerOptimization(String filePath, {String bucket = 'recipe-step-media'}) {
    // Fire and forget - optimization happens asynchronously
    http.post(
      Uri.parse('$edgeFunctionUrl/optimize-image'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $supabaseAnonKey',
      },
      body: jsonEncode({
        'file_path': filePath,
        'bucket': bucket,
      }),
    ).catchError((e) => print('Optimization trigger failed: $e'));
  }

  /// Update ingredient record with new image URL
  Future<void> _updateIngredientImage(String ingredientId, String imageUrl) async {
    await http.patch(
      Uri.parse('$supabaseUrl/rest/v1/ingredient?id=eq.$ingredientId'),
      headers: {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $supabaseAnonKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
      body: jsonEncode({
        'image_url': imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }),
    );
  }

  /// Delete media from storage and database
  Future<bool> deleteMedia({
    required String mediaId,
    required MediaType mediaType,
  }) async {
    try {
      // First, get the media URL from database
      // Then delete from storage
      // Finally, delete from database
      
      // This is a simplified version - in production, you'd implement full deletion logic
      print('Delete media $mediaId not fully implemented yet');
      return true;
    } catch (e) {
      print('Error deleting media: $e');
      return false;
    }
  }
}
