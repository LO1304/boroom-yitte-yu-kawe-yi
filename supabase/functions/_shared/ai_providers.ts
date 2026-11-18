// Provider-independent server-side AI gateway
// Default: Google Gemini, with pluggable OpenAI, Anthropic, and OpenAI-compatible adapters.
// All API keys stay strictly on the server (Deno.env) and are NEVER shipped to mobile clients.

export type AIProviderName = "gemini" | "openai" | "anthropic" | "custom";

export interface AIMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

export interface AICompletionRequest {
  provider?: AIProviderName;
  model?: string;
  systemPrompt: string;
  messages: AIMessage[];
  temperature?: number;
  maxOutputTokens?: number;
  expectJson?: boolean;
}

export interface AICompletionResult {
  provider: AIProviderName;
  model: string;
  text: string;
  promptTokens: number;
  completionTokens: number;
  estimatedCostUsd: number;
  latencyMs: number;
}

const MODEL_PRICING_PER_1M_TOKENS: Record<
  string,
  { input: number; output: number }
> = {
  "gemini-2.5-flash": { input: 0.15, output: 0.6 },
  "gemini-2.5-pro": { input: 1.25, output: 10.0 },
  "gpt-4o-mini": { input: 0.15, output: 0.6 },
  "gpt-4o": { input: 2.5, output: 10.0 },
  "claude-sonnet-4-20250514": { input: 3.0, output: 15.0 },
  "claude-haiku-3-5": { input: 0.8, output: 4.0 },
};

export function estimateCostUsd(
  model: string,
  promptTokens: number,
  completionTokens: number,
): number {
  const rate = MODEL_PRICING_PER_1M_TOKENS[model] ?? { input: 0.5, output: 1.5 };
  const cost =
    (promptTokens / 1_000_000) * rate.input +
    (completionTokens / 1_000_000) * rate.output;
  return Number(cost.toFixed(6));
}

export function getEnv(name: string, fallback = ""): string {
  const g = globalThis as unknown as {
    Deno?: { env: { get(key: string): string | undefined } };
    process?: { env: Record<string, string | undefined> };
  };
  if (g.Deno?.env) {
    return g.Deno.env.get(name) ?? fallback;
  }
  if (g.process?.env) {
    return g.process.env[name] ?? fallback;
  }
  return fallback;
}

export function resolveProviderAndModel(
  requestedProvider?: AIProviderName,
  requestedModel?: string,
): { provider: AIProviderName; model: string } {
  const defaultProvider =
    (getEnv("AI_DEFAULT_PROVIDER", "gemini") as AIProviderName) || "gemini";
  const provider = requestedProvider ?? defaultProvider;

  if (requestedModel && requestedModel.trim().length > 0) {
    return { provider, model: requestedModel.trim() };
  }

  switch (provider) {
    case "gemini":
      return {
        provider,
        model: getEnv("AI_DEFAULT_MODEL_GEMINI", "gemini-2.5-flash"),
      };
    case "openai":
      return {
        provider,
        model: getEnv("AI_DEFAULT_MODEL_OPENAI", "gpt-4o-mini"),
      };
    case "anthropic":
      return {
        provider,
        model: getEnv("AI_DEFAULT_MODEL_ANTHROPIC", "claude-sonnet-4-20250514"),
      };
    case "custom":
      return {
        provider,
        model: getEnv("AI_DEFAULT_MODEL_CUSTOM", "llama-3.1-70b-instruct"),
      };
  }
}

