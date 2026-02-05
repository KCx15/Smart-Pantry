const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { GoogleGenerativeAI } = require("@google/generative-ai");

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

exports.generateRecipes = onCall(
    { region: "europe-west1", secrets: [GEMINI_API_KEY] },
    async (request) => {
        const data = request.data || {};
        const pantry = Array.isArray(data.pantry) ? data.pantry : [];

        if (!pantry.length) {
            throw new HttpsError("invalid-argument", "Pantry is empty.");
        }

        const maxRecipes = Number(data.max_recipes || 5);
        const maxTime = Number(data.max_time_minutes || 30);
        const diet = String(data.diet || "any");
        const allergies = Array.isArray(data.allergies) ? data.allergies : [];

        const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
        const model = genAI.getGenerativeModel({
            model: "gemini-1.5-flash",
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
      "steps": string[]
    }
  ]
}

Rules:
- Generate ${maxRecipes} recipes
- Max cook time ${maxTime} minutes
- Diet: ${diet}
- Allergies: ${JSON.stringify(allergies)}
- Prefer ingredients expiring soon
- Keep steps concise

Pantry:
${JSON.stringify(pantry, null, 2)}
`;

        try {
            const result = await model.generateContent(prompt);
            const text = result.response.text();
            const json = JSON.parse(text);
            return json;
        } catch (e) {
            throw new HttpsError("internal", String(e));
        }
    }
);
