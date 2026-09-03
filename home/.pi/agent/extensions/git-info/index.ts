import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent"
import {
  emptyGitInfoState,
  GIT_INFO_CHANNEL,
  REFRESH_CHANNEL,
  type PullRequestInfo,
} from "@pi/shared/dashboard-state"
import { loadChangedFiles, showChangedFiles } from "./src/changed-files-view.ts"
import { runCommand } from "./src/process.ts"
import { makeRefreshCoordinator } from "./src/refresh-coordinator.ts"

const POLL_INTERVAL_MS = 3_000
const GIT_TIMEOUT_MS = 3_000
const GH_TIMEOUT_MS = 10_000

function countChangedFiles(status: string) {
  if (!status.trim()) return 0
  return status.split("\n").filter(Boolean).length
}

function parsePullRequest(value: unknown) {
  if (typeof value !== "object" || value === null) return null
  if (!("number" in value) || typeof value.number !== "number") return null
  if (!("url" in value) || typeof value.url !== "string") return null
  if (!("state" in value) || value.state !== "OPEN") return null

  return {
    number: value.number,
    url: value.url,
    isDraft: "isDraft" in value && value.isDraft === true,
  } satisfies PullRequestInfo
}

function parsePullRequestJson(value: string) {
  try {
    return parsePullRequest(JSON.parse(value))
  } catch {
    return null
  }
}

function delay(ms: number, signal: AbortSignal) {
  return new Promise<boolean>((resolve) => {
    const timer = setTimeout(() => {
      signal.removeEventListener("abort", onAbort)
      resolve(true)
    }, ms)
    const onAbort = () => {
      clearTimeout(timer)
      resolve(false)
    }
    signal.addEventListener("abort", onAbort, { once: true })
  })
}

function abortedError(message: string) {
  return new Error(message)
}

