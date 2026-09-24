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
  '',
  'Prefer common Indian dishes when they match. If the photo has no food,',
  'return an empty foods array.',
].join('\n');

const app = express();
app.use(cors());
app.use(express.json({ limit: '12mb' }));

app.get('/health', (_req, res) => {
  res.json({ ok: true, model: MODEL, keyConfigured: Boolean(API_KEY) });
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

  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`;
  const payload = {
    contents: [
      {
        parts: [
          { text: PROMPT },
          {
            inline_data: {
              mime_type:
                typeof mimeType === 'string' ? mimeType : 'image/jpeg',
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

  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 40000);
    let upstream;
    try {
      upstream = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': API_KEY,
        },
        body: JSON.stringify(payload),
        signal: controller.signal,
      });
    } finally {
      clearTimeout(timer);
    }

    if (!upstream.ok) {
      const detail = await upstream.text();
      console.error(`Gemini ${upstream.status}: ${detail}`);
      // Pull Google's own message out of the error body when present.
      let reason = detail.slice(0, 200);
      try {
        const message = JSON.parse(detail)?.error?.message;
        if (message) reason = message;
      } catch {
        // Not JSON; keep the truncated text.
      }
      const hint = upstream.status === 404
        ? ` The model "${MODEL}" may not exist for your key; set GEMINI_MODEL in backend/.env (e.g. gemini-3.6-flash or gemini-flash-latest).`
        : upstream.status === 429
        ? ' You may be out of free quota; try again later.'
        : '';
      return res
        .status(502)
        .json({ error: `Gemini ${upstream.status}: ${reason}.${hint}` });
    }

    const data = await upstream.json();
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) {
      return res
        .status(502)
        .json({ error: 'The AI service returned no result.' });
    }

    let parsed;
    try {
      parsed = JSON.parse(text);
    } catch {
      return res
        .status(502)
        .json({ error: 'The AI service returned malformed data.' });
    }

    const foods = Array.isArray(parsed.foods) ? parsed.foods : [];
    return res.json({ foods });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'The server had a problem.' });
  }
});

app.listen(PORT, () => {
  console.log(`Food Baba API on http://localhost:${PORT} (model ${MODEL})`);
  if (!API_KEY) console.warn('GEMINI_API_KEY is not set; /analyze will 503.');
});
