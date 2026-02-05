const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { GoogleGenerativeAI } = require("@google/generative-ai");

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

function toMidnight(d) {
    return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

function daysUntil(iso) {
    if (!iso) return null;
    const dt = new Date(iso);
    if (Number.isNaN(dt.getTime())) return null;

    const today = toMidnight(new Date());
    const target = toMidnight(dt);
    const diffMs = target.getTime() - today.getTime();
    return Math.floor(diffMs / (1000 * 60 * 60 * 24));
}

exports.generateRecipes = onCall(
    { region: "europe-west1", secrets: [GEMINI_API_KEY] },
    async (request) => {
        const data = request.data || {};
        const pantryInput = Array.isArray(data.pantry) ? data.pantry : [];

        if (!pantryInput.length) {
            throw new HttpsError("invalid-argument", "Pantry is empty.");
        }

        const maxRecipes = Number(data.max_recipes || 5);
        const maxTime = Number(data.max_time_minutes || 30);
        const diet = String(data.diet || "any");
        const allergies = Array.isArray(data.allergies) ? data.allergies : [];

        // Enrich pantry with expiry metadata (used for scoring and prompt)
        const pantry = pantryInput.map((p) => {
            const name = String(p.name || "").trim();
            const quantity = Number(p.quantity || 0);
            const expiryIso = p.expiry_iso ? String(p.expiry_iso) : null;

            const d = expiryIso ? daysUntil(expiryIso) : null;
            const expiringSoon = d !== null ? d <= 3 : false;

            return {
                name,
                quantity,
                expiry_iso: expiryIso,
                days_left: d,
                expiring_soon: expiringSoon,
            };
        });

        // (Optional) You can pre-sort pantry so Gemini sees urgent items first
        pantry.sort((a, b) => {
            const da = a.days_left ?? 9999;
            const db = b.days_left ?? 9999;
            return da - db;
        });

        const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
        const model = genAI.getGenerativeModel({
            model: "gemini-2.5-flash",
            generationConfig: { responseMimeType: "application/json" },
        });

        const prompt = `
Return ONLY valid JSON.

Schema:
{
  "recipes": [
    {
      "title": string,
      "cook_time_minutes": number,
      "difficulty": "easy" | "medium" | "hard",
      "uses": string[],
      "missing": string[],
      "missing_count": number,
      "expiring_items_used": string[],
      "match_score": number, 
      "steps": string[]
    }
  ]
}

Rules:
- Generate ${maxRecipes} recipes
- Max cook time ${maxTime} minutes
- Diet: ${diet}
- Allergies: ${JSON.stringify(allergies)}
- Prefer using items marked expiring_soon=true first
- "uses" must ONLY include items that appear in Pantry names
- "expiring_items_used" must be a subset of "uses"
- match_score is 0..100 based on:
    + Uses more pantry items
    + Uses more expiring_soon items (big boost)
    - Fewer missing ingredients
    - Keeps time <= ${maxTime}
- Keep steps concise (max ~8 steps)
- Return sorted by match_score DESC

Pantry (most urgent first):
${JSON.stringify(pantry, null, 2)}
`;

        try {
            const result = await model.generateContent(prompt);
            const text = result.response.text();
            const json = JSON.parse(text);

            // Safety: ensure recipes is an array
            const recipes = Array.isArray(json.recipes) ? json.recipes : [];

            // Extra safety: server-side sort by match_score (in case model ignores)
            recipes.sort((a, b) => (Number(b.match_score || 0) - Number(a.match_score || 0)));

            return { recipes };
        } catch (e) {
            const details = {
                name: e?.name,
                message: e?.message,
                status: e?.status,
                raw: String(e),
            };
            throw new HttpsError("internal", details.message || details.raw || "Gemini request failed");
        }
    }
);
