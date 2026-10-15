import {
  extractGeminiOutputText,
  RequestValidationError,
} from "../recognize-drink/recognition.ts";
import {
  buildNutritionRequest,
  parseLabelImage,
  parseNutritionOutput,
} from "./nutrition.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "apikey, authorization, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }
  try {
    const key = request.headers.get("apikey");
    if (!key) return json({ error: "unauthorized" }, 401);
    if (Number(request.headers.get("content-length")) > 12 * 1024 * 1024) {
      return json({
        error: "image_too_large",
        message: "Ukuran foto maksimal 8 MB.",
      }, 413);
    }
    let raw: unknown;
    try {
      raw = await request.json();
    } catch {
      return json({ error: "invalid_json" }, 400);
    }
    const image = parseLabelImage(raw);
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const geminiKey = Deno.env.get("GEMINI_API_KEY");
    if (!supabaseUrl || !geminiKey) {
      return json({
        error: "ai_not_configured",
        message: "Layanan pembacaan label belum dikonfigurasi.",
      }, 503);
    }
    // Verify the project's public key before spending Gemini quota. No writes.
    const auth = await fetch(
      `${supabaseUrl}/rest/v1/drinks?select=id&limit=1`,
      {
        method: "HEAD",
        headers: { apikey: key },
        signal: AbortSignal.timeout(10000),
      },
    );
    if (auth.status === 401 || auth.status === 403) {
      return json({ error: "unauthorized" }, 401);
    }
    if (!auth.ok) return json({ error: "backend_unavailable" }, 503);
    const model = Deno.env.get("GEMINI_MODEL") || "gemini-3.5-flash-lite";
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${
        encodeURIComponent(model)
      }:generateContent`,
      {
        method: "POST",
        headers: {
          "x-goog-api-key": geminiKey,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(buildNutritionRequest(image)),
        signal: AbortSignal.timeout(25000),
      },
    );
    if (!response.ok) {
      console.error("Nutrition provider failed", response.status);
      return json({
        error: "provider_unavailable",
        message: "Pembaca label sedang sibuk. Coba lagi sebentar.",
      }, response.status === 429 ? 429 : 502);
    }
    const text = extractGeminiOutputText(await response.json());
    if (text === null) {
      return json({
        error: "label_unreadable",
        message: "Label belum terbaca. Foto ulang tabel gizi.",
      }, 422);
    }
    const label = parseNutritionOutput(text);
    return json({ label });
  } catch (error) {
    if (error instanceof RequestValidationError) {
      return json({ error: error.code, message: error.message }, error.status);
    }
    console.error(
      "Nutrition request failed",
      error instanceof Error ? error.name : "unknown",
    );
    return json({
      error: "request_failed",
      message: "Label belum dapat dibaca. Coba lagi atau isi manual.",
    }, 502);
  }
});

function json(value: unknown, status = 200) {
  return Response.json(value, {
    status,
    headers: { ...corsHeaders, "Cache-Control": "no-store" },
  });
}
