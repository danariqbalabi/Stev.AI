export const MAX_IMAGE_BYTES = 8 * 1024 * 1024;
export const SUPPORTED_MIME_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
]);

export type RecognitionRequest = {
  imageBase64: string;
  mimeType: string;
  catalogIds: string[];
};

export type CatalogDrink = {
  id: string;
  name: string;
  brand: string | null;
  aliases: string[];
};

export type RecognitionCandidate = {
  id: string;
  confidence: number;
};

export class RequestValidationError extends Error {
  readonly status: number;
  readonly code: string;

  constructor(
    status: number,
    code: string,
    message: string,
  ) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

export function parseRecognitionRequest(value: unknown): RecognitionRequest {
  if (!isRecord(value)) {
    throw new RequestValidationError(
      400,
      "invalid_body",
      "Body harus berupa JSON object.",
    );
  }

  const imageBase64 = value.imageBase64;
  const mimeType = value.mimeType;
  const rawCatalogIds = value.catalogIds;
  if (typeof imageBase64 !== "string" || imageBase64.length === 0) {
    throw new RequestValidationError(
      400,
      "missing_image",
      "Foto belum dikirim.",
    );
  }
  if (typeof mimeType !== "string" || !SUPPORTED_MIME_TYPES.has(mimeType)) {
    throw new RequestValidationError(
      415,
      "unsupported_image",
      "Format foto harus JPEG, PNG, atau WebP.",
    );
  }
  if (!Array.isArray(rawCatalogIds)) {
    throw new RequestValidationError(
      400,
      "invalid_catalog",
      "Daftar katalog tidak valid.",
    );
  }

  const estimatedBytes = Math.floor((imageBase64.length * 3) / 4);
  if (estimatedBytes > MAX_IMAGE_BYTES) {
    throw new RequestValidationError(
      413,
      "image_too_large",
      "Ukuran foto maksimal 8 MB.",
    );
  }
  try {
    Uint8Array.from(atob(imageBase64), (character) => character.charCodeAt(0));
  } catch (_) {
    throw new RequestValidationError(
      400,
      "invalid_image",
      "Data foto bukan Base64 yang valid.",
    );
  }

  const catalogIds = [
    ...new Set(
      rawCatalogIds.filter(
        (id): id is string => typeof id === "string" && id.trim().length > 0,
      ).map((id) => id.trim()),
    ),
  ].slice(0, 500);
  if (catalogIds.length === 0) {
    throw new RequestValidationError(
      400,
      "empty_catalog",
      "Katalog minuman kosong.",
    );
  }

  return { imageBase64, mimeType, catalogIds };
}

export function mapCatalogRows(
  rows: unknown[],
  allowedIds: Set<string>,
): CatalogDrink[] {
  const drinks: CatalogDrink[] = [];
  for (const value of rows) {
    if (
      !isRecord(value) || typeof value.id !== "string" ||
      typeof value.name !== "string"
    ) {
      continue;
    }
    if (!allowedIds.has(value.id)) continue;

    const aliases = Array.isArray(value.drink_aliases)
      ? value.drink_aliases
        .filter(isRecord)
        .map((alias) => alias.alias)
        .filter((alias): alias is string => typeof alias === "string")
      : [];
    drinks.push({
      id: value.id,
      name: value.name,
      brand: typeof value.brand === "string" ? value.brand : null,
      aliases,
    });
  }
  return drinks;
}

export function buildGeminiRequest(
  request: RecognitionRequest,
  catalog: CatalogDrink[],
): Record<string, unknown> {
  const catalogText = catalog.map((drink) => {
    const brand = drink.brand ? `; brand=${drink.brand}` : "";
    const aliases = drink.aliases.length > 0
      ? `; alias=${drink.aliases.join(", ")}`
      : "";
    return `- id=${drink.id}; nama=${drink.name}${brand}${aliases}`;
  }).join("\n");

  return {
    systemInstruction: {
      parts: [{
        text:
          "Anda adalah pengenal minuman Indonesia. Pilih hanya ID yang tersedia dalam katalog. " +
          "Jangan menebak kandungan gula dan jangan membuat ID baru. Gunakan teks pada kemasan/menu, " +
          "logo, bentuk produk, dan konteks visual. Confidence harus 0 sampai 1.",
      }],
    },
    contents: [{
      role: "user",
      parts: [
        {
          text:
            "Identifikasi minuman pada foto. Kembalikan maksimal tiga kandidat paling mungkin " +
            `dari katalog berikut:\n${catalogText}`,
        },
        {
          inlineData: {
            mimeType: request.mimeType,
            data: request.imageBase64,
          },
        },
      ],
    }],
    generationConfig: {
      temperature: 0.1,
      responseMimeType: "application/json",
      responseJsonSchema: {
        type: "object",
        properties: {
          candidates: {
            type: "array",
            items: {
              type: "object",
              properties: {
                id: { type: "string" },
                confidence: { type: "number" },
              },
              required: ["id", "confidence"],
              additionalProperties: false,
            },
            maxItems: 3,
          },
        },
        required: ["candidates"],
        additionalProperties: false,
      },
    },
  };
}

export function extractGeminiOutputText(value: unknown): string | null {
  if (!isRecord(value)) return null;
  if (!Array.isArray(value.candidates)) return null;

  for (const candidate of value.candidates) {
    if (!isRecord(candidate) || !isRecord(candidate.content)) continue;
    const parts = candidate.content.parts;
    if (!Array.isArray(parts)) continue;
    for (const part of parts) {
      if (isRecord(part) && typeof part.text === "string") {
        return part.text;
      }
    }
  }
  return null;
}

export function sanitizeCandidates(
  outputText: string,
  allowedIds: Set<string>,
): RecognitionCandidate[] {
  const decoded: unknown = JSON.parse(outputText);
  if (!isRecord(decoded) || !Array.isArray(decoded.candidates)) return [];

  const seen = new Set<string>();
  const candidates: RecognitionCandidate[] = [];
  for (const value of decoded.candidates) {
    if (
      !isRecord(value) || typeof value.id !== "string" ||
      typeof value.confidence !== "number"
    ) {
      continue;
    }
    if (
      !allowedIds.has(value.id) || seen.has(value.id) ||
      !Number.isFinite(value.confidence)
    ) {
      continue;
    }
    seen.add(value.id);
    candidates.push({
      id: value.id,
      confidence: Math.max(0, Math.min(1, value.confidence)),
    });
  }
  return candidates.sort((a, b) => b.confidence - a.confidence).slice(0, 3);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
