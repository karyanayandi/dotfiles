# Agent guidelines

## Scope and priority

- Read the closest project-specific `AGENTS.md` before changing code.
- If a user asks to update `AGENTS.md` only, edit only `AGENTS.md`. Do not
  change source files, dependencies, lockfiles, or generated files.
- Before code search, use `code-index-mcp`. Select the project with
  `set_project_path`. Check `get_settings_info`.
- Keep the file watcher off. Call `configure_file_watcher` with `enabled=false`,
  then call `set_project_path` again for the same project. Check that
  `get_file_watcher_status` reports `active=false` before you build a deep index.
- Use `search_code_advanced` and `find_files` for code context. Follow search
  pagination with `start_index` when `has_more=true`. Use `refresh_index` when
  the file list is stale.
- Use `build_deep_index` with `max_workers=1` only when you need symbol data.
  Then use `get_file_summary` and `get_symbol_body`. Do not rebuild before each
  search. Rebuild symbol data after source changes if you need current symbols.
- Hidden paths and some languages have limited coverage. Use native search when
  required files are absent or the server is unavailable. State the reason.
- Inspect existing callers, types, tests, and configuration before editing.
- Make smallest complete change. Reuse existing code before adding helpers,
  abstractions, dependencies, or configuration.
- Only `AGENTS.md`, `README.md`, and `LICENSE.md` may be committed as Markdown
  files. Put detailed plans and working documentation in gitignored `docs/`.
  Keep `README.md` focused on project overview, setup, usage, and license.

## Work quality and continuity

- Do not speculate about token budgets, remaining context, or time left. Do not
  narrate internal resource accounting or invent deadlines.
- Never use perceived token, context, or time pressure to rush work, reduce the
  requested scope, skip investigation or validation, or settle for a partial or
  lower-quality fix.
- When context fills, rely on Pi's supported compaction mechanism and continue
  working. Preserve the task, constraints, decisions, relevant files, exact
  diagnostics, validation results, and next steps across compaction. Re-read
  source material when needed rather than guessing from a summary.
- Prefer the smallest complete, correct solution, not the quickest shortcut.
  Efficiency means avoiding unnecessary work, not weakening reasoning,
  correctness, safety, maintainability, or test coverage.
- Continue until the requested work is complete and verified, or a concrete
  blocker requires user input. Report actual blockers and unfinished checks
  honestly; never claim completion because of perceived resource pressure.

## Validation

- After making changes, run the project's available check, format, and lint
  commands.
- If any command is unavailable, say so and suggest adding it.
- When lint, typecheck, or tests fail, read the exact diagnostic and fix the
  underlying code or test to satisfy the existing rule, type contract, or
  expected behavior. Follow the linter's requested pattern rather than hiding
  the violation.
- Never suppress or weaken checks as a substitute for fixing failures: do not
  change rule or compiler configuration, use type escape hatches, skip tests,
  remove assertions, or narrow test selection to hide failures.
- If a lint rule genuinely cannot be satisfied for one specific line, a
  line-scoped disable is allowed only for that rule and line. Add a nearby
  comment explaining why the exception is necessary; never disable the rule for
  an entire file or project.
- Rerun the failing command after the fix and report any remaining failures.

## Testing

- Never write unit tests after writing implementation code. If unit tests are
  necessary, define them before implementation, not as a retrospective check.
- Strongly prefer end-to-end (E2E) tests as the sole testing mechanism. Exercise
  complex features through real user workflows and observable outcomes rather
  than testing internal functions or mocked interactions in isolation.
- Make E2E runs reproducible: state prerequisites, use repeatable setup and
  inputs, and leave a verifiable artifact at the end (such as a test report,
  trace, screenshot, or saved output) with enough context to confirm the result
  and rerun the same scenario. Do not claim success without checking the
  artifact.
- If isolation testing is unavoidable, first enumerate the expected behavior and
  all plausible failure modes and edge cases; write the corresponding tests
  before implementation code. Do not add isolated tests afterward merely to
  mirror code already written.

## TypeScript

- Keep type safety. Never use the `any` type, `as any`, or `as unknown as`.
- Use accurate types, type narrowing, generics, or runtime validation instead of
  unsafe casts.
- Let TypeScript infer return types unless an explicit type is necessary.
- Do not use dynamic `await import(...)` calls.
- Do not use `await import()`. Use static imports.
- Prefer function declarations. Use arrow functions only when needed, such as
  inline callbacks, closures, or APIs that require a function expression.
- Use `const` whenever reassignment is unnecessary.
- Do not use `console.log`; use `console.error`, `console.warn`, or
  `console.info` when logging is necessary.

## Functions and React

- Use normal function declarations by default.
- Define and export components and hooks in one declaration with
  `export function`.
- React components and hooks must use named `export function` declarations.
  Never use `export default` for React code.
- Keep components small, reusable, composable, and easy to maintain. Extract
  focused subcomponents when a component gains unrelated responsibilities.
- Do not define a function and export it separately.
- Ban `useEffect` entirely. Do not import or call it. Prefer derived values,
  event handlers, or framework APIs.
- Ban `useCallback` and `useMemo` entirely. Do not import or call it. Let React
  Compiler handle memoization.

## Comments and documentation

- Do not add comments or JSDoc unless they are necessary to explain non-obvious
  behavior, a required workaround, or a public API contract.
- Prefer clear names and straightforward code over explanatory comments.
- When you add or update documentation, comments, JSDoc, or instructions
  inside code, use ASD-STE100 Simplified Technical English: approved words,
  short sentences, and active voice. Keep required technical names, code
  identifiers, and syntax unchanged.

## Development servers

- Before starting a development server, check whether one is already running.
- If one is running, do not start another server or switch to a different port.
- Ask the user to stop the existing process before starting a replacement.

## Browser automation

- When using Playwriter, prefer the current active tab. Open a new tab only when
  the task genuinely requires it.

## Git

- Use Conventional Commits: `<type>(scope): <description>`. Scope is optional;
  if used, enclose it in parentheses, not square brackets. Add `!` before `:`
  for a breaking change.
- Write exactly one commit message for all changes in the commit. Use one
  title that summarizes the complete change and one body that gives details.
  Do not write separate commit messages for each file or change.
- Keep the full title under 50 characters, including the type and scope.
- Separate the title and body with a blank line. Use prose or a list for the
  body, and wrap each line at 72 characters, including list markers and indent.
- Use ASD-STE100 Simplified Technical English for the title description and
  body: use approved words, short sentences, and active voice. Keep required
  technical names and code identifiers unchanged.
