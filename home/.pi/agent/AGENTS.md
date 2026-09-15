# Agent guidelines

## Validation

- After making changes, run the project's available check, format, and lint commands.
- If any command is unavailable, say so and suggest adding it.
- Fix lint errors at their source. Do not disable lint rules.
- If a lint exception is safe and necessary, document why in a code comment.

## TypeScript

- Keep type safety. Never use the `any` type, `as any`, or `as unknown as`.
- Use accurate types, type narrowing, generics, or runtime validation instead of unsafe casts.
- Let TypeScript infer return types unless an explicit type is necessary.
- Do not use dynamic `await import(...)` calls.

## Functions and React

- Use normal function declarations by default.
- Use arrow functions only when they are needed, such as callbacks or lexical `this`.
- In React, define and export components and hooks in one declaration with `export function`.
- Keep components small, reusable, composable, and easy to maintain. Extract focused subcomponents when a component gains unrelated responsibilities.
- Do not define a function and export it separately.
- Ban `useEffect` entirely. Do not import or call it. Prefer derived values, event handlers, or framework APIs.

## Comments and documentation

- Do not add comments or JSDoc unless they are necessary to explain non-obvious behavior, a required workaround, or a public API contract.
- Prefer clear names and straightforward code over explanatory comments.

## Development servers

- Before starting a development server, check whether one is already running.
- If one is running, do not start another server or switch to a different port.
- Ask the user to stop the existing process before starting a replacement.
