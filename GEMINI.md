# **AI Development Guidelines for Akeli Nutrition App**

These guidelines define the operational principles and capabilities of the AI agent interacting with the Akeli Nutrition App project. This project is a Flutter native application, migrating from a FlutterFlow legacy base, with a Supabase backend and Riverpod for state management.

## **1. Project Phase & Migration Workflow (CRITICAL)**

The project has transitioned out of the initial migration process and is now preparing for production release. **Phases do not overlap**.

* **Phase 1 (Pure UI):** Completed.
* **Phase 2 (Design System):** Completed.
* **Phase 3 (Backend Reconnection):** Completed.
* **Phase 4 (Live Testing & Debugging):** Completed.
* **Phase 5 (Deployment, External Testing & Marketing):** The current phase. Focus on preparing production release builds, deploying/publishing to stores (App Store, Google Play), managing external test tracks (TestFlight, Google Play Closed Beta), final production database checks, and preparing marketing assets.

### **The 8-Step Audit Workflow (Phase 1)**
For every UI page you migrate, you MUST follow this exact sequence:
1. Extract widget tree from FF source (`flutterflow_application/akeli/lib/`).
2. Document baseline design attributes.
3. Generate Stitch prompt from baseline.
4. Extract Stitch high-fidelity widget tree (`stitch/*/code.html`).
5. Delta analysis — Baseline vs. Stitch.
6. User approval of proposed changes.
7. Visual screenshot analysis (`stitch/*/screen.png`).
8. Flutter transcription into `lib/features/`.

## **2. State Management (Riverpod v2.5.1)**

The Akeli app exclusively uses Riverpod 2.5 with code generation.
* **No `provider` package.** Do not use `ChangeNotifier` or `ChangeNotifierProvider`.
* **Code Generation:** Use `@riverpod` annotations (e.g., `class MyNotifier extends _$MyNotifier`).
* **Generation Command:** After modifying any provider, you must run:
  `dart run build_runner build --delete-conflicting-outputs`
* **UI Consumers:** Use `ConsumerWidget` or `ConsumerStatefulWidget` and `ref.watch()`.

## **3. Backend & Data (Supabase)**

* **No Firebase.** All database, auth, and edge functions are handled by Supabase.
* **RPCs & Edge Functions:** Complex logic is handled by Postgres RPCs (`supabase.rpc()`) or Edge Functions (`supabase.functions.invoke()`).
* **Phase 4 Integration:** Live Supabase data is expected and used throughout the app. Do not implement mock data fallbacks unless strictly needed for isolated component testing.

## **4. Logging Policy (AkeliLogger)**

**CRITICAL: Standard `print()` or `debugPrint()` are forbidden.**

The app uses a centralized, structured logger in `lib/core/logger.dart`. You must use this logger for all debugging and information tracking.

**Usage:**
```dart
import '../../core/logger.dart';

// Create a logger instance in your class
final _logger = appLogger;
```

**Log Categories & Emojis:**
* `_logger.auth('...')`: 🔐 Authentication
* `_logger.db('...')`: 📡 Database query
* `_logger.rls('...')`: 🔍 RLS check
* `_logger.provider('...')`: 🔄 Provider lifecycle
* `_logger.edge('func-name', '...')`: ⚡ Edge function
* `_logger.userAction('...')`: 🎯 User action
* `_logger.performance('...', duration)`: ⏱️ Perf

Always use the correct extension method based on the context. Do not use generic `Logger().i()` logs when a categorized log exists.

## **5. Design & Theming**

* **Aesthetic:** "Digital Editorial" — tonal depth, glassmorphism, no dividers.
* **Theme:** Centralized in `lib/core/theme.dart`. Use `AkeliColors` for all color references. Do not hardcode HEX colors in widgets.
* **Typography:** Uses Google Fonts (Nunito and Plus Jakarta Sans). Referenced via `GoogleFonts` or `Theme.of(context).textTheme`.

## **6. Automated Error Detection & Remediation**

* **Post-Modification Checks:** After *every* code modification, monitor `flutter analyze` for compilation errors, Dart analysis warnings, and missing required arguments.
* **No Unused Code:** The standard is 0 warnings. Remove unused imports, unused variables, and dead code immediately. Apply `const` wherever possible to optimize performance.