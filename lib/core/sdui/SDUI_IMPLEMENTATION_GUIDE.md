# SDUI Implementation Guide - AKELI

## 🎯 Overview

This guide walks you through implementing Server-Driven UI (SDUI) in AKELI to enable dynamic mode switching between Nutrition, Beauty, and future wellness modes.

## 📁 File Structure Created

```
lib/core/sdui/
├── services/
│   ├── layout_cache_service.dart    # Hive caching for layouts
│   └── layout_fetch_service.dart    # Supabase fetching with fallbacks
├── providers/
│   └── mode_provider.dart           # Riverpod state management
└── widgets/
    ├── widget_factory.dart          # Component renderer
    └── dynamic_layout_page.dart     # Dynamic page component
```

## 🔧 Step 1: Update pubspec.yaml

✅ **Already Done** - Added dependencies:
```yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  json_annotation: ^4.9.0

dev_dependencies:
  json_serializable: ^6.8.0
  hive_generator: ^2.0.1
```

**Run on your local machine:**
```bash
cd C:\Projects\akeli-nutrition-app
flutter pub get
```

## 🗄️ Step 2: Create Supabase Table

Execute this SQL in your Supabase SQL Editor:

```sql
-- Create layouts table
CREATE TABLE layouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mode TEXT NOT NULL,
  version TEXT NOT NULL,
  layout_json JSONB NOT NULL,
  culture_tags TEXT[] DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for fast lookups
CREATE INDEX idx_layouts_mode_active ON layouts(mode, is_active);
CREATE INDEX idx_layouts_culture_tags ON layouts USING GIN(culture_tags);

-- Enable RLS
ALTER TABLE layouts ENABLE ROW LEVEL SECURITY;

-- Allow public read access (adjust for production)
CREATE POLICY "Allow public read access" ON layouts
  FOR SELECT USING (true);

-- Insert sample nutrition layout
INSERT INTO layouts (mode, version, layout_json, culture_tags, is_active)
VALUES (
  'nutrition',
  '1.0.0',
  '{
    "components": [
      {
        "type": "hero_banner",
        "config": {
          "title": "Nutrition",
          "subtitle": "Track your meals & reach your goals"
        }
      },
      {
        "type": "weight_tracker",
        "config": {
          "title": "Weight Progress"
        }
      },
      {
        "type": "calories_graph",
        "config": {
          "title": "Daily Calories"
        }
      },
      {
        "type": "cultural_tip",
        "config": {
          "tip": "In West Africa, fonio is considered a sacred grain that brings strength and vitality.",
          "origin": "Senegal"
        }
      }
    ]
  }'::jsonb,
  ARRAY['west_african', 'default'],
  true
);

-- Insert sample beauty layout
INSERT INTO layouts (mode, version, layout_json, culture_tags, is_active)
VALUES (
  'beauty',
  '1.0.0',
  '{
    "components": [
      {
        "type": "hero_banner",
        "config": {
          "title": "Beauty",
          "subtitle": "Skin & Hair Care rooted in tradition"
        }
      },
      {
        "type": "routine_grid",
        "config": {
          "title": "Your Routines",
          "routines": []
        }
      },
      {
        "type": "product_tracker",
        "config": {
          "title": "Products"
        }
      },
      {
        "type": "cultural_tip",
        "config": {
          "tip": "Shea butter has been used for centuries in Africa for its moisturizing and healing properties.",
          "origin": "Ghana"
        }
      }
    ]
  }'::jsonb,
  ARRAY['west_african', 'default'],
  true
);
```

## 🚀 Step 3: Initialize Hive in main.dart

Update your `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/sdui/services/layout_cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for SDUI caching
  await Hive.initFlutter();
  await LayoutCacheService().initialize();
  
  runApp(
    const ProviderScope(
      child: AkeliApp(),
    ),
  );
}
```

## 🔄 Step 4: Add Mode Switching to Your App

### Option A: Add Mode Selector to Existing Home Page

Create a mode switcher widget:

