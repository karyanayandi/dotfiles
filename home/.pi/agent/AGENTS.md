- run check/format/lint commands when your done making a change. if they don't
  exist, suggest making them for the project you're in
- avoid explicit return types unless absolutely needed
- `as any` should be an absolute last resort. always use real type safety. lean
  on type inference instead of manually writing new types over and over again
- when fix linting errors, try to fix the root cause instead of just silencing
  the error and don't disable the rules. if you can't fix it, add a comment
  explaining why it's safe to ignore the error
