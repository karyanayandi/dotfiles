import assert from "node:assert/strict"
import test from "node:test"
import { crawlEffect, type CrawlClient } from "./index.ts"

test("cancels the remote crawl when polling is interrupted", async () => {
  let pollingStarted!: () => void
  const startedPolling = new Promise<void>((resolve) => {
    pollingStarted = resolve
  })
  const cancelledJobs: string[] = []

  const client: CrawlClient = {
    startCrawl: async (url) => ({ id: "crawl-123", url }),
    getCrawlStatus: async () => {
      pollingStarted()
      return new Promise(() => undefined)
    },
    cancelCrawl: async (jobId) => {
      cancelledJobs.push(jobId)
      return true
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
