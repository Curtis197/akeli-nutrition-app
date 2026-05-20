# Implementation Plan: Multimedia Support for Ingredients & Recipe Steps

**Feature**: Display images for ingredients and images/videos for recipe steps  
**Date**: March 2026  
**Author**: AI Assistant  
**Status**: Ready for Implementation  
**Based on**: Technical Audit (MULTIMEDIA_INGREDIENTS_STEPS_AUDIT.md)

---

## Overview

This implementation plan adds rich multimedia support to the Akeli platform, enabling:
- 📸 **Ingredient images** in the global ingredient database
- 📝 **Structured recipe steps** (replacing monolithic instructions text)
- 🖼️ **Multiple images per recipe step**
- 🎥 **Video support for recipe steps**
- 📤 **Creator upload tools** for media management
- 📱 **Consumer viewing experience** with galleries and video playback

---

## Architecture Changes

### Database Schema Changes

#### 1. Add Image Support to Ingredient Table

```sql
-- Migration: 20260301000004_ingredient_images.sql
ALTER TABLE ingredient 
ADD COLUMN image_url text,
ADD COLUMN image_thumbnail_url text;

CREATE INDEX idx_ingredient_category ON ingredient(category);
```

**Rationale**: 
- `image_url`: Full-resolution image for detail views
- `image_thumbnail_url`: Optimized thumbnail for lists (faster loading)

---

#### 2. Create Recipe Step Table (CRITICAL)

```sql
-- Migration: 20260301000005_recipe_steps.sql
CREATE TABLE recipe_step (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id       uuid REFERENCES recipe(id) ON DELETE CASCADE,
  step_number     int NOT NULL CHECK (step_number > 0),
  instruction     text NOT NULL,
  instruction_fr  text,  -- For language support
  instruction_en  text,
  instruction_es  text,
  instruction_pt  text,
  duration_sec    int,   -- Estimated time for this step
  sort_order      int DEFAULT 0,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now(),
  UNIQUE (recipe_id, step_number)
);

CREATE INDEX idx_recipe_step_recipe ON recipe_step(recipe_id);
CREATE INDEX idx_recipe_step_sort ON recipe_step(recipe_id, sort_order);

ALTER TABLE recipe_step ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads published recipe steps" ON recipe_step
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM recipe r 
      WHERE r.id = recipe_step.recipe_id AND r.is_published = true
    )
  );

CREATE POLICY "creator manages own recipe steps" ON recipe_step
  USING (
    recipe_id IN (
      SELECT r.id FROM recipe r
      JOIN creator c ON r.creator_id = c.id
      WHERE c.user_id = auth.uid()
    )
  );

-- Auto-update trigger
CREATE TRIGGER trg_recipe_step_updated_at
  BEFORE UPDATE ON recipe_step
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

**Key Features**:
- `step_number`: Logical ordering (Step 1, Step 2, etc.)
- `sort_order`: Fine-tuning display order within same step_number
- Multi-language support for instructions (aligns with language feature)
- Duration tracking per step

---

#### 3. Create Recipe Step Media Table

```sql
-- Migration: 20260301000005_recipe_steps.sql (continued)
CREATE TYPE media_type AS ENUM ('image', 'video');

CREATE TABLE recipe_step_media (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_step_id  uuid REFERENCES recipe_step(id) ON DELETE CASCADE,
  media_type      media_type NOT NULL DEFAULT 'image',
  url             text NOT NULL,
  thumbnail_url   text,
  caption         text,
  sort_order      int DEFAULT 0,
  width           int,
  height          int,
  duration_sec    int,  -- For videos
  file_size_bytes bigint,
  created_at      timestamptz DEFAULT now()
);

CREATE INDEX idx_recipe_step_media_step ON recipe_step_media(recipe_step_id);
CREATE INDEX idx_recipe_step_media_type ON recipe_step_media(media_type);

ALTER TABLE recipe_step_media ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads step media" ON recipe_step_media
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM recipe_step rs
      JOIN recipe r ON rs.recipe_id = r.id
      WHERE rs.id = recipe_step_media.recipe_step_id AND r.is_published = true
    )
  );

CREATE POLICY "creator manages own step media" ON recipe_step_media
  USING (
    recipe_step_id IN (
      SELECT rs.id FROM recipe_step rs
      JOIN recipe r ON rs.recipe_id = r.id
      JOIN creator c ON r.creator_id = c.id
      WHERE c.user_id = auth.uid()
    )
  );
```

**Features**:
- Supports both images and videos
- Thumbnail generation for faster previews
- Metadata storage (dimensions, duration, file size)
- Captions for accessibility

---

#### 4. Create Ingredient Media Table (Optional Enhancement)

```sql
-- Alternative: Multiple images per ingredient
CREATE TABLE ingredient_image (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ingredient_id   uuid REFERENCES ingredient(id) ON DELETE CASCADE,
  url             text NOT NULL,
  is_primary      boolean DEFAULT false,
  sort_order      int DEFAULT 0,
  created_at      timestamptz DEFAULT now()
);

CREATE INDEX idx_ingredient_image_ingredient ON ingredient_image(ingredient_id);

ALTER TABLE ingredient_image ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads ingredient images" ON ingredient_image FOR SELECT USING (true);
```

**Note**: This allows multiple angles/varieties per ingredient (e.g., whole tomato, sliced tomato)

---

#### 5. Migrate Existing Recipe Instructions to Steps

```sql
-- Migration helper function: split_instructions_into_steps
CREATE OR REPLACE FUNCTION split_instructions_into_steps()
RETURNS void AS $$
DECLARE
  rec RECORD;
  steps TEXT[];
  step_num INT;
BEGIN
  FOR rec IN SELECT id, instructions FROM recipe WHERE instructions IS NOT NULL LOOP
    -- Split by common patterns: numbered steps, newlines, etc.
    -- This is a simplified version - production should use AI for better parsing
    steps := regexp_split_to_array(rec.instructions, E'\\n\\s*(?=\\d+\\.|Step|Étape)');
    
    step_num := 1;
    FOREACH step_text IN ARRAY steps LOOP
      IF step_text IS NOT NULL AND length(trim(step_text)) > 0 THEN
        INSERT INTO recipe_step (recipe_id, step_number, instruction, sort_order)
        VALUES (rec.id, step_num, trim(step_text), step_num)
        ON CONFLICT (recipe_id, step_number) DO NOTHING;
        
        step_num := step_num + 1;
      END IF;
    END LOOP;
  END LOOP;
END;
$$ LANGUAGE plpgsql;
```

**Note**: Production migration should use AI-powered parsing for accuracy

---

### Storage Configuration (Supabase Storage)

#### Bucket Setup

```sql
-- Run via Supabase Dashboard or CLI
-- Create buckets:
-- 1. ingredient-images
-- 2. recipe-step-images
-- 3. recipe-step-videos
```

#### RLS Policies for Storage

```sql
-- Migration: 20260301000006_storage_policies.sql

-- Ingredient Images (public read, creator upload)
CREATE POLICY "Public can view ingredient images"
ON storage.objects FOR SELECT
USING (bucket_id = 'ingredient-images');

CREATE POLICY "Creators can upload ingredient images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'ingredient-images' AND
  auth.uid() IN (SELECT user_id FROM creator)
);

-- Recipe Step Media (public read for published recipes)
CREATE POLICY "Public can view recipe step media"
ON storage.objects FOR SELECT
USING (
  bucket_id IN ('recipe-step-images', 'recipe-step-videos')
);

