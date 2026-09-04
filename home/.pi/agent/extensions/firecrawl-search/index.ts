import { readFileSync } from "node:fs"
import { mkdtemp, writeFile } from "node:fs/promises"
import { homedir, tmpdir } from "node:os"
import { join } from "node:path"
import {
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
  formatSize,
  truncateHead,
  type AgentToolResult,
  type AgentToolUpdateCallback,
  type ExtensionAPI,
} from "@earendil-works/pi-coding-agent"
import { Firecrawl, type CrawlJob, type CrawlOptions } from "firecrawl"
import * as v from "valibot"
import { toolSchema } from "../shared/schema.ts"
import {
  CRAWL_PARAMETER_DESCRIPTIONS,
  CRAWL_PROMPT_GUIDELINES,
  CRAWL_PROMPT_SNIPPET,
  CRAWL_TOOL_DESCRIPTION,
  SCRAPE_PARAMETER_DESCRIPTIONS,
  SCRAPE_PROMPT_GUIDELINES,
  SCRAPE_PROMPT_SNIPPET,
  SCRAPE_TOOL_DESCRIPTION,
  SEARCH_PARAMETER_DESCRIPTIONS,
  SEARCH_PROMPT_GUIDELINES,
  SEARCH_PROMPT_SNIPPET,
  SEARCH_TOOL_DESCRIPTION,
} from "./prompt.ts"

function readEnvValue(name: string) {
  if (process.env[name]) return process.env[name]

  const envPath = join(homedir(), ".env")
  let envText = ""

  try {
    envText = readFileSync(envPath, "utf8")
  } catch {
    return undefined
  }

  for (const line of envText.split(/\r?\n/)) {
    const trimmed = line.trim()
    if (!trimmed || trimmed.startsWith("#")) continue

    const match = trimmed.match(
      /^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/,
    )
    if (!match || match[1] !== name) continue

    const value = match[2].trim()
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      return value.slice(1, -1)
    }

    return value.replace(/\s+#.*$/, "")
  }

  return undefined
}

class MissingApiKeyError extends Error {
  constructor() {
    super("Missing FIRECRAWL_API_KEY in the environment or ~/.env")
    this.name = "MissingApiKeyError"
  }
}

function createClient() {
  const apiKey = readEnvValue("FIRECRAWL_API_KEY")
  if (!apiKey) throw new MissingApiKeyError()
  try {
    return new Firecrawl({ apiKey })
  } catch (cause) {
    throw new FirecrawlError(errorMessage(cause), { cause })
  }
}

function stringify(value: unknown) {
  return JSON.stringify(value, null, 2)
}

function errorMessage(error: unknown) {
  return error instanceof Error ? error.message : String(error)
}

class FirecrawlError extends Error {
  constructor(message: string, options?: ErrorOptions) {
    super(message, options)
    this.name = "FirecrawlError"
  }
}

async function firecrawlRequest<T>(request: () => Promise<T>): Promise<T> {
  try {
    return await request()
  } catch (cause) {
    throw new FirecrawlError(errorMessage(cause), { cause })
  }
}

class OutputError extends Error {
  constructor(message: string, options?: ErrorOptions) {
    super(message, options)
    this.name = "OutputError"
  }
}

async function formatOutput(value: unknown, operation: string) {
  try {
    const output = typeof value === "string" ? value : stringify(value)
    const truncation = truncateHead(output, {
      maxBytes: DEFAULT_MAX_BYTES,
      maxLines: DEFAULT_MAX_LINES,
    })
    if (!truncation.truncated) return output

    const outputDirectory = await mkdtemp(join(tmpdir(), "pi-firecrawl-"))
    const outputPath = join(outputDirectory, `${operation}.json`)
    await writeFile(outputPath, output, "utf8")

    return `${truncation.content}\n\n[Output truncated: ${truncation.outputLines} of ${truncation.totalLines} lines (${formatSize(truncation.outputBytes)} of ${formatSize(truncation.totalBytes)}). Full output saved to: ${outputPath}]`
  } catch (cause) {
    throw new OutputError(errorMessage(cause), { cause })
  }
}

export type CrawlClient = Pick<
  Firecrawl,
  "startCrawl" | "getCrawlStatus" | "cancelCrawl"
>

function throwIfAborted(signal: AbortSignal | undefined): void {
  if (signal?.aborted) throw signal.reason
}

function withAbort<T>(promise: Promise<T>, signal: AbortSignal | undefined) {
  if (!signal) return promise
  if (signal.aborted) return Promise.reject(signal.reason)

  return new Promise<T>((resolve, reject) => {
    const abort = () => reject(signal.reason)
    signal.addEventListener("abort", abort, { once: true })
    void promise.then(resolve, reject).finally(() => {
      signal.removeEventListener("abort", abort)
    })
  })
}

