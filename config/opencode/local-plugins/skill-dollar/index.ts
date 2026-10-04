import { Plugin, Skill } from "@opencode/plugin";

const PATTERN = /\$([a-z0-9]+(?:-[a-z0-9]+)*)/g;

function toLines(ids: ReadonlyArray<string>, descriptions: ReadonlyMap<string, string>): string {
  if (ids.length === 0) return "No skills are installed. Type $ followed by a skill id once one exists.";
  return ids
    .map((id) => {
      const description = descriptions.get(id);
      return description ? `- $${id} — ${description}` : `- $${id}`;
    })
    .join("\n");
}

export default Plugin.define({
  id: "skill-dollar",
  async setup(ctx) {
    const promptHook = await ctx.session.hook("prompt", async (event) => {
      if (!event.prompt.text.includes("$")) return;
      const { data } = await ctx.skill.list();
      const known = new Set<string>(data.map((skill) => skill.id));
      if (known.size === 0) return;

      event.prompt.skills ??= [];
      const attached = new Set<string>(event.prompt.skills.map((skill) => skill.id));
      event.prompt.text = event.prompt.text.replace(
        PATTERN,
        (full: string, id: string, offset: number): string => {
          if (!known.has(id)) return full;
          if (!attached.has(id)) {
            attached.add(id);
            event.prompt.skills?.push({
              id: Skill.ID.make(id),
              mention: { start: offset, end: offset + full.length, text: `@${id}` },
            });
          }
          return `@${id}`;
        },
      );
    });

    const skillsCommand = await ctx.command.transform((editor) => {
      editor.add({
        name: "skills",
        description: "List available skills ($)",
        execute: async ({ sessionID, prompt, delivery }) => {
          const { data } = await ctx.skill.list();
          const ids = data.map((skill) => skill.id);
          const descriptions = new Map<string, string>(data.map((skill) => [skill.id, skill.description ?? ""] as const));
          await ctx.session.prompt({
            ...prompt,
            sessionID,
            text: toLines(ids, descriptions),
            delivery,
          });
        },
      });
    });

    return async () => {
      await promptHook.dispose();
      await skillsCommand.dispose();
    };
  },
});
