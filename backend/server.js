// Food Baba API.
//
// One endpoint, POST /analyze, takes a food photo and returns the foods in
// it with estimated portions and nutrition. It calls Google's Gemini vision
// model, keeping the API key on the server so it never ships in the app.
//
// The model name and key come from the environment; see .env.example.

import 'dotenv/config';
import express from 'express';
import cors from 'cors';

const PORT = process.env.PORT || 8787;
const API_KEY = process.env.GEMINI_API_KEY;
// Override if your key has access to a different model.
const MODEL = process.env.GEMINI_MODEL || 'gemini-3.6-flash';
// Gemini's free tier throttles a single model ("high demand"). When the
// primary is busy we retry, then fall back to these, which have separate
// capacity. Configurable via GEMINI_FALLBACK_MODELS (comma-separated).
const FALLBACK_MODELS = (
  process.env.GEMINI_FALLBACK_MODELS ||
  'gemini-flash-latest,gemini-3.1-flash-lite'
)
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);

// The models to try in order, primary first, duplicates removed.
const MODELS = [MODEL, ...FALLBACK_MODELS].filter(
  (m, i, all) => all.indexOf(m) === i,
);

// Give up after this long overall so the client's own timeout never fires
// first, and cap each single call so one slow model can't eat the budget.
const OVERALL_BUDGET_MS = 38000;
const PER_CALL_TIMEOUT_MS = 18000;
const RETRY_BACKOFF_MS = 800;

// What each food in the reply looks like. responseSchema makes Gemini return
// exactly this shape, so no brittle text parsing is needed.
const FOOD_SCHEMA = {
  type: 'object',
  properties: {
    foods: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          name: { type: 'string' },
          servingLabel: { type: 'string' },
          gramsPerServing: { type: 'number' },
          servings: { type: 'number' },
          calories: { type: 'number' },
          proteinG: { type: 'number' },
          carbsG: { type: 'number' },
          fatG: { type: 'number' },
          sugarG: { type: 'number' },
          fiberG: { type: 'number' },
          sodiumMg: { type: 'number' },
          confidence: { type: 'number' },
          notes: { type: 'string' },
        },
        required: [
          'name',
          'servingLabel',
          'gramsPerServing',
          'servings',
          'calories',
          'proteinG',
          'carbsG',
          'fatG',
        ],
      },
    },
  },
  required: ['foods'],
};

const PROMPT = [
  'You are a nutrition assistant. Identify every distinct food and drink in',
  'this photo. For each one estimate the portion actually shown and its',
  'nutrition for a single serving.',
  '',
  '- servingLabel: a natural household unit, e.g. "1 katori", "2 rotis",',
  '  "1 glass", "1 bowl".',
  '- gramsPerServing: the weight of ONE such serving in grams.',
  '- servings: how many of that serving are on the plate (may be fractional).',
  '- calories, proteinG, carbsG, fatG, sugarG, fiberG are PER ONE serving;',
  '  sodiumMg is per serving in milligrams.',
  '- confidence: 0..1, how sure you are of the item.',
  '- notes: a short phrase naming notable micronutrients or health facts,',
  '  e.g. "High in calcium and vitamin B12" or "Rich in fibre and iron".',
  '  Keep it under 12 words. Use an empty string if nothing stands out.',
  '',
  'Prefer common Indian dishes when they match. If the photo has no food,',
  'return an empty foods array.',
].join('\n');

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Calls one model once. Returns { ok:true, foods } on success, else
// { ok:false, status, reason }. status 0 means the call never completed.
async function callGemini(model, payload) {
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), PER_CALL_TIMEOUT_MS);
  try {
    const r = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': API_KEY,
      },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });
    if (!r.ok) {
      const detail = await r.text();
      console.error(`Gemini ${model} ${r.status}: ${detail.slice(0, 300)}`);
      let reason = detail.slice(0, 200);
      try {
        const message = JSON.parse(detail)?.error?.message;
        if (message) reason = message;
      } catch {
        // Not JSON; keep the truncated text.
      }
      return { ok: false, status: r.status, reason };
    }
    const data = await r.json();
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) {
      return { ok: false, status: 502, reason: 'the model returned no result' };
    }
    try {
      const parsed = JSON.parse(text);
      return {
        ok: true,
        foods: Array.isArray(parsed.foods) ? parsed.foods : [],
      };
    } catch {
      return {
        ok: false,
        status: 502,
        reason: 'the model returned malformed data',
      };
    }
  } catch (e) {
    return {
      ok: false,
      status: 0,
      reason:
        e.name === 'AbortError'
          ? 'the model timed out'
          : 'could not reach the model',
    };
  } finally {
    clearTimeout(timer);
  }
}

const app = express();
app.use(cors());
app.use(express.json({ limit: '12mb' }));

app.get('/health', (_req, res) => {
  res.json({ ok: true, models: MODELS, keyConfigured: Boolean(API_KEY) });
});

app.post('/analyze', async (req, res) => {
  if (!API_KEY) {
    return res.status(503).json({
      error: 'The server has no API key set. See backend/README.md.',
    });
  }
  const { imageBase64, mimeType } = req.body || {};
  if (typeof imageBase64 !== 'string' || imageBase64.length < 100) {
    return res.status(400).json({ error: 'No image was received.' });
  }

  const payload = {
    contents: [
      {
        parts: [
          { text: PROMPT },
          {
            inline_data: {
              mime_type: typeof mimeType === 'string' ? mimeType : 'image/jpeg',
              data: imageBase64,
            },
          },
        ],
      },
    ],
    generationConfig: {
      responseMimeType: 'application/json',
      responseSchema: FOOD_SCHEMA,
      temperature: 0.2,
    },
  };

  const deadline = Date.now() + OVERALL_BUDGET_MS;
  let lastStatus = 0;
  let lastReason = 'the AI service did not respond';

  for (const model of MODELS) {
    // Retry a busy model once before moving on; a 404/400 is permanent, so
    // skip straight to the next model.
    for (let attempt = 0; attempt < 2; attempt++) {
      if (Date.now() > deadline) break;
      const result = await callGemini(model, payload);
      if (result.ok) return res.json({ foods: result.foods });
      lastStatus = result.status;
      lastReason = result.reason;
      const transient =
        result.status === 503 || result.status === 429 || result.status === 0;
      if (!transient) break;
      if (attempt === 0 && Date.now() + RETRY_BACKOFF_MS < deadline) {
        await sleep(RETRY_BACKOFF_MS);
      }
    }
  }

  const hint =
    lastStatus === 503
      ? ' The models are busy right now. Please try again in a moment.'
      : lastStatus === 429
      ? ' You may be out of free quota; try again later.'
      : lastStatus === 404
      ? ' Set a model your key supports in backend/.env (GEMINI_MODEL).'
      : '';
  return res
    .status(502)
    .json({ error: `Gemini ${lastStatus}: ${lastReason}.${hint}` });
});

app.listen(PORT, () => {
  console.log(
    `Food Baba API on http://localhost:${PORT} (models: ${MODELS.join(', ')})`,
  );
  if (!API_KEY) console.warn('GEMINI_API_KEY is not set; /analyze will 503.');
});
