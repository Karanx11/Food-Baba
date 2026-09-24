# Food Guruji backend

A tiny Express server with one job: take a food photo from the app, ask a
vision model what's on the plate, and return each food with an estimated
portion and nutrition. The AI key lives here, on the server, so it never
ships inside the mobile app.

## Run it

1. **Get a free API key** from Google AI Studio: https://aistudio.google.com/apikey
2. **Configure and start:**

   ```bash
   cd backend
   npm install
   cp .env.example .env          # then paste your key into .env
   npm start
   ```

   The server prints `Food Guruji API on http://localhost:8787`.

3. **Point the app at it.** Run the app with the backend URL:

   ```bash
   flutter run --dart-define=FOOD_BABA_API=http://localhost:8787
   ```

   On an Android emulator use `http://10.0.2.2:8787` instead of `localhost`.

Without `FOOD_BABA_API`, the app uses a built-in demo analyzer that returns
sample foods, so the Snap flow still works end to end for testing.

## Endpoints

| Method | Path       | Body                            | Returns |
|--------|------------|---------------------------------|---------|
| GET    | `/health`  | —                               | `{ ok, model, keyConfigured }` |
| POST   | `/analyze` | `{ imageBase64, mimeType }`     | `{ foods: [...] }` |

Each food: `name`, `servingLabel`, `gramsPerServing`, `servings`, and
per-serving `calories`, `proteinG`, `carbsG`, `fatG`, `sugarG`, `fiberG`,
`sodiumMg`, plus a `confidence` from 0 to 1.

## Configuration

| Variable                 | Default            | Purpose |
|--------------------------|--------------------|---------|
| `GEMINI_API_KEY`         | —                  | Required. Your Google AI Studio key. |
| `GEMINI_MODEL`           | `gemini-3.6-flash` | The primary vision model. |
| `GEMINI_FALLBACK_MODELS` | `gemini-flash-latest,gemini-3.1-flash-lite` | Comma-separated models tried when the primary is busy. |
| `PORT`                   | `8787`             | Port to listen on. |

The free tier throttles a single model with `503 high demand`. `/analyze`
handles this: it retries the primary once, then tries each fallback model
(they have separate capacity), all within one request, so a Snap usually
succeeds without the user retrying. If your key lacks a model, list ones it
has (see `GET /v1beta/models`).

## Deploying

Any Node host works (Render, Railway, Fly, a small VM). Set the environment
variables there, deploy this folder, and build the app with
`--dart-define=FOOD_BABA_API=https://your-deployed-url`.

## Swapping the model

The provider lives entirely in `server.js` (`/analyze`). To use a different
vision API, change the request there and keep the JSON reply shape the same;
the app needs no changes.
