# Fan Mode Page — Redesign

**Date:** 2026-06-12  
**Author:** Curtis (Fondateur Akeli)  
**Status:** Approved — ready for implementation

---

## Context

The current `FanModePage` (`lib/features/fan_mode/fan_mode_page.dart`) treats fan mode as a simple donation toggle. It shows an explanation card (which omits the 90/10 commitment) and a list of creators. For an active fan, it shows only a banner saying "Mode Fan actif" with no actionable information.

Fan mode is a commitment mode with real constraints (90/10 rule, hard block at 9 external recipes/month). The page must reflect this for active fans, and help non-fans discover it through their own consumption data.

---

## Design

The page branches on `myFanSubscriptionProvider`:
- **No active/pending subscription** → View A (non-fan)
- **Active or pending subscription** → View B (fan)

Both views share the same route (`/fan-mode`) and `AppBar` ("Mode Fan").

---

## View A — Non-fan user

### Consumption ratio card

- Card label: "Vos recettes ce mois"
- Total meals badge: "🍽 N repas enregistrés"
- One row per creator consumed this month, sorted by count descending:
  - Creator avatar (initials + color) · creator name · horizontal bar · percentage label
  - Bar color matches creator color coding
- Empty state if no meals this month: "Aucune recette enregistrée ce mois"
- **Data source:** `meal_consumption` GROUP BY `creator_id` WHERE `user_id = me AND month_key = YYYY-MM` (current month)
- **New provider:** `creatorConsumptionProvider` → `AsyncValue<List<CreatorConsumption>>`

### Creator list

- Section title: "Créateurs à soutenir"
- Section subtitle: "Votre créateur dominant est mis en avant."
- Same `fanEligibleCreatorsProvider` as today (creators with ≥30 recipes)
- Creator card: avatar · name · specialties · recipe count · fan count · "Soutenir" button
- The creator with the highest consumption percentage gets a highlighted "Soutenir" button (pink/primary accent) to nudge the natural choice
- Tapping "Soutenir" triggers the existing `_activateFanMode()` confirmation dialog

---

## View B — Fan user

### Status banner

- Creator avatar initials + creator name + specialties
- Status chip:
  - Active: "❤️ Mode Fan actif" (pink)
  - Pending: "⏳ Actif le 1er du mois prochain" (amber)

### External recipe counter (active status only, hidden when pending)

- Card label: "Recettes externes ce mois"
- Large `X / 9` counter — color logic:
  - 0–4: green (`AkeliColors.success`)
  - 5–7: orange/amber
  - 8–9: red (`AkeliColors.error`)
- Progress bar with matching color
- Sublabel: "Limite : 9 par mois"
- **Data source:** `fan_external_recipe_counter` WHERE `user_id = me AND month_key = YYYY-MM` (current month)
- **New provider:** `fanExternalCounterProvider` → `AsyncValue<int>` (returns 0 if no row exists yet)

### Short explanation

- 3–4 lines of body text explaining: who you support, 1€/month guaranteed, 90/10 rule summary
- Not a collapsible — always visible, intentionally brief

### Leave button

- Full-width outlined red button: "Quitter le Mode Fan"
- Triggers the existing `_cancelFanMode()` confirmation dialog (no changes to dialog or cancel logic)

---

## New models

### `CreatorConsumption`

```dart
@immutable
class CreatorConsumption {
  final String creatorId;
  final String creatorName;
  final String? avatarUrl;
  final int count;      // total meals consumed this month from this creator
  final double pct;     // percentage of total meals (0.0–1.0)
}
```

---

## New providers

### `creatorConsumptionProvider`

- **Type:** `FutureProvider<List<CreatorConsumption>>`
- **Query strategy:** PostgREST does not support GROUP BY. Fetch all `meal_consumption` rows for `user_id = currentUserId AND month_key = currentMonthKey`, then aggregate client-side by `creator_id`. For typical usage (≤40 meals/month) this is acceptable.
- After aggregation, fetch creator names/avatars from `creator` table for the distinct `creator_id` set (second query, not a join).
- Returns empty list if no consumption this month
- Full logging (BEFORE/AFTER/ERROR, zero-row RLS detection)

### `fanExternalCounterProvider`

- **Type:** `FutureProvider<int>`
- **Query:** `fan_external_recipe_counter` WHERE `user_id = currentUserId AND month_key = currentMonthKey` — returns `external_recipe_count` or 0 if no row
- Only watched in View B (active fan)
- Full logging

---

## Files to create / modify

| File | Action |
|---|---|
| `lib/features/fan_mode/fan_mode_page.dart` | Rewrite — split into `_FanUserView` and `_NoFanUserView` |
| `lib/providers/fan_mode_provider.dart` | Add `creatorConsumptionProvider` and `fanExternalCounterProvider` |
| `lib/shared/models/creator.dart` | Add `CreatorConsumption` model |

No new routes, no schema changes, no edge function changes.

---

## Out of scope

- Creator profile page navigation from the fan page (V2)
- Creator's recent recipes shown on the fan page (V2)
- Rolling 30-day consumption view (current month only per spec)
- Any changes to `_activateFanMode()` or `_cancelFanMode()` dialog logic