CREATE POLICY "Creators can upload recipe step media"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id IN ('recipe-step-images', 'recipe-step-videos') AND
  auth.uid() IN (SELECT user_id FROM creator)
);
```

---

## Edge Functions

### 1. Media Upload & Processing

**File**: `/workspace/supabase/functions/process-media-upload/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  try {
    const { recipe_id, step_id, media_type, file_name, content_type } = await req.json();
    
    // Validate user is creator of recipe
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );
    
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Unauthorized');
    
    // Verify creator permissions
    const { data: recipe } = await supabase
      .from('recipe')
      .select('creator_id')
      .eq('id', recipe_id)
      .single();
    
    const { data: creator } = await supabase
      .from('creator')
      .select('user_id')
      .eq('id', recipe.creator_id)
      .eq('user_id', user.id)
      .single();
    
    if (!creator) throw new Error('Not authorized for this recipe');
    
    // Generate signed URL for upload
    const bucket = media_type === 'video' ? 'recipe-step-videos' : 'recipe-step-images';
    const path = `${recipe_id}/${step_id}/${crypto.randomUUID()}_${file_name}`;
    
    const { data: uploadUrl } = await supabase.storage
      .from(bucket)
      .createSignedUploadUrl(path);
    
    // Create media record
    const { data: media } = await supabase
      .from('recipe_step_media')
      .insert({
        recipe_step_id: step_id,
        media_type: media_type,
        url: `https://${Deno.env.get('SUPABASE_PROJECT_REF')}.supabase.co/storage/v1/object/public/${bucket}/${path}`,
        thumbnail_url: null, // Will be generated by webhook
        sort_order: 999
      })
      .select()
      .single();
    
    return new Response(JSON.stringify({ 
      uploadUrl, 
      path, 
      media 
    }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
```

---

### 2. Image Optimization Webhook

**File**: `/workspace/supabase/functions/optimize-image/index.ts`

```typescript
// Triggered by Supabase Storage upload
// Uses Sharp for image processing
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import sharp from 'npm:sharp';

serve(async (req) => {
  const { bucket, object_key } = await req.json();
  
  // Download original image
  // Resize to multiple sizes (thumbnail, medium, large)
  // Convert to WebP
  // Upload optimized versions
  // Update database with thumbnail_url
  
  return new Response(JSON.stringify({ success: true }));
});
```

---

### 3. Video Transcoding (Optional - Use Third-Party)

**Recommendation**: Use Cloudflare Stream, Mux, or AWS MediaConvert instead of self-hosting

```typescript
// File: /workspace/supabase/functions/transcode-video/index.ts
// Integration with Cloudflare Stream API
```

---

## Flutter Implementation

### Dependencies to Add

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management (already have provider)
  provider: ^6.1.1
  
  # Image Caching
  cached_network_image: ^3.3.1
  flutter_cache_manager: ^3.3.1
  
  # Video Player
  video_player: ^2.8.2
  chewie: ^1.7.4  # Better UI for video_player
  
  # Image Gallery
  photo_view: ^0.14.0  # Zoomable images
  carousel_slider: ^4.2.1
  
  # Supabase
  supabase_flutter: ^2.3.0
  
  # File Picker (for uploads)
  image_picker: ^1.0.7
  file_picker: ^6.1.1
  
  # Image Compression (for uploads)
  flutter_image_compress: ^2.1.0
```

---

### Data Models

**File**: `/workspace/lib/models/recipe_step.dart`

```dart
import 'package:flutter/foundation.dart';

enum MediaType { image, video }

class RecipeStepMedia {
  final String id;
  final String recipeStepId;
  final MediaType mediaType;
  final String url;
  final String? thumbnailUrl;
  final String? caption;
  final int? width;
  final int? height;
  final int? durationSec;
  final int sortOrder;

  RecipeStepMedia({
    required this.id,
    required this.recipeStepId,
    required this.mediaType,
    required this.url,
    this.thumbnailUrl,
    this.caption,
    this.width,
    this.height,
    this.durationSec,
    this.sortOrder = 0,
  });

  factory RecipeStepMedia.fromMap(Map<String, dynamic> map) {
    return RecipeStepMedia(
      id: map['id'] as String,
      recipeStepId: map['recipe_step_id'] as String,
      mediaType: MediaType.values.firstWhere(
        (e) => e.name == map['media_type'],
        orElse: () => MediaType.image,
      ),
      url: map['url'] as String,
      thumbnailUrl: map['thumbnail_url'] as String?,
      caption: map['caption'] as String?,
      width: map['width'] as int?,
      height: map['height'] as int?,
      durationSec: map['duration_sec'] as int?,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipe_step_id': recipeStepId,
      'media_type': mediaType.name,
      'url': url,
      'thumbnail_url': thumbnailUrl,
      'caption': caption,
      'width': width,
      'height': height,
      'duration_sec': durationSec,
      'sort_order': sortOrder,
    };
  }
}

class RecipeStep {
  final String id;
  final String recipeId;
  final int stepNumber;
  final String instruction;
  final int? durationSec;
  final int sortOrder;
  final List<RecipeStepMedia> media;

  RecipeStep({
    required this.id,
    required this.recipeId,
    required this.stepNumber,
    required this.instruction,
    this.durationSec,
    this.sortOrder = 0,
    this.media = const [],
  });

  factory RecipeStep.fromMap(Map<String, dynamic> map, {List<RecipeStepMedia>? media}) {
    return RecipeStep(
      id: map['id'] as String,
      recipeId: map['recipe_id'] as String,
      stepNumber: map['step_number'] as int,
      instruction: map['instruction'] as String,
      durationSec: map['duration_sec'] as int?,
      sortOrder: map['sort_order'] as int? ?? 0,
      media: media ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'step_number': stepNumber,
      'instruction': instruction,
      'duration_sec': durationSec,
      'sort_order': sortOrder,
    };
  }
}
```

---

**File**: `/workspace/lib/models/ingredient_with_image.dart`

```dart
class Ingredient {
  final String id;
  final String name;
  final String? nameFr;
  final String? nameEn;
  final String? nameEs;
  final String? namePt;
  final String? category;
  final String? imageUrl;
  final String? imageThumbnailUrl;
  final double? caloriesPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;

  Ingredient({
    required this.id,
    required this.name,
    this.nameFr,
    this.nameEn,
    this.nameEs,
    this.namePt,
    this.category,
    this.imageUrl,
    this.imageThumbnailUrl,
    this.caloriesPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
  });

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'] as String,
      name: map['name'] as String,
      nameFr: map['name_fr'] as String?,
      nameEn: map['name_en'] as String?,
      nameEs: map['name_es'] as String?,
      namePt: map['name_pt'] as String?,
      category: map['category'] as String?,
      imageUrl: map['image_url'] as String?,
      imageThumbnailUrl: map['image_thumbnail_url'] as String?,
      caloriesPer100g: (map['calories_per_100g'] as num?)?.toDouble(),
      proteinPer100g: (map['protein_per_100g'] as num?)?.toDouble(),
      carbsPer100g: (map['carbs_per_100g'] as num?)?.toDouble(),
      fatPer100g: (map['fat_per_100g'] as num?)?.toDouble(),
    );
  }
}
```

---

### Services

**File**: `/workspace/lib/services/media_upload_service.dart`

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaUploadService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<File?> compressImage(File imageFile) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      imageFile.absolute.path,
      '${imageFile.absolute.path}.jpg',
      quality: 80,
      minWidth: 1920,
      minHeight: 1080,
    );
    return result;
  }

  Future<Map<String, dynamic>> uploadRecipeStepMedia({
    required String recipeId,
    required String stepId,
    required bool isVideo,
    required XFile file,
  }) async {
    // Compress if image
    File? processedFile;
    if (!isVideo && kIsWeb == false) {
      processedFile = await compressImage(File(file.path));
    }

    final fileToUpload = processedFile ?? File(file.path);

    // Get signed upload URL from edge function
    final response = await _supabase.functions.invoke(
      'process-media-upload',
      body: {
        'recipe_id': recipeId,
        'step_id': stepId,
        'media_type': isVideo ? 'video' : 'image',
        'file_name': file.name,
        'content_type': isVideo ? 'video/mp4' : 'image/jpeg',
      },
    );

    final uploadUrl = response['uploadUrl'] as String;
    final path = response['path'] as String;
    final media = response['media'] as Map<String, dynamic>;

    // Upload file
    final bytes = await fileToUpload.readAsBytes();
    final uploadResponse = await Client().put(
      Uri.parse(uploadUrl),
      body: bytes,
      headers: {'Content-Type': 'application/octet-stream'},
    );

    if (uploadResponse.statusCode != 200) {
      throw Exception('Upload failed');
    }

    return media;
  }
}
```

---

### Widgets

**File**: `/workspace/lib/widgets/ingredient_list_tile.dart`

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/ingredient_with_image.dart';

class IngredientListTile extends StatelessWidget {
  final Ingredient ingredient;
  final double quantity;
  final String unit;
  final bool isOptional;

  const IngredientListTile({
    super.key,
    required this.ingredient,
    required this.quantity,
    required this.unit,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ingredient.imageThumbnailUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: ingredient.imageThumbnailUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: Icon(Icons.restaurant, color: Colors.grey[400]),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: Icon(Icons.error, color: Colors.red[300]),
                ),
              ),
            )
          : Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.restaurant, color: Colors.grey[400]),
            ),
      title: Text(
        ingredient.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          decoration: isOptional ? TextDecoration.lineThrough : null,
          color: isOptional ? Colors.grey : null,
        ),
      ),
      subtitle: Text('$quantity $unit'),
      trailing: isOptional
          ? Chip(
              label: Text('Optional', style: TextStyle(fontSize: 12)),
              backgroundColor: Colors.orange[100],
            )
          : null,
    );
  }
}
```