```dart
// lib/features/mode/widgets/mode_switcher.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sdui/providers/mode_provider.dart';

class ModeSwitcher extends ConsumerWidget {
  const ModeSwitcher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(currentModeProvider);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            label: 'Nutrition',
            icon: Icons.restaurant,
            isActive: currentMode == 'nutrition',
            onTap: () => ref.read(currentModeProvider.notifier).switchTo('nutrition'),
          ),
          _ModeButton(
            label: 'Beauty',
            icon: Icons.spa,
            isActive: currentMode == 'beauty',
            onTap: () => ref.read(currentModeProvider.notifier).switchTo('beauty'),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Option B: Use DynamicLayoutPage Directly

For a cleaner approach, replace your home page with:

```dart
// In your router or navigation
GoRoute(
  path: '/home',
  builder: (context, state) => DynamicLayoutPage(mode: 'nutrition'),
),
GoRoute(
  path: '/beauty',
  builder: (context, state) => DynamicLayoutPage(mode: 'beauty'),
),
```

## 🧪 Step 5: Test the Implementation

### Test Cache-First Loading:
```dart
// Run the app in airplane mode
// Should load bundled fallback layouts
```

### Test Mode Switching:
```dart
// Tap mode switcher
// Verify layout changes without navigation transition
// Check that scroll position is preserved per mode
```

### Test Remote Updates:
```dart
// Update layout in Supabase
// Pull to refresh in app
// Verify new layout renders
```

## 📊 Supported Component Types

### Common Components:
- `hero_banner` - Welcome banner with gradient
- `section_header` - Section titles with actions
- `quick_actions` - Horizontal action buttons

### Nutrition Components:
- `weight_tracker` - Weight progress card
- `calories_graph` - Daily calories visualization
- `meal_log` - Meal tracking interface
- `nutrition_summary` - Macro breakdown

### Beauty Components:
- `routine_grid` - Skincare/haircare routines
- `product_tracker` - Product inventory
- `skin_progress` - Skin condition timeline
- `hair_care_timeline` - Hair journey tracker
- `ingredient_checker` - Product ingredient analysis

### Cultural Components:
- `cultural_tip` - Traditional wellness tips
- `traditional_remedy` - Heritage remedies

## 🔐 Security Considerations

### Production Checklist:
- [ ] Implement JWT validation for layout fetching
- [ ] Sign layout JSON payloads with HMAC
- [ ] Validate JSON schema before rendering
- [ ] Rate limit layout fetch requests
- [ ] Encrypt sensitive user preferences in Hive
- [ ] Implement proper RLS policies in Supabase

## 📈 Performance Optimizations

1. **Prefetch Adjacent Modes**: Load beauty layout when user is on nutrition
2. **Image Caching**: Use `cached_network_image` for all remote images
3. **Background Parsing**: Use `compute()` for large JSON parsing
4. **Lazy Loading**: Only render visible components with `ListView.builder`

## 🐛 Troubleshooting

### Issue: Layout not loading
**Solution**: Check Supabase connection and RLS policies

### Issue: Cache not persisting
**Solution**: Ensure Hive initialization happens before any cache operations

### Issue: Mode switch causes rebuild
**Solution**: Use `IndexedStack` to preserve widget state across modes

### Issue: Unknown component type
**Solution**: Add component type to `WidgetFactory.buildComponent` switch statement

## 📝 Next Steps

1. ✅ Run `flutter pub get` locally
2. ✅ Execute Supabase SQL to create layouts table
3. ✅ Initialize Hive in main.dart
4. ✅ Add mode switcher to your UI
5. ✅ Test with sample layouts
6. ✅ Build beauty-specific widgets
7. ✅ Implement user culture preferences from profile
8. ✅ Add analytics tracking for layout performance

## 🎨 Customization Tips

### Add New Component Type:
1. Add case to `WidgetFactory.buildComponent`
2. Implement private builder method
3. Test with sample JSON config
4. Deploy layout to Supabase

### Customize Layout Schema:
```json
{
  "components": [
    {
      "type": "your_custom_component",
      "config": {
        "custom_property": "value"
      },
      "conditions": {
        "min_app_version": "1.0.0",
        "culture_tags": ["west_african"]
      }
    }
  ]
}
```

---

**Status**: ✅ Core SDUI infrastructure implemented
**Next**: Integrate with existing navigation and test mode switching
