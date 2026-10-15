import assert from "node:assert/strict";
import test from "node:test";
import {
  buildNutritionRequest,
  parseLabelImage,
  parseNutritionOutput,
} from "./nutrition.ts";

const output = (overrides: Record<string, unknown> = {}) =>
  JSON.stringify({
    status: "readable",
    productName: "Teh uji",
    sugarValue: 9,
    sugarUnit: "g",
    basis: "per_serving",
    servingMl: 150,
    servingsPerPackage: 2,
    packageMl: 300,
    sugarText: "Gula total 9 g",
    basisText: "Takaran saji 150 ml; 2 sajian per kemasan",
    confidence: 0.95,
    ...overrides,
  });

test("validates photo bytes and MIME rather than trusting extension", () => {
  assert.equal(
    parseLabelImage({ imageBase64: "/9j/", mimeType: "image/jpeg" }).mimeType,
    "image/jpeg",
  );
  for (
    const raw of [null, {}, { imageBase64: "%%%", mimeType: "image/jpeg" }, {
      imageBase64: "AQID",
      mimeType: "image/jpeg",
    }, { imageBase64: "/9j/", mimeType: "image/png" }]
  ) {
    assert.throws(() => parseLabelImage(raw));
  }
});

test("asks for exact label evidence and nullable quantities without totals", () => {
  const payload = buildNutritionRequest({
    imageBase64: "/9j/",
    mimeType: "image/jpeg",
  });
  assert.equal(payload.generationConfig.responseMimeType, "application/json");
  assert.match(JSON.stringify(payload), /karbohidrat/);
  assert.match(JSON.stringify(payload), /null/);
  assert.doesNotMatch(
    JSON.stringify(payload.generationConfig.responseJsonSchema),
    /totalGrams/,
  );
});

test("preserves per-serving numbers; total is calculated outside the model", () => {
  const label = parseNutritionOutput(output());
  assert.equal(label.sugarGrams, 9);
  assert.equal(label.servingsPerPackage, 2);
  assert.equal(label.basis, "per_serving");
  assert.equal("totalGrams" in label, false);
});

test("zero is valid while missing sugar must not become zero", () => {
  assert.equal(
    parseNutritionOutput(output({ sugarValue: 0, sugarText: "Gula 0 g" }))
      .sugarGrams,
    0,
  );
  assert.throws(() => parseNutritionOutput(output({ sugarValue: null })));
});

test("normalizes mg deterministically and preserves unread quantities as null", () => {
  const label = parseNutritionOutput(
    output({
      sugarValue: 900,
      sugarUnit: "mg",
      servingsPerPackage: null,
      packageMl: null,
    }),
  );
  assert.equal(label.sugarGrams, 0.9);
  assert.equal(label.servingsPerPackage, null);
  assert.equal(label.packageMl, null);
});

test("rejects non-labels, carbs-only evidence, uncertain readings and invalid bases", () => {
  for (
    const override of [
      { status: "unreadable" },
      { sugarText: "Karbohidrat total 9 g" },
      { sugarText: "Gula <1 g" },
      { confidence: 0.74 },
      { confidence: 1.1 },
      { basis: "per_100g" },
      { basisText: "" },
      { sugarValue: -1 },
      { basis: "per_100ml", sugarValue: 101 },
      { servingsPerPackage: 0 },
      { packageMl: -1 },
      { sugarUnit: "%" },
    ]
  ) assert.throws(() => parseNutritionOutput(output(override)));
  assert.throws(() => parseNutritionOutput("not json"));
});
