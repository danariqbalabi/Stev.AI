import {
  buildGeminiRequest,
  extractGeminiOutputText,
  mapCatalogRows,
  parseRecognitionRequest,
  RequestValidationError,
  sanitizeCandidates,
} from "./recognition.ts";

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

  const startedAt = Date.now();
  try {
    const apiKey = request.headers.get("apikey");
    if (!apiKey) return json({ error: "missing_api_key" }, 401);

    let rawBody: unknown;
    try {
      rawBody = await request.json();
    } catch (_) {
      throw new RequestValidationError(
        400,
        "invalid_json",
        "Body JSON tidak valid.",
      );
    }
    const recognitionRequest = parseRecognitionRequest(rawBody);

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    if (!supabaseUrl) throw new Error("SUPABASE_URL is not configured");
    const catalogUrl = new URL("/rest/v1/drinks", supabaseUrl);
    catalogUrl.searchParams.set(
      "select",
      "id,name,brand,drink_aliases(alias)",
    );
    catalogUrl.searchParams.set("verified", "eq.true");
    catalogUrl.searchParams.set(
      "id",
      `in.(${
        recognitionRequest.catalogIds.map(escapePostgrestValue).join(",")
      })`,
    );

    const catalogResponse = await fetch(catalogUrl, {
      headers: { apikey: apiKey },
    });
    if (!catalogResponse.ok) {
      return json(
        { error: "unauthorized_or_catalog_unavailable" },
        catalogResponse.status === 401 ? 401 : 502,
      );
    }
    const catalogRows: unknown = await catalogResponse.json();
    const allowedRequestIds = new Set(recognitionRequest.catalogIds);
    const catalog = Array.isArray(catalogRows)
      ? mapCatalogRows(catalogRows, allowedRequestIds)
      : [];
    if (catalog.length === 0) return json({ candidates: [] });

    const geminiKey = Deno.env.get("GEMINI_API_KEY");
    if (!geminiKey) return json({ error: "ai_not_configured" }, 503);
    const model = Deno.env.get("GEMINI_MODEL") || "gemini-3.5-flash-lite";
    const geminiUrl = new URL(
      `https://generativelanguage.googleapis.com/v1beta/models/${
        encodeURIComponent(model)
      }:generateContent`,
    );
    const aiResponse = await fetch(geminiUrl, {
      method: "POST",
      headers: {
        "x-goog-api-key": geminiKey,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(
        buildGeminiRequest(recognitionRequest, catalog),
      ),
    });
    if (!aiResponse.ok) {
      console.error(
        "Vision provider failed",
        aiResponse.status,
        aiResponse.headers.get("x-request-id") ??
          aiResponse.headers.get("x-guploader-uploadid"),
      );
      return json({ error: "vision_provider_failed" }, 502);
    }

    const aiBody: unknown = await aiResponse.json();
    const outputText = extractGeminiOutputText(aiBody);
    const allowedDatabaseIds = new Set(catalog.map((drink) => drink.id));
    const candidates = outputText === null
      ? []
      : sanitizeCandidates(outputText, allowedDatabaseIds);

    console.log(JSON.stringify({
      event: "drink_recognition",
      model,
      candidateCount: candidates.length,
      durationMs: Date.now() - startedAt,
    }));
    return json({ candidates });
  } catch (error) {
    if (error instanceof RequestValidationError) {
      return json({ error: error.code, message: error.message }, error.status);
    }
    console.error(
      "Recognition failed",
      error instanceof Error ? error.message : "unknown",
    );
    return json({ error: "internal_error" }, 500);
  }
});

function json(body: unknown, status = 200): Response {
  return Response.json(body, {
    status,
    headers: { ...corsHeaders, "Cache-Control": "no-store" },
  });
}

function escapePostgrestValue(value: string): string {
  return `"${value.replaceAll("\\", "\\\\").replaceAll('"', '\\"')}"`;
}