export default function gitInfo(pi: ExtensionAPI) {
  let state = emptyGitInfoState()
  let polling: { controller: AbortController; done: Promise<void> } | undefined
  let currentContext: ExtensionContext | undefined
  let generation = 0
  let queriedPrBranch: string | null = null
  const refreshCoordinator = makeRefreshCoordinator()
  const publish = () => {
    pi.events.emit(GIT_INFO_CHANNEL, { ...state })
    if (!currentContext) return

    currentContext.ui.setStatus(
      "worktrunk",
      state.isRepository &&
        state.branch &&
        !["main", "master"].includes(state.branch)
        ? currentContext.ui.theme.fg("accent", `branch: ${state.branch}`)
        : undefined,
    )
  }
  const run = (
    command: string,
    args: string[],
    ctx: ExtensionContext,
    timeout: number,
    signal?: AbortSignal,
  ) => runCommand(command, args, ctx.cwd, timeout, signal)

  const lookupPullRequest = async (
    ctx: ExtensionContext,
    branch: string,
    signal?: AbortSignal,
  ) => {
    const result = await run(
      "gh",
      ["pr", "view", branch, "--json", "number,url,state,isDraft"],
      ctx,
      GH_TIMEOUT_MS,
      signal,
    )
    if (result.code !== 0) return null
    return parsePullRequestJson(result.stdout)
  }

  const refreshTask = async (
    ctx: ExtensionContext,
    forcePullRequest: boolean,
    refreshGeneration: number,
    signal?: AbortSignal,
  ) => {
    if (refreshGeneration !== generation) return
    currentContext = ctx

    const repo = await run(
      "git",
      ["rev-parse", "--is-inside-work-tree"],
      ctx,
      GIT_TIMEOUT_MS,
      signal,
    )
    if (refreshGeneration !== generation) return

    if (repo.code !== 0 || repo.stdout.trim() !== "true") {
      queriedPrBranch = null
      state = emptyGitInfoState()
      publish()
      return
    }

    const [branchResult, headResult, statusResult] = await Promise.all([
      run("git", ["branch", "--show-current"], ctx, GIT_TIMEOUT_MS, signal),
      run("git", ["rev-parse", "--short", "HEAD"], ctx, GIT_TIMEOUT_MS, signal),
      run(
        "git",
        // Avoid recursively scanning every untracked file on each poll.
        ["status", "--porcelain=v1", "--untracked-files=normal"],
        ctx,
        GIT_TIMEOUT_MS,
        signal,
      ),
    ])
    if (refreshGeneration !== generation) return

    const branchName = branchResult.stdout.trim()
    const shortHead = headResult.stdout.trim()
    const branch =
      branchName || (shortHead ? `detached@${shortHead}` : "detached")
    const branchChanged = branchName !== queriedPrBranch

    state = {
      ...state,
      isRepository: true,
      branch,
      changedFiles:
        statusResult.code === 0 ? countChangedFiles(statusResult.stdout) : 0,
      pullRequest: branchChanged ? null : state.pullRequest,
    }
    publish()

    if (!branchName) {
      // queriedPrBranch is never "", so branchChanged already cleared pullRequest.
      queriedPrBranch = null
      return
    }

    if (forcePullRequest || branchChanged) {
      queriedPrBranch = branchName
      const pullRequest = await lookupPullRequest(ctx, branchName, signal)
      if (refreshGeneration !== generation) return
      state = { ...state, pullRequest }
      publish()
    }
  }

  const refresh = (
    ctx: ExtensionContext,
    forcePullRequest = false,
    signal?: AbortSignal,
  ) =>
    refreshCoordinator.run(() =>
      refreshTask(ctx, forcePullRequest, generation, signal),
    )

  const refreshIfIdle = (ctx: ExtensionContext, signal?: AbortSignal) =>
    refreshCoordinator.runIfIdle(() =>
      refreshTask(ctx, false, generation, signal),
    )

  const reportBackgroundDefect = (error: unknown) => {
    console.error("git-info background task defect", error)
  }

  const refreshInBackground = (ctx: ExtensionContext) => {
    void refreshIfIdle(ctx).catch(reportBackgroundDefect)
  }

  const poll = async (signal: AbortSignal) => {
    while (await delay(POLL_INTERVAL_MS, signal)) {
      if (!currentContext) continue
      try {
        await refreshIfIdle(currentContext, signal)
      } catch (error) {
        if (!signal.aborted) reportBackgroundDefect(error)
      }
    }
  }

  const stopPolling = async () => {
    const previous = polling
    polling = undefined
    if (!previous) return
    previous.controller.abort()
    await previous.done
  }

  const startPolling = () => {
    const controller = new AbortController()
    const done = poll(controller.signal)
    polling = { controller, done }
  }

  const stopRefreshListener = pi.events.on(REFRESH_CHANNEL, () => {
    if (currentContext) refreshInBackground(currentContext)
  })

  pi.on("session_start", async (_event, ctx) => {
    generation += 1
    queriedPrBranch = null
    await stopPolling()

    // Do not block Pi startup on GitHub/network I/O. The initial refresh publishes
    // state when it completes; polling continues to keep it current afterwards.
    refreshInBackground(ctx)
    startPolling()
  })

  pi.on("input", (_event, ctx) => {
    refreshInBackground(ctx)
    return { action: "continue" }
  })

  pi.on("tool_execution_end", (_event, ctx) => {
    refreshInBackground(ctx)
  })

  pi.on("session_shutdown", async () => {
    stopRefreshListener()
    generation += 1
    currentContext?.ui.setStatus("worktrunk", undefined)
    currentContext = undefined
    await stopPolling()
  })

  pi.registerCommand("lg", {
    description: "Browse changed files and their diffs",
    handler: async (_args, ctx) => {
      if (ctx.mode !== "tui") {
        ctx.ui.notify(
          "The local changes viewer requires the interactive TUI",
          "warning",
        )
        return
      }

      let files
      try {
        files = await loadChangedFiles(ctx.cwd, ctx.signal)
      } catch (error) {
        if (ctx.signal?.aborted) {
          throw abortedError("Loading changed files was cancelled.")
        }
        throw error
      }
      if (files === null) {
        ctx.ui.notify("Not a git repository", "warning")
        return
      }
      if (files.length === 0) {
        ctx.ui.notify("Working tree is clean", "info")
        return
      }

      await showChangedFiles(ctx, files)
    },
  })

  pi.registerCommand("pr", {
    description: "Refresh git and pull request information",
    handler: async (_args, ctx) => {
      try {
        await refresh(ctx, true, ctx.signal)
      } catch (error) {
        if (ctx.signal?.aborted) {
          throw abortedError("Git and pull request refresh was cancelled.")
        }
        throw error
      }
      if (!state.isRepository) {
        ctx.ui.notify("Not a git repository", "warning")
      } else if (state.pullRequest) {
        ctx.ui.notify(
          `PR #${state.pullRequest.number}: ${state.pullRequest.url}`,
          "info",
        )
      } else {
        ctx.ui.notify(`No open PR found for ${state.branch}`, "info")
      }
    },
  })
}
