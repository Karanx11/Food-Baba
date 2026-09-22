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

Next up: home dashboard, capture flow, analytics.

## Project layout

```
lib/
  main.dart                 entry point
  app/                      FoodBabaApp + theme
  core/                     dates, number formatting, local DB wiring (sembast)
  core/widgets/             shared widgets (placeholder page, loaders, number field)
  features/
    splash/                 launch screen
    shell/                  bottom navigation + Snap action
    profile/                domain (profile, targets calculator), data (repository),
                            application (Riverpod providers), presentation (pages)
    log/                    domain (nutrition, food entry, daily log), data (sembast
                            repository), application (providers), presentation (log page, form)
    home/ analyze/          placeholders for now
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
