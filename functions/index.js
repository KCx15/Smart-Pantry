const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

function normName(s) {
    return String(s || "").trim().toLowerCase().replace(/\s+/g, " ");
}

function fingerprintPantry(pantry) {
    // Choose what “same pantry” means:
    // - include quantity? yes (recommended)
    // - include expiry bucket? yes (expiringSoon vs not)
    const parts = pantry
        .map((p) => {
            const name = normName(p.name);
            const qty = Number(p.quantity || 0);
            const expSoon = Boolean(p.expiring_soon);
            return `${name}:${qty}:${expSoon ? "soon" : "later"}`;
        })
        .sort();
    const str = parts.join("|");
    return crypto.createHash("sha256").update(str).digest("hex");
}

exports.generateRecipes = onCall(
    { region: "europe-west1", secrets: [GEMINI_API_KEY] },
    async (request) => {
        const data = request.data || {};
        const pantryInput = Array.isArray(data.pantry) ? data.pantry : [];
        if (!pantryInput.length) throw new HttpsError("invalid-argument", "Pantry is empty.");

        const maxRecipes = Number(data.max_recipes || 5);
        const maxTime = Number(data.max_time_minutes || 30);
        const diet = String(data.diet || "any");
        const allergies = Array.isArray(data.allergies) ? data.allergies : [];

        // You already enrich pantry (days_left, expiring_soon). Keep your current logic.
        const pantry = pantryInput.map((p) => ({
            name: String(p.name || "").trim(),
            quantity: Number(p.quantity || 0),
            expiry_iso: p.expiry_iso ? String(p.expiry_iso) : null,
            days_left: p.days_left ?? null,
            expiring_soon: Boolean(p.expiring_soon),
        }));

        const fp = fingerprintPantry(pantry);
        const cacheRef = admin.firestore().collection("recipe_cache").doc(fp);

        // ✅ 1) Check cache
        const cachedSnap = await cacheRef.get();
        if (cachedSnap.exists) {
            const cached = cachedSnap.data();
            const expiresAt = cached?.expiresAt?.toDate?.();
            if (expiresAt && expiresAt > new Date()) {
                return { ...cached.response, cache: "HIT", fingerprint: fp };
            }
        }

        // ✅ 2) Miss -> call Gemini
        const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
        const model = genAI.getGenerativeModel({
            model: "gemini-2.5-flash",
            generationConfig: { responseMimeType: "application/json" },
        });

        const prompt = `
Return ONLY valid JSON.
Schema: { "recipes": [ ... ] }
Rules:
- Generate ${maxRecipes} recipes
- Max cook time ${maxTime} minutes
- Diet: ${diet}
- Allergies: ${JSON.stringify(allergies)}
- Prefer expiring_soon items first
Pantry:
${JSON.stringify(pantry, null, 2)}
`;

        try {
            const result = await model.generateContent(prompt);
            const text = result.response.text();
            const json = JSON.parse(text);

            const recipes = Array.isArray(json.recipes) ? json.recipes : [];
            recipes.sort((a, b) => Number(b.match_score || 0) - Number(a.match_score || 0));

            const response = { recipes };

            // ✅ 3) Save cache (24h)
            const now = admin.firestore.Timestamp.now();
            const expiresAt = admin.firestore.Timestamp.fromDate(
                new Date(Date.now() + 24 * 60 * 60 * 1000)
            );

            await cacheRef.set(
                {
                    fingerprint: fp,
                    createdAt: now,
                    expiresAt,
                    response,
                    model: "gemini-2.5-flash",
                    version: 1,
                },
                { merge: true }
            );

            return { ...response, cache: "MISS", fingerprint: fp };
        } catch (e) {
            throw new HttpsError("internal", e?.message || String(e));
        }
    }
);
