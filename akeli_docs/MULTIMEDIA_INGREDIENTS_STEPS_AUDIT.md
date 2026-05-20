# Technical Audit: Multimedia Support for Ingredients & Recipe Steps

**Feature Request**: Add image support for ingredients and image/video support for recipe steps  
**Date**: March 2026  
**Author**: AI Assistant  
**Status**: Audit Phase  

---

## Executive Summary

The Akeli platform currently has **limited multimedia support**:
- ✅ Recipes have a `cover_image_url` field and a separate `recipe_image` table for gallery images
- ❌ Ingredients have **NO image support** in the database
- ❌ Recipe steps/instructions are stored as a **single text blob** with no structured steps, thus no ability to attach media to individual steps

This audit identifies gaps and provides recommendations for implementing rich multimedia content.

---

## Current State Analysis

### 1. Database Schema (Supabase/PostgreSQL)

#### Recipe Table
```sql
CREATE TABLE recipe (
  id              uuid PRIMARY KEY,
  creator_id      uuid REFERENCES creator(id),
  title           text NOT NULL,
  description     text,
  instructions    text NOT NULL,          -- ⚠️ SINGLE TEXT BLOB - NO STRUCTURED STEPS
  region          text REFERENCES food_region(code),
  difficulty      text,
  prep_time_min   int,
  cook_time_min   int,
  servings        int DEFAULT 1,
  is_published    boolean DEFAULT false,
  language        text DEFAULT 'fr',
  cover_image_url text,                   -- ✅ Single cover image
  created_at      timestamptz,
  updated_at      timestamptz
);
```

**Issues**:
- `instructions` is a monolithic text field (no step-by-step structure)
- Only one cover image at recipe level
- No way to associate media with specific cooking steps

#### Recipe Image Table
```sql
CREATE TABLE recipe_image (
  id          uuid PRIMARY KEY,
  recipe_id   uuid REFERENCES recipe(id) ON DELETE CASCADE,
  url         text NOT NULL,
  sort_order  int DEFAULT 0,
  created_at  timestamptz
);
```

**Limitations**:
- Images are only associated with the recipe as a whole
- No distinction between step images, ingredient images, or general gallery
- No support for videos

#### Ingredient Table
```sql
CREATE TABLE ingredient (
  id                  uuid PRIMARY KEY,
  name                text NOT NULL,
  name_fr             text,
  name_en             text,
  name_es             text,
  name_pt             text,
  category            text REFERENCES ingredient_category(code),
  calories_per_100g   numeric(6,1),
  protein_per_100g    numeric(5,1),
  carbs_per_100g      numeric(5,1),
  fat_per_100g        numeric(5,1),
  created_at          timestamptz
);
```

**Issues**:
- ❌ **NO image URL field** for ingredient photos
- Users cannot see what ingredients look like

#### Recipe Ingredient Junction Table
```sql
CREATE TABLE recipe_ingredient (
  id            uuid PRIMARY KEY,
  recipe_id     uuid REFERENCES recipe(id) ON DELETE CASCADE,
  ingredient_id uuid REFERENCES ingredient(id),
  quantity      numeric(8,2) NOT NULL,
  unit          text REFERENCES measurement_unit(code),
  is_optional   boolean DEFAULT false,
  sort_order    int DEFAULT 0,
  created_at    timestamptz
);
```

**Limitations**:
- No ability to override ingredient image at recipe level
- No step-specific ingredient grouping

---

### 2. Flutter Frontend

#### Current File Structure
```
lib/
├── main.dart
├── core/
│   ├── localization/
│   │   └── app_locale.dart
│   ├── providers/
│   │   └── locale_provider.dart
│   └── services/
│       └── translation_service.dart
└── widgets/
    └── locale_selector.dart
```

**Observations**:
- Minimal Flutter codebase exists (mainly localization infrastructure from recent language feature)
- No recipe detail screens, ingredient lists, or cooking step UIs implemented yet
- No image caching or media playback infrastructure
- No Supabase storage integration for media uploads

**Missing Components**:
- Recipe detail widget/screen
- Ingredient list widget with image support
- Step-by-step instruction renderer
- Video player integration
- Image gallery/carousel widget
- Media upload functionality

---

### 3. Edge Functions

#### Existing Functions
- `translate-recipe`: AI-powered recipe translation using OpenAI

**Missing**:
- Media upload/processing endpoints
- Video transcoding or optimization
- Image resizing/compression
- CDN integration for media delivery

---

### 4. Storage (Supabase Storage)

**Current Status**: Unknown/Not configured

