import assert from "node:assert/strict";
import test from "node:test";

import {
  buildGeminiRequest,
  extractGeminiOutputText,
  mapCatalogRows,
  parseRecognitionRequest,
  RequestValidationError,
  sanitizeCandidates,
} from "./recognition.ts";

test("validates and normalizes a recognition request", () => {
  const request = parseRecognitionRequest({
    imageBase64: "AQID",
    mimeType: "image/jpeg",
    catalogIds: ["matcha", "matcha", "es-teh-manis"],
  });
  assert.deepEqual(request.catalogIds, ["matcha", "es-teh-manis"]);
});

test("rejects unsupported images", () => {
  assert.throws(
    () =>
      parseRecognitionRequest({
        imageBase64: "AQID",
        mimeType: "image/gif",
        catalogIds: ["matcha"],
      }),
    (error) => error instanceof RequestValidationError && error.status === 415,
  );
});

test("maps only requested catalog rows and aliases", () => {
  const drinks = mapCatalogRows([
    {
      id: "matcha",
      name: "Matcha",
      brand: null,
      drink_aliases: [{ alias: "green tea latte" }],
    },
    { id: "hidden", name: "Hidden", brand: null, drink_aliases: [] },
  ], new Set(["matcha"]));
  assert.deepEqual(drinks, [{
    id: "matcha",
    name: "Matcha",
    brand: null,
    aliases: ["green tea latte"],
  }]);
});

test("builds a vision request without asking AI for sugar values", () => {
  const payload = buildGeminiRequest(
    { imageBase64: "AQID", mimeType: "image/png", catalogIds: ["matcha"] },
    [{ id: "matcha", name: "Matcha", brand: null, aliases: [] }],
  );
  const encoded = JSON.stringify(payload);
  assert.match(
    encoded,
    /"inlineData":\{"mimeType":"image\/png","data":"AQID"\}/,
  );
  assert.match(encoded, /"responseFormat"/);
  assert.doesNotMatch(encoded, /sugar_grams/);
});

test("extracts output and keeps three valid unique candidates", () => {
  const output = extractGeminiOutputText({
    candidates: [{
      content: {
        parts: [{
          text: JSON.stringify({
            candidates: [
              { id: "matcha", confidence: 0.7 },
              { id: "unknown", confidence: 1 },
              { id: "matcha", confidence: 0.5 },
              { id: "tea", confidence: 0.9 },
              { id: "coffee", confidence: 0.8 },
              { id: "boba", confidence: 0.6 },
            ],
          }),
        }],
      },
    }],
  });
  assert.ok(output);
  assert.deepEqual(
    sanitizeCandidates(output, new Set(["matcha", "tea", "coffee", "boba"])),
    [
      { id: "tea", confidence: 0.9 },
      { id: "coffee", confidence: 0.8 },
      { id: "matcha", confidence: 0.7 },
    ],
  );
});