function wait(ms: number, signal: AbortSignal | undefined): Promise<void> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(resolve, ms)
    signal?.addEventListener(
      "abort",
      () => {
        clearTimeout(timer)
        reject(signal.reason)
      },
      { once: true },
    )
  })
}

async function pollCrawl(
  client: CrawlClient,
  jobId: string,
  signal: AbortSignal | undefined,
): Promise<CrawlJob> {
  throwIfAborted(signal)
  const job = await withAbort(
    firecrawlRequest(() => client.getCrawlStatus(jobId)),
    signal,
  )
  if (job.status !== "scraping") return job
  await wait(2_000, signal)
  return pollCrawl(client, jobId, signal)
}

/** Cancels remote job when polling fails or caller aborts. */
export async function crawlEffect(
  client: CrawlClient,
  url: string,
  options: CrawlOptions,
  signal?: AbortSignal,
): Promise<CrawlJob> {
  const job = await firecrawlRequest(() => client.startCrawl(url, options))
  try {
    return await pollCrawl(client, job.id, signal)
  } catch (error) {
    await Promise.race([
      firecrawlRequest(() => client.cancelCrawl(job.id)).catch(() => undefined),
      wait(10_000, undefined),
    ])
    throw error
  }
}

function operationError(operation: string, error: unknown) {
  if (error instanceof MissingApiKeyError) return new Error(error.message)

  const cause =
    error instanceof FirecrawlError || error instanceof OutputError
      ? error.cause
      : error
  return new Error(`Firecrawl ${operation} failed: ${errorMessage(error)}`, {
    cause,
  })
}

async function runFirecrawl<T>(
  operation: string,
  status: string,
  timeout: number,
  signal: AbortSignal | undefined,
  onUpdate: AgentToolUpdateCallback<T | undefined> | undefined,
  request: (
    client: Firecrawl,
    signal: AbortSignal,
  ) => Promise<{ details: T; output: unknown }>,
) {
  const requestSignal = signal
    ? AbortSignal.any([signal, AbortSignal.timeout(timeout)])
    : AbortSignal.timeout(timeout)

  try {
    const client = createClient()
    onUpdate?.({
      content: [{ type: "text", text: status }],
      details: undefined,
    })
    const { details, output } = await request(client, requestSignal)
    const formatted = await formatOutput(output, operation)
    return {
      content: [{ type: "text" as const, text: formatted }],
      details,
    } satisfies AgentToolResult<T | undefined>
  } catch (error) {
    if (requestSignal.aborted) throw new Error("Firecrawl request cancelled")
    throw operationError(operation, error)
  }
}

