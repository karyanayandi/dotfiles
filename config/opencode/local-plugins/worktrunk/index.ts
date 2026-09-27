import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { Plugin } from "@opencode/plugin";

const run = promisify(execFile);

export default Plugin.define({
  id: "worktrunk",
  setup(ctx) {
    const controller = new AbortController();

    void (async () => {
      try {
        for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
          const args = event.type === "session.deleted"
            ? ["config", "state", "marker", "clear"]
            : event.type === "session.idle"
              ? ["config", "state", "marker", "set", "💬"]
              : event.type === "session.status" && event.data.status.type !== "idle"
                ? ["config", "state", "marker", "set", "🤖"]
                : undefined;
          if (!args) continue;
          try {
            await run("wt", args, { cwd: event.location?.directory ?? ctx.location.directory });
          } catch {
            // A non-worktree session has no marker to update.
          }
        }
      } catch (error) {
        if (!controller.signal.aborted) console.error("Worktrunk event stream failed", error);
      }
    })();

    return () => controller.abort();
  },
});