---

**File**: `/workspace/lib/widgets/recipe_step_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:photo_view/photo_view.dart';
import '../models/recipe_step.dart';

class RecipeStepCard extends StatefulWidget {
  final RecipeStep step;
  final int index;

  const RecipeStepCard({
    super.key,
    required this.step,
    required this.index,
  });

  @override
  State<RecipeStepCard> createState() => _RecipeStepCardState();
}

class _RecipeStepCardState extends State<RecipeStepCard> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    final videoMedia = widget.step.media
        .firstWhere((m) => m.mediaType == MediaType.video, orElse: () => widget.step.media.first);
    
    if (videoMedia.mediaType == MediaType.video) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoMedia.url));
      _videoController!.initialize().then((_) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoController!,
            autoPlay: false,
            looping: false,
            showControlsOnInitialize: true,
          );
        });
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    '${widget.index + 1}',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 12),
                if (widget.step.durationSec != null)
                  Icon(Icons.access_time, size: 16, color: Colors.grey),
                if (widget.step.durationSec != null)
                  SizedBox(width: 4),
                if (widget.step.durationSec != null)
                  Text(
                    '${widget.step.durationSec! ~/ 60} min',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ),

          // Instruction Text
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.step.instruction,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ),

          SizedBox(height: 16),

          // Media Gallery
          if (widget.step.media.isNotEmpty)
            SizedBox(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.step.media.length,
                itemBuilder: (context, index) {
                  final media = widget.step.media[index];
                  return _buildMediaItem(media);
                },
              ),
            ),

          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMediaItem(RecipeStepMedia media) {
    if (media.mediaType == MediaType.video) {
      return SizedBox(
        width: 300,
        child: _chewieController != null
            ? Chewie(controller: _chewieController!)
            : Center(child: CircularProgressIndicator()),
      );
    } else {
      return GestureDetector(
        onTap: () => _showFullImage(media.url),
        child: Padding(
          padding: EdgeInsets.only(left: 16, right: media == widget.step.media.last ? 16 : 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: media.thumbnailUrl ?? media.url,
              fit: BoxFit.cover,
              width: 300,
              height: 250,
            ),
          ),
        ),
      );
    }
  }

  void _showFullImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: PhotoView(
            imageProvider: CachedNetworkImageProvider(imageUrl),
          ),
        ),
      ),
    );
  }
}
```