**Requirements**:
- Bucket for ingredient images
- Bucket for recipe step images
- Bucket for recipe step videos
- Automatic image optimization (WebP conversion, resizing)
- Video transcoding (HLS streaming for large videos)
- CDN integration for fast global delivery

---

## Gap Analysis

| Feature | Current State | Required State | Gap Severity |
|---------|--------------|----------------|--------------|
| Ingredient Images | ❌ Not supported | Display image per ingredient | HIGH |
| Structured Recipe Steps | ❌ Single text blob | Array of steps with order | CRITICAL |
| Step Images | ❌ Not supported | Multiple images per step | HIGH |
| Step Videos | ❌ Not supported | Embedded videos per step | MEDIUM |
| Media Upload (Creator) | ❌ Not implemented | Upload via creator dashboard | HIGH |
| Media CDN | ❌ Unknown | Optimized delivery | MEDIUM |
| Video Playback | ❌ Not implemented | In-app video player | MEDIUM |

---

## Technical Challenges

### 1. Data Migration
- Existing recipes have monolithic `instructions` text
- Need to parse/split into structured steps (may require AI assistance)
- Backward compatibility during transition

### 2. Storage Costs
- Videos are expensive to store and stream
- Need compression, transcoding, and possibly third-party video hosting (YouTube, Vimeo, Cloudflare Stream)

### 3. Performance
- Loading many images/videos can slow down recipe pages
- Need lazy loading, pagination, and progressive image loading

### 4. Content Moderation
- User-uploaded media requires moderation
- Need automated filtering + manual review workflow

### 5. Mobile Data Usage
- Videos can consume significant mobile data
- Need quality options (auto, low, medium, high)

---

## Recommendations

### Phase 1: Foundation (Critical)
1. **Restructure recipe instructions** into discrete steps
2. **Add image_url to ingredient table**
3. **Create recipe_step table** with support for text, images, videos
4. **Set up Supabase Storage buckets** with RLS policies

### Phase 2: Creator Tools (High Priority)
1. **Build media upload UI** in creator dashboard
2. **Implement image optimization** pipeline
3. **Add step editor** with drag-and-drop reordering
4. **Video upload** with progress indicators

### Phase 3: Consumer Experience (Medium Priority)
1. **Recipe detail screen** with step-by-step navigation
2. **Ingredient list** with images
3. **Image gallery** with swipe gestures
4. **Video player** with quality controls
5. **Offline mode** for downloaded recipes

### Phase 4: Optimization (Nice to Have)
1. **CDN integration** for global delivery
2. **Adaptive video streaming** (HLS)
3. **AI-generated step images** for recipes without media
4. **AR ingredient visualization** (future)

---

## Competitive Analysis

### What Competitors Do

| Platform | Ingredient Images | Step Images | Step Videos | Notes |
|----------|------------------|-------------|-------------|-------|
| Marmiton | ❌ | ✅ (per recipe) | ✅ (embedded) | Videos at recipe level |
| AllRecipes | ✅ | ✅ | ✅ | Rich multimedia |
| Tasty | ✅ | ✅ | ✅ (primary) | Video-first approach |
| Yummly | ✅ | ✅ | ✅ | Personalized media |
| Kitchen Stories | ✅ | ✅ | ✅ | High-quality production |

**Industry Standard**: 
- Ingredient images: Expected but not universal
- Step-by-step photos: Standard for quality recipes
- Video content: Increasingly expected, especially for complex techniques

---

## Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Storage costs exceed budget | HIGH | MEDIUM | Use CDN, compress aggressively, limit video length |
| Slow page load times | HIGH | HIGH | Lazy loading, progressive images, cache strategies |
| Poor video playback on mobile | MEDIUM | MEDIUM | Use adaptive streaming, test on low-end devices |
| Content moderation overhead | MEDIUM | HIGH | Automated filters + community reporting |
| Creator adoption (upload friction) | HIGH | MEDIUM | Simplify upload UX, bulk upload, mobile-friendly |

---

## Next Steps

1. **Approve audit findings** → Proceed to implementation plan
2. **Define MVP scope** → Which features for V1?
3. **Estimate storage needs** → Budget planning
4. **Choose video strategy** → Self-hosted vs third-party
5. **Design creator UX** → Upload flow wireframes

---

**Conclusion**: The current architecture requires **significant changes** to support multimedia ingredients and recipe steps. The most critical change is restructuring the `instructions` field into discrete steps. This is a foundational change that will enable all future multimedia features.

**Recommendation**: Proceed with implementation plan focusing on Phase 1 (structured steps + ingredient images) as the foundation for all other multimedia features.

---

*Document created: March 2026*  
*Author: AI Assistant*  
*Version: 1.0 - Audit Report*