export async function callAIProvider(
  req: AICompletionRequest,
): Promise<AICompletionResult> {
  const started = Date.now();
  const { provider, model } = resolveProviderAndModel(req.provider, req.model);

  if (provider === "gemini") {
    const apiKey = getEnv("GEMINI_API_KEY");
    if (!apiKey) {
      throw new Error("MISSING_PROVIDER_KEY: GEMINI_API_KEY is not configured on the server.");
    }
    const endpoint =
      `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(apiKey)}`;

    const contents = req.messages
      .filter((m) => m.role !== "system")
      .map((m) => ({
        role: m.role === "assistant" ? "model" : "user",
        parts: [{ text: m.content }],
      }));

    const payload: Record<string, unknown> = {
      systemInstruction: { parts: [{ text: req.systemPrompt }] },
      contents,
      generationConfig: {
        temperature: req.temperature ?? 0.3,
        maxOutputTokens: req.maxOutputTokens ?? 2048,
        ...(req.expectJson ? { responseMimeType: "application/json" } : {}),
      },
    };

    const res = await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    if (!res.ok) {
      const errText = await res.text();
      throw new Error(`GEMINI_HTTP_${res.status}: ${errText}`);
    }
    const data = await res.json();
    const text =
      data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
    const promptTokens = Number(data?.usageMetadata?.promptTokenCount ?? 0);
    const completionTokens = Number(
      data?.usageMetadata?.candidatesTokenCount ?? 0,
    );

    return {
      provider,
      model,
      text,
      promptTokens,
      completionTokens,
      estimatedCostUsd: estimateCostUsd(model, promptTokens, completionTokens),
      latencyMs: Date.now() - started,
    };
  }

  if (provider === "openai" || provider === "custom") {
    const isCustom = provider === "custom";
    const apiKey = getEnv(isCustom ? "CUSTOM_LLM_API_KEY" : "OPENAI_API_KEY");
    const baseUrl = isCustom
      ? getEnv("CUSTOM_LLM_BASE_URL", "http://localhost:11434/v1")
      : "https://api.openai.com/v1";

    if (!isCustom && !apiKey) {
      throw new Error("MISSING_PROVIDER_KEY: OPENAI_API_KEY is not configured on the server.");
    }

    const res = await fetch(`${baseUrl.replace(/\/$/, "")}/chat/completions`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...(apiKey ? { Authorization: `Bearer ${apiKey}` } : {}),
      },
      body: JSON.stringify({
        model,
        temperature: req.temperature ?? 0.3,
        max_tokens: req.maxOutputTokens ?? 2048,
        ...(req.expectJson ? { response_format: { type: "json_object" } } : {}),
        messages: [
          { role: "system", content: req.systemPrompt },
          ...req.messages.filter((m) => m.role !== "system"),
        ],
      }),
    });

    if (!res.ok) {
      const errText = await res.text();
      throw new Error(`${provider.toUpperCase()}_HTTP_${res.status}: ${errText}`);
    }
    const data = await res.json();
    const text = data?.choices?.[0]?.message?.content ?? "";
    const promptTokens = Number(data?.usage?.prompt_tokens ?? 0);
    const completionTokens = Number(data?.usage?.completion_tokens ?? 0);

    return {
      provider,
      model,
      text,
      promptTokens,
      completionTokens,
      estimatedCostUsd: estimateCostUsd(model, promptTokens, completionTokens),
      latencyMs: Date.now() - started,
    };
  }

  // Anthropic Claude
  const apiKey = getEnv("ANTHROPIC_API_KEY");
  if (!apiKey) {
    throw new Error("MISSING_PROVIDER_KEY: ANTHROPIC_API_KEY is not configured on the server.");
  }

  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model,
      max_tokens: req.maxOutputTokens ?? 2048,
      temperature: req.temperature ?? 0.3,
      system: req.systemPrompt,
      messages: req.messages
        .filter((m) => m.role !== "system")
        .map((m) => ({
          role: m.role === "assistant" ? "assistant" : "user",
          content: m.content,
        })),
    }),
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`ANTHROPIC_HTTP_${res.status}: ${errText}`);
  }
  const data = await res.json();
  const text = data?.content?.[0]?.text ?? "";
  const promptTokens = Number(data?.usage?.input_tokens ?? 0);
  const completionTokens = Number(data?.usage?.output_tokens ?? 0);

  return {
    provider,
    model,
    text,
    promptTokens,
    completionTokens,
    estimatedCostUsd: estimateCostUsd(model, promptTokens, completionTokens),
    latencyMs: Date.now() - started,
  };
}

export function extractJsonObject<T>(rawText: string): T {
  const cleaned = rawText
    .trim()
    .replace(/^```(?:json)?\s*/i, "")
    .replace(/\s*```$/i, "")
    .trim();
  return JSON.parse(cleaned) as T;
}