---

**File**: `/workspace/lib/widgets/recipe_detail_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe_step.dart';
import '../widgets/ingredient_list_tile.dart';
import '../widgets/recipe_step_card.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Map<String, dynamic>? _recipe;
  List<RecipeStep> _steps = [];
  List<Map<String, dynamic>> _ingredients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    try {
      final supabase = Supabase.instance.client;

      // Load recipe
      final recipeResponse = await supabase
          .from('recipe')
          .select('*, creator(*)')
          .eq('id', widget.recipeId)
          .single();

      // Load steps with media
      final stepsResponse = await supabase
          .from('recipe_step')
          .select('*')
          .eq('recipe_id', widget.recipeId)
          .order('sort_order');

      final steps = (stepsResponse as List).map((s) => RecipeStep.fromMap(s)).toList();

      // Load media for each step
      for (var step in steps) {
        final mediaResponse = await supabase
            .from('recipe_step_media')
            .select('*')
            .eq('recipe_step_id', step.id)
            .order('sort_order');

        step.media = (mediaResponse as List)
            .map((m) => RecipeStepMedia.fromMap(m))
            .toList();
      }

      // Load ingredients
      final ingredientsResponse = await supabase
          .from('recipe_ingredient')
          .select('*, ingredient(*)')
          .eq('recipe_id', widget.recipeId)
          .order('sort_order');

      setState(() {
        _recipe = recipeResponse;
        _steps = steps;
        _ingredients = ingredientsResponse as List;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading recipe: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_recipe == null) {
      return Scaffold(body: Center(child: Text('Recipe not found')));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Cover Image
          SliverToBoxAdapter(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                _recipe!['cover_image_url'] ?? '',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Title & Info
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _recipe!['title'],
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoChip(Icons.timer, '${_recipe!['prep_time_min']} min prep'),
                      SizedBox(width: 8),
                      _buildInfoChip(Icons.local_fire_department, '${_recipe!['cook_time_min']} min cook'),
                      SizedBox(width: 8),
                      _buildInfoChip(Icons.people, '${_recipe!['servings']} servings'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Ingredients Section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Ingredients', style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final ri = _ingredients[index];
                final ingredient = ri['ingredient'];
                return IngredientListTile(
                  ingredient: Ingredient.fromMap(ingredient),
                  quantity: ri['quantity'],
                  unit: ri['unit'] ?? '',
                  isOptional: ri['is_optional'] ?? false,
                );
              },
              childCount: _ingredients.length,
            ),
          ),

          // Steps Section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Instructions', style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return RecipeStepCard(
                  step: _steps[index],
                  index: index,
                );
              },
              childCount: _steps.length,
            ),
          ),

          // Bottom Padding
          SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: TextStyle(fontSize: 12)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
```

