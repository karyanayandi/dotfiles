import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { Plugin } from "@opencode/plugin";

const dir = dirname(fileURLToPath(import.meta.url));

const INJECTED_MARKER = "Respond terse like smart caveman";

async function readProjectFile(directory) {
  for (const filename of ["AGENTS.md", "CLAUDE.md"]) {
    try {
      return await readFile(join(directory, filename), "utf-8");
    } catch (error) {
      if (error.code !== "ENOENT") throw error;
    }
  }
  return "";
}

function stripFrontmatter(text) {
  return text.replace(/^---\n[\s\S]*?\n---\n/, "");
}

export default Plugin.define({
  id: "caveman",
  async setup(ctx) {
    const skillPath = join(homedir(), ".agents", "skills", "caveman", "SKILL.md");
    const skillBody = stripFrontmatter(await readFile(skillPath, "utf-8"));
    const header = `${skillBody.slice(0, skillBody.indexOf("## Persistence")).trimEnd()}\n\nDefault intensity: ultra. Strip grammar and conjunctions; use fragments, standard technical abbreviations, arrows for causality, and one word when enough. Preserve every technical fact, negation, command, path, and code block. Use normal prose for security warnings, irreversible actions, ambiguous step sequences, and requests for clarification. Persist until the user changes the level or says "stop caveman" or "normal mode".`;

    const commandNames = ["caveman", "caveman-review", "caveman-commit"];
    const templates = new Map();
    for (const name of commandNames) {
      templates.set(name, (await readFile(join(dir, "commands", `${name}.md`), "utf-8")).trim());
    }

    await ctx.skill.transform((editor) => {
      editor.add({
        id: "caveman",
        name: "caveman",
        description:
          "Terse caveman voice: answer first, fluff gone, every technical fact kept. Use for /caveman, caveman mode, talk like caveman, be brief, less tokens. Stays on until stop caveman or normal mode.",
        path: skillPath,
        content: skillBody,
      });
    });

    await ctx.command.transform((editor) => {
      for (const [name, template] of templates) {
        editor.add({
          name,
          description: template.split("\n")[0],
          execute: async ({ sessionID, prompt, delivery }) => {
            const args = prompt.text?.trim() ? `\n\n${prompt.text}` : "";
            await ctx.session.prompt({ ...prompt, sessionID, text: `${template}${args}`, delivery });
          },
        });
      }
    });

    await ctx.tool.transform((editor) => {
      editor.add({
        name: "caveman_compress",
        description:
          "Returns caveman compression rules prepended to your AGENTS.md. Inject the output as session instructions to activate terse mode.",
        input: { type: "object", properties: {}, additionalProperties: false },
        execute: async () => {
          const existing = await readProjectFile(ctx.location.directory);
          const content = existing ? `${header}\n\n---\n\n${existing}`.trimEnd() : header;
          return { content };
        },
      });
    });

    await ctx.session.hook("context", (event) => {
      if (event.system.some((part) => part.type === "text" && part.text.includes(INJECTED_MARKER))) return;
      event.system.push({ type: "text", text: header });
    });
  },
});
