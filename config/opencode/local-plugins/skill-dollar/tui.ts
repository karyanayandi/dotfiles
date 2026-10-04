import { Plugin } from "@opencode/plugin/tui";

interface SkillOption {
  readonly title: string;
  readonly value: string;
  readonly description?: string;
}

function matches(query: string, option: SkillOption): boolean {
  const haystack = `${option.value} ${option.title} ${option.description ?? ""}`.toLowerCase();
  return query
    .toLowerCase()
    .split(/\s+/)
    .filter((part) => part.length > 0)
    .every((part) => haystack.includes(part));
}

export default Plugin.define({
  id: "skill-dollar.cli",
  setup(context) {
    const bind = typeof context.options.bind === "string" ? context.options.bind : "ctrl+s";
    context.keymap.layer(() => ({
      mode: "global",
      commands: [
        {
          id: "skill-dollar.open",
          title: "Skill: Insert ($)",
          description: "Pick a skill and show its @mention to insert",
          group: "Skills",
          bind,
          palette: true,
          slash: { name: "skills" },
          run: async () => {
            const location = context.location ?? context.data.location.default();
            try {
              await context.data.location.skill.sync(location);
            } catch {
              context.ui.toast.show({
                message: "Skill refresh failed; showing cached skills.",
                variant: "warning",
              });
            }
            const skills = context.data.location.skill.list(location) ?? [];
            if (skills.length === 0) {
              context.ui.toast.show({ message: "No skills installed.", variant: "info" });
              return;
            }
            const request = {
              title: "Skills ($)",
              placeholder: "Filter by id, name, or description",
              options: skills.map((skill) => ({
                title: skill.name,
                value: skill.id,
                description:
                  `$${skill.id}` + (skill.description ? ` — ${skill.description}` : ""),
              })),
              search: (query: string, candidates: ReadonlyArray<SkillOption>) =>
                candidates.filter((candidate) => matches(query, candidate)),
            };
            const picked = await context.ui.dialog.select(request);
            if (picked === undefined) return;
            context.ui.toast.show({
              message: `@${picked} — type @${picked} or $${picked} to attach`,
              variant: "info",
            });
          },
        },
      ],
      bindings: ["skill-dollar.open"],
    }));
  },
});