---

## Implementation Phases

### Phase 1: Database & Backend (Week 1-2)

**Tasks**:
- [ ] Create migration: `20260301000004_ingredient_images.sql`
- [ ] Create migration: `20260301000005_recipe_steps.sql`
- [ ] Create migration: `20260301000006_storage_policies.sql`
- [ ] Set up Supabase Storage buckets
- [ ] Create edge function: `process-media-upload`
- [ ] Create migration helper function for splitting instructions
- [ ] Test database migrations locally
- [ ] Deploy migrations to production

**Deliverables**:
- Updated database schema
- Working storage buckets with RLS
- Media upload edge function

---

### Phase 2: Creator Upload Tools (Week 3-4)

**Tasks**:
- [ ] Build media upload service in Flutter
- [ ] Create recipe step editor UI
- [ ] Implement drag-and-drop step reordering
- [ ] Add image compression for uploads
- [ ] Build video upload with progress indicator
- [ ] Create step media gallery editor
- [ ] Add ingredient image upload (for reference data)
- [ ] Test upload flow end-to-end

**Deliverables**:
- Creator can add/edit/delete recipe steps
- Creator can upload images/videos per step
- Creator can reorder steps
- Ingredient images can be added

---

### Phase 3: Consumer Experience (Week 5-6)

**Tasks**:
- [ ] Build RecipeDetailScreen widget
- [ ] Implement IngredientListTile with images
- [ ] Create RecipeStepCard with media gallery
- [ ] Add image zoom functionality
- [ ] Integrate video player with controls
- [ ] Implement horizontal scrolling for step media
- [ ] Add step duration display
- [ ] Optimize image loading with caching
- [ ] Test on various screen sizes

**Deliverables**:
- Users can view recipes with structured steps
- Ingredient images display in lists
- Step images/videos render correctly
- Smooth scrolling and navigation

---

### Phase 4: Migration & Content (Week 7-8)

**Tasks**:
- [ ] Run AI-powered migration of existing recipes
- [ ] Manually review migrated recipes
- [ ] Seed ingredient database with images
- [ ] Create sample recipes with full multimedia
- [ ] Performance testing and optimization
- [ ] User acceptance testing
- [ ] Documentation for creators

**Deliverables**:
- All existing recipes converted to step format
- Ingredient database populated with images
- Sample content showcasing features

---

### Phase 5: Optimization & Launch (Week 9-10)

**Tasks**:
- [ ] Implement CDN integration
- [ ] Add lazy loading for images
- [ ] Optimize video streaming (HLS if needed)
- [ ] Add offline mode support
- [ ] Analytics integration
- [ ] Bug fixes and polish
- [ ] Marketing materials
- [ ] Public launch

**Deliverables**:
- Production-ready multimedia features
- Optimized performance
- Happy users! 🎉

---

## Testing Strategy

### Unit Tests
- Model serialization/deserialization
- Media upload service logic
- Image compression algorithms

### Integration Tests
- End-to-end upload flow
- Database CRUD operations
- Storage bucket access policies

### UI Tests
- Recipe detail screen rendering
- Image gallery interactions
- Video playback controls
- Responsive layout on different screens

### Performance Tests
- Image loading times
- Video buffering performance
- Memory usage with large galleries
- Network payload optimization

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Page load time | < 2s | Lighthouse |
| Image load time | < 500ms | Analytics |
| Video start time | < 1s | Analytics |
| Creator adoption | > 50% in 1 month | Upload stats |
| User engagement | +20% time on recipe | Analytics |
| Error rate | < 1% | Sentry logs |

---

## Budget Considerations

### Storage Costs (Estimated)
- **Ingredient images**: 500 ingredients × 200KB = 100MB (~$0.02/month)
- **Recipe step images**: 1000 recipes × 10 steps × 500KB = 5GB (~$1/month)
- **Recipe videos**: 500 recipes × 2 videos × 50MB = 50GB (~$10/month)
- **Total**: ~$15/month for storage

### Bandwidth Costs
- Depends on traffic, estimate $50-200/month for moderate usage

### Third-Party Services (Optional)
- **Cloudflare Stream**: $5/month + $1 per 1000 minutes
- **Image optimization API**: Free tier available

**Total Monthly Cost**: $70-230 depending on usage

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Large video files slow loading | Enforce max file size, auto-compression |
| Storage costs spiral | Set quotas, monitor usage, archive old content |
| Poor mobile performance | Lazy loading, progressive images, quality options |
| Creator upload friction | Simplify UI, bulk upload, mobile app |
| Content moderation | Automated filters + reporting system |

---

## Conclusion

This implementation plan provides a comprehensive roadmap for adding rich multimedia support to Akeli. The phased approach ensures steady progress while managing risk and cost.

**Key Success Factors**:
1. **Start with structured steps** - Foundation for all multimedia
2. **Optimize aggressively** - Images and videos must be fast
3. **Creator experience first** - Easy upload = more content
4. **Mobile-first design** - Most users will be on phones
5. **Monitor costs** - Storage and bandwidth can grow quickly

**Next Action**: Review and approve this plan → Begin Phase 1 development

---

*Document created: March 2026*  
*Author: AI Assistant*  
*Version: 1.0 - Implementation Plan*
