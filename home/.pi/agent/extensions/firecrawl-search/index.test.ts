import assert from "node:assert/strict"
import test from "node:test"
import { crawlEffect, type CrawlClient } from "./index.ts"

await test("cancels the remote crawl when polling is interrupted", async () => {
  let pollingStarted!: () => void

  const startedPolling = new Promise<void>((resolve) => {
    pollingStarted = resolve
  })

  const cancelledJobs: string[] = []

  const client: CrawlClient = {
    startCrawl: (url) => Promise.resolve({ id: "crawl-123", url }),
    getCrawlStatus: () => {
      pollingStarted()

      return new Promise(() => undefined)
    },
    cancelCrawl: (jobId) => {
      cancelledJobs.push(jobId)

      return Promise.resolve(true)
    },
  }

  const controller = new AbortController()

  const running = crawlEffect(
    client,
    "https://example.com",
    { limit: 1 },
    controller.signal,
  )

  const interrupted = assert.rejects(running)

  await startedPolling
  controller.abort()
  await interrupted

  assert.deepEqual(cancelledJobs, ["crawl-123"])
})

await test("preserves crawl request rejection causes", async () => {
  const cause = new Error("network down")

  const client: CrawlClient = {
    startCrawl: () =>
      Promise.resolve({ id: "crawl-123", url: "https://example.com" }),
    getCrawlStatus: () => Promise.reject(cause),
    cancelCrawl: () => Promise.resolve(true),
  }

  await assert.rejects(
    crawlEffect(client, "https://example.com", { limit: 1 }),
    { cause },
  )
})
