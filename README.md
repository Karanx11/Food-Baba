# Food Baba

Snap a photo of any food and get its nutrition breakdown, then track and analyze your eating over time.

Flutter app (Android, iOS, web) with a Node/Express backend planned for AI vision and nutrition lookups.

## Status

| Step | What | Verified |
|------|------|----------|
| 1 | Flutter scaffold (`food_baba`, Android + iOS + web) | analyze, web build, renders in browser |
| 2 | Brand theme (mint / charcoal / off-white), 4-tab shell, placeholder pages | analyze, widget tests, light + dark screenshots |
| 3 | Loading animations: single-stroke burger loader (splash) and hopping-pan loader (Snap preview sheet) | analyze, widget tests, screenshots |
| 4 | Profile (sex, age, height, weight, activity, goal) with Mifflin-St Jeor calorie and macro targets, saved locally via shared_preferences, state via Riverpod | analyze, 23 unit + widget tests, screenshots incl. reload persistence |
| 5 | Food log: day picker, calories/macros vs targets, Breakfast/Lunch/Dinner/Snacks with add, edit, swipe-to-delete + undo, recent foods to re-log, water tracking. Local document DB (sembast: files on mobile, IndexedDB on web) | analyze, 46 tests, browser walkthrough |
| 6 | Home dashboard: greeting, calorie ring (left/over), macro bars vs targets, today's meals with quick add, water shortcut, profile set-up prompt | analyze, 5 widget tests, browser light + dark |
| 7 | Food search: bundled database of 75 common foods (Indian staples first) with Hindi aliases, ranked search, portion screen with serving sizes and a quantity slider, recent foods, custom-food fallback | analyze, 70 tests incl. a data plausibility check, browser walkthrough |
| 8 | Glassmorphic UI (frosted cards, floating glass nav). Replaced by step 9 at the user's request | analyze, tests, browser light + dark |
| 9 | Lavender redesign from the user's reference: soft grey page with a lavender glow, white rounded cards, violet accent, black pill buttons, round floating nav with Snap in the middle. Home (week strip, Today's Goal gauge with macros left, meal cards with thumbnails), Daily Breakdown (270° calorie gauge, macro pills, water, health score), Goal Progress (goal and current weight, weight trend chart, BMI bar). Adds weight history and goal weight | analyze, 108 tests, browser light + dark |
| 10 | Light/dark mode button in the Home header (moon / sun). Follows the device until tapped; the choice is saved and loaded before the first frame | analyze, 114 tests, browser incl. reload |
| 11 | Camera capture: Snap opens Camera or Gallery, a food photo is analyzed, and detected foods appear on a review screen where portions are adjusted, items removed, and the rest logged. Node backend (backend/) calls Gemini with the key server-side; a built-in demo analyzer runs when no backend is set | analyze, 120 tests (6 capture-flow), backend syntax check |

Next up: barcode scan (Open Food Facts), then streaks and analytics.

## Project layout

```
lib/
  main.dart                 entry point
  app/                      FoodBabaApp + theme
  core/                     dates, number formatting, local DB wiring (sembast)
  core/widgets/             shared widgets (palette, background, cards, round buttons, top bar,
                            gauges, water fill, loaders, number field)
  features/
    splash/                 launch screen
    shell/                  bottom navigation + Snap action
    profile/                domain (profile, targets calculator), data (repository),
                            application (Riverpod providers), presentation (pages)
    log/                    domain (nutrition, food entry, daily log), data (sembast
                            repository), application (providers), presentation (log page, form)
    food_search/            domain (food item, ranked search), data (bundled catalog),
                            presentation (search page, portion page, portion selector)
    home/                   week strip, Today's Goal card, meal cards
    insights/               health score and the Daily Breakdown page
    progress/               weight history, BMI and goal progress, Goal Progress page
    capture/                photo source, AI analyzer (backend + demo), review screen
backend/                    Node/Express API that calls Gemini vision (see backend/README.md)
assets/foods/               bundled food database (approximate values per 100 g)
test/                       unit + widget tests (helpers/test_app.dart wires an in-memory store)
.claude/                    dev tooling (web preview server + launch config)
```

## Develop

Flutter lives at `C:\Users\Karan\flutter`. If `flutter` is not found, fix the PATH entry
(it currently points at `C:\Users\flutter\bin`) or call it by full path.

```bash
flutter pub get
flutter analyze
flutter test
```

Run on a device or the Chrome debugger:

```bash
flutter run -d chrome
```

Preview the release web build with the zero-dependency static server (port 8080):

```bash
flutter build web
node .claude/serve_web.js
```

## Android setup (one-time)

- Install `cmdline-tools` from Android Studio's SDK Manager.
- Accept licences: `flutter doctor --android-licenses`.
- An AVD named `Pixel_10_Pro` already exists.
