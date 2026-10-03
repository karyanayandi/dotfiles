import * as v from "valibot"

export const MODEL_INFO_CHANNEL = "dashboard:model-info"

export const GIT_INFO_CHANNEL = "dashboard:git-info"

export const REFRESH_CHANNEL = "dashboard:refresh"

export interface ModelInfoState {
  provider: string
  modelId: string
  modelName: string
  thinking: string
  contextTokens: number | null
  contextWindow: number
  contextPercent: number | null
  cost: number
  tokensPerSecond: number | null
  generating: boolean
}

export interface PullRequestInfo {
  number: number
  url: string
  isDraft: boolean
}

export interface GitInfoState {
  isRepository: boolean
  branch: string | null
  changedFiles: number
  pullRequest: PullRequestInfo | null
}

export function emptyModelInfoState(): ModelInfoState {
  return {
    provider: "",
    modelId: "no-model",
    modelName: "No model",
    thinking: "off",
    contextTokens: null,
    contextWindow: 0,
    contextPercent: null,
    cost: 0,
    tokensPerSecond: null,
    generating: false,
  }
}

export function emptyGitInfoState(): GitInfoState {
  return {
    isRepository: false,
    branch: null,
    changedFiles: 0,
    pullRequest: null,
  }
}

const modelInfoSchema = v.object({
  provider: v.string(),
  modelId: v.string(),
  modelName: v.string(),
  thinking: v.string(),
  contextTokens: v.nullable(v.number()),
  contextWindow: v.number(),
  contextPercent: v.nullable(v.number()),
  cost: v.number(),
  tokensPerSecond: v.nullable(v.number()),
  generating: v.boolean(),
})

const gitInfoSchema = v.object({
  isRepository: v.boolean(),
  branch: v.nullable(v.string()),
  changedFiles: v.number(),
  pullRequest: v.nullable(
    v.object({
      number: v.number(),
      url: v.string(),
      isDraft: v.boolean(),
    }),
  ),
})

export function isModelInfoState<Value>(
  value: Value,
): value is Value & ModelInfoState {
  return v.is(modelInfoSchema, value)
}

export function isGitInfoState<Value>(
  value: Value,
): value is Value & GitInfoState {
  return v.is(gitInfoSchema, value)
}