export default function firecrawlTools(pi: ExtensionAPI) {
  pi.registerTool({
    name: "search",
    label: "Search Web",
    description: SEARCH_TOOL_DESCRIPTION,
    promptSnippet: SEARCH_PROMPT_SNIPPET,
    promptGuidelines: SEARCH_PROMPT_GUIDELINES,
    parameters: toolSchema(
      v.object({
        query: v.pipe(
          v.string(),
          v.description(SEARCH_PARAMETER_DESCRIPTIONS.query),
        ),
        limit: v.optional(
          v.pipe(
            v.number(),
            v.minValue(1),
            v.maxValue(20),
            v.description(SEARCH_PARAMETER_DESCRIPTIONS.limit),
          ),
        ),
        source: v.optional(v.picklist(["web", "news", "images"])),
        scrapeResults: v.optional(
          v.pipe(
            v.boolean(),
            v.description(SEARCH_PARAMETER_DESCRIPTIONS.scrapeResults),
          ),
        ),
      }),
    ),
    execute: (_toolCallId, params, signal, onUpdate) =>
      runFirecrawl(
        "search",
        `Searching Firecrawl for: ${params.query}`,
        35_000,
        signal,
        onUpdate,
        async (client) => {
          const result = await firecrawlRequest(() =>
            client.search(params.query, {
              limit: params.limit ?? 5,
              sources: [params.source ?? "web"],
              scrapeOptions: params.scrapeResults
                ? { formats: ["markdown"], timeout: 30_000 }
                : undefined,
              timeout: 30_000,
            }),
          )
          return { details: result, output: result }
        },
      ),
  })

  pi.registerTool({
    name: "crawl",
    label: "Crawl Website",
    description: CRAWL_TOOL_DESCRIPTION,
    promptSnippet: CRAWL_PROMPT_SNIPPET,
    promptGuidelines: CRAWL_PROMPT_GUIDELINES,
    parameters: toolSchema(
      v.object({
        url: v.pipe(
          v.string(),
          v.description(CRAWL_PARAMETER_DESCRIPTIONS.url),
        ),
        limit: v.optional(
          v.pipe(
            v.number(),
            v.minValue(1),
            v.maxValue(100),
            v.description(CRAWL_PARAMETER_DESCRIPTIONS.limit),
          ),
        ),
        maxDiscoveryDepth: v.optional(
          v.pipe(
            v.number(),
            v.minValue(0),
            v.description(CRAWL_PARAMETER_DESCRIPTIONS.maxDiscoveryDepth),
          ),
        ),
        includePaths: v.optional(
          v.pipe(
            v.array(v.string()),
            v.description(CRAWL_PARAMETER_DESCRIPTIONS.includePaths),
          ),
        ),
        excludePaths: v.optional(
          v.pipe(
            v.array(v.string()),
            v.description(CRAWL_PARAMETER_DESCRIPTIONS.excludePaths),
          ),
        ),
        crawlEntireDomain: v.optional(
          v.pipe(
            v.boolean(),
            v.description(CRAWL_PARAMETER_DESCRIPTIONS.crawlEntireDomain),
          ),
        ),
        allowSubdomains: v.optional(
          v.pipe(
            v.boolean(),
            v.description(CRAWL_PARAMETER_DESCRIPTIONS.allowSubdomains),
          ),
        ),
        sitemap: v.optional(v.picklist(["include", "skip", "only"])),
        onlyMainContent: v.optional(
          v.pipe(
            v.boolean(),
            v.description(CRAWL_PARAMETER_DESCRIPTIONS.onlyMainContent),
          ),
        ),
        timeout: v.optional(
          v.pipe(
            v.number(),
            v.minValue(1),
            v.maxValue(600),
            v.description(CRAWL_PARAMETER_DESCRIPTIONS.timeout),
          ),
        ),
      }),
    ),
    execute: (_toolCallId, params, signal, onUpdate) =>
      runFirecrawl(
        "crawl",
        `Crawling up to ${params.limit ?? 20} pages from: ${params.url}`,
        ((params.timeout ?? 120) + 5) * 1_000,
        signal,
        onUpdate,
        async (client, requestSignal) => {
          const result = await crawlEffect(
            client,
            params.url,
            {
              limit: params.limit ?? 20,
              maxDiscoveryDepth: params.maxDiscoveryDepth,
              includePaths: params.includePaths,
              excludePaths: params.excludePaths,
              crawlEntireDomain: params.crawlEntireDomain,
              allowSubdomains: params.allowSubdomains,
              sitemap: params.sitemap,
              scrapeOptions: {
                formats: ["markdown"],
                onlyMainContent: params.onlyMainContent ?? true,
              },
            },
            requestSignal,
          )
          return { details: result, output: result }
        },
      ),
  })

  pi.registerTool({
    name: "scrape",
    label: "Scrape Page",
    description: SCRAPE_TOOL_DESCRIPTION,
    promptSnippet: SCRAPE_PROMPT_SNIPPET,
    promptGuidelines: SCRAPE_PROMPT_GUIDELINES,
    parameters: toolSchema(
      v.object({
        url: v.pipe(
          v.string(),
          v.description(SCRAPE_PARAMETER_DESCRIPTIONS.url),
        ),
        onlyMainContent: v.optional(
          v.pipe(
            v.boolean(),
            v.description(SCRAPE_PARAMETER_DESCRIPTIONS.onlyMainContent),
          ),
        ),
        waitFor: v.optional(
          v.pipe(
            v.number(),
            v.minValue(0),
            v.maxValue(60_000),
            v.description(SCRAPE_PARAMETER_DESCRIPTIONS.waitFor),
          ),
        ),
        timeout: v.optional(
          v.pipe(
            v.number(),
            v.minValue(1),
            v.maxValue(120_000),
            v.description(SCRAPE_PARAMETER_DESCRIPTIONS.timeout),
          ),
        ),
        includeMetadata: v.optional(
          v.pipe(
            v.boolean(),
            v.description(SCRAPE_PARAMETER_DESCRIPTIONS.includeMetadata),
          ),
        ),
      }),
    ),
    execute: (_toolCallId, params, signal, onUpdate) =>
      runFirecrawl(
        "scrape",
        `Scraping page with Firecrawl: ${params.url}`,
        (params.timeout ?? 30_000) + 5_000,
        signal,
        onUpdate,
        async (client) => {
          const document = await firecrawlRequest(() =>
            client.scrape(params.url, {
              formats: ["markdown"],
              onlyMainContent: params.onlyMainContent ?? true,
              waitFor: params.waitFor,
              timeout: params.timeout ?? 30_000,
            }),
          )
          try {
            const metadata =
              params.includeMetadata && document.metadata
                ? `\n\nMetadata:\n${stringify(document.metadata)}`
                : ""
            const markdown =
              document.markdown?.trim() || "No markdown content returned."
            return { details: document, output: `${markdown}${metadata}` }
          } catch (cause) {
            throw new OutputError(errorMessage(cause), { cause })
          }
        },
      ),
  })
}
