// Minimal OpenRouter chat-completions client (https://openrouter.ai/docs).
// - Structured output via response_format json_schema (falls back to json_object, then plain text on 400).
// - Web search via the `web` plugin (plan route), citations read from message.annotations[].url_citation.
// - Optional streaming so the plan route can report live progress.

export interface ChatMsg { role: "system" | "user" | "assistant"; content: string }
export interface Citation { title: string; url: string }
export interface CompletionResult {
  text: string;
  citations: Citation[];
  model: string;
  tokensIn?: number;
  tokensOut?: number;
}

export interface CompletionOptions {
  model: string;
  messages: ChatMsg[];
  schema?: { name: string; schema: unknown; strict?: boolean };
  webSearch?: { maxResults?: number };
  temperature?: number;
  maxTokens?: number;
  reasoningEffort?: "low" | "medium" | "high";
  /** Receives the accumulated text as it streams in (enables streaming). */
  onDelta?: (accumulated: string) => void;
  timeoutMs?: number;
}

const ENDPOINT = "https://openrouter.ai/api/v1/chat/completions";

export class OpenRouterError extends Error {
  constructor(public status: number, message: string) { super(message); }
}

export async function complete(opts: CompletionOptions): Promise<CompletionResult> {
  // Try the richest format first, degrade on 400s (some providers don't support json_schema with plugins).
  const formats: Array<"schema" | "json" | "none"> = opts.schema ? ["schema", "json", "none"] : ["none"];
  let lastError: unknown;
  for (const format of formats) {
    try {
      return await request(opts, format);
    } catch (e) {
      lastError = e;
      if (!(e instanceof OpenRouterError) || e.status !== 400) throw e;
      console.warn(`[openrouter] ${opts.model} rejected format=${format}: ${e.message}`);
    }
  }
  throw lastError;
}

async function request(opts: CompletionOptions, format: "schema" | "json" | "none"): Promise<CompletionResult> {
  const key = Deno.env.get("OPENROUTER_API_KEY");
  if (!key) throw new OpenRouterError(500, "OPENROUTER_API_KEY is not set");

  const body: Record<string, unknown> = {
    model: opts.model,
    messages: opts.messages,
    temperature: opts.temperature ?? 0.7,
    max_tokens: opts.maxTokens ?? 8000,
    stream: !!opts.onDelta,
  };
  if (opts.reasoningEffort) body.reasoning = { effort: opts.reasoningEffort, exclude: true };
  if (format === "schema" && opts.schema) {
    body.response_format = {
      type: "json_schema",
      json_schema: { name: opts.schema.name, strict: opts.schema.strict ?? false, schema: opts.schema.schema },
    };
  } else if (format === "json") {
    body.response_format = { type: "json_object" };
  }
  if (opts.webSearch) body.plugins = [{ id: "web", max_results: opts.webSearch.maxResults ?? 5 }];

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), opts.timeoutMs ?? 150_000);
  let res: Response;
  try {
    res = await fetch(ENDPOINT, {
      method: "POST",
      signal: controller.signal,
      headers: {
        "Authorization": `Bearer ${key}`,
        "Content-Type": "application/json",
        "HTTP-Referer": Deno.env.get("OPENROUTER_REFERER") ?? "https://github.com/ilo-app/ilo",
        "X-Title": "ilo — learn anything",
      },
      body: JSON.stringify(body),
    });
  } catch (e) {
    clearTimeout(timer);
    throw new OpenRouterError(504, `OpenRouter unreachable: ${e instanceof Error ? e.message : e}`);
  }

  if (!res.ok) {
    clearTimeout(timer);
    const detail = await res.text().catch(() => "");
    throw new OpenRouterError(res.status, detail.slice(0, 500));
  }

  try {
    if (body.stream) return await readStream(res, opts);
    const json = await res.json();
    if (json.error) throw new OpenRouterError(502, JSON.stringify(json.error).slice(0, 500));
    const message = json.choices?.[0]?.message ?? {};
    return {
      text: typeof message.content === "string" ? message.content : "",
      citations: extractCitations(message.annotations),
      model: json.model ?? opts.model,
      tokensIn: json.usage?.prompt_tokens,
      tokensOut: json.usage?.completion_tokens,
    };
  } finally {
    clearTimeout(timer);
  }
}

async function readStream(res: Response, opts: CompletionOptions): Promise<CompletionResult> {
  const reader = res.body!.pipeThrough(new TextDecoderStream()).getReader();
  let buffer = "", text = "", model = opts.model;
  const annotations: unknown[] = [];
  let tokensIn: number | undefined, tokensOut: number | undefined;
  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    buffer += value;
    let nl: number;
    while ((nl = buffer.indexOf("\n")) >= 0) {
      const line = buffer.slice(0, nl).trim();
      buffer = buffer.slice(nl + 1);
      if (!line.startsWith("data:")) continue; // ": OPENROUTER PROCESSING" keep-alives etc.
      const data = line.slice(5).trim();
      if (data === "[DONE]") continue;
      try {
        const chunk = JSON.parse(data);
        if (chunk.error) throw new OpenRouterError(502, JSON.stringify(chunk.error).slice(0, 500));
        model = chunk.model ?? model;
        const delta = chunk.choices?.[0]?.delta ?? {};
        if (typeof delta.content === "string" && delta.content) {
          text += delta.content;
          opts.onDelta?.(text);
        }
        if (Array.isArray(delta.annotations)) annotations.push(...delta.annotations);
        const msgAnn = chunk.choices?.[0]?.message?.annotations;
        if (Array.isArray(msgAnn)) annotations.push(...msgAnn);
        if (chunk.usage) { tokensIn = chunk.usage.prompt_tokens; tokensOut = chunk.usage.completion_tokens; }
      } catch (e) {
        if (e instanceof OpenRouterError) throw e;
      }
    }
  }
  return { text, citations: extractCitations(annotations), model, tokensIn, tokensOut };
}

function extractCitations(annotations: unknown): Citation[] {
  if (!Array.isArray(annotations)) return [];
  const seen = new Set<string>();
  const out: Citation[] = [];
  for (const a of annotations as any[]) {
    const c = a?.url_citation ?? a;
    const url = typeof c?.url === "string" ? c.url : "";
    if (!/^https?:\/\//.test(url) || seen.has(url)) continue;
    seen.add(url);
    out.push({ title: typeof c.title === "string" && c.title ? c.title : new URL(url).hostname, url });
  }
  return out;
}
