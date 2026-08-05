/**
 * Self-check for the vim-mode editor. Run: `node --experimental-strip-types vim-mode.test.ts`
 * Exercises the modal logic against the real pi-tui Editor, wrapped as the
 * extension wraps the installed editor.
 */

import mod from "./index.ts";
import { Editor } from "@earendil-works/pi-tui";

const tui = { requestRender() {}, terminal: { rows: 24, cols: 80 } } as any;
const theme = { borderColor: (s: string) => s, selectList: {} } as any;
const kb = { matches: () => false } as any;

async function buildEditor(): Promise<Editor> {
	let factory: ((tui: any, theme: any, kb: any) => Editor) | undefined;
	const pi = {
		on(ev: string, h: (e: unknown, ctx: any) => void) {
			if (ev === "session_start")
				h({}, { ui: { getEditorComponent: () => undefined, setEditorComponent(f: typeof factory) { factory = f; } } });
		},
	};
	mod(pi as any);
	// The extension defers its wrap to a macrotask so it runs after other
	// session_start handlers; wait for it here too.
	await new Promise((r) => setTimeout(r, 5));
	return factory!(tui, theme, kb);
}

let failed = 0;
function assert(name: string, got: unknown, want: unknown) {
	const ok = JSON.stringify(got) === JSON.stringify(want);
	if (!ok) failed++;
	console.log(`${ok ? "PASS" : "FAIL"} ${name}${ok ? "" : ` got=${JSON.stringify(got)} want=${JSON.stringify(want)}`}`);
}

const ed = await buildEditor();
function keys(...ks: string[]) {
	for (const k of ks) ed.handleInput(k);
}

// Composition: the wrapper must delegate rendering to the base editor.
ed.setText("alpha\nbeta\ngamma");
const rendered = ed.render(40);
assert("render delegates (lines match text)", rendered.length >= 1, true);
assert("render has text", rendered.join("\n").includes("alpha"), true);

ed.setText("alpha\nbeta\ngamma");
ed.handleInput("\x1b"); // insert -> normal (setText starts cursor at end: line2)
keys("0");
assert("0 line start", ed.getCursor(), { line: 2, col: 0 });
keys("k");
assert("k up", ed.getCursor(), { line: 1, col: 0 });
keys("$");
assert("$ line end", ed.getCursor(), { line: 1, col: 4 });
keys("d", "d");
assert("dd", ed.getText(), "alpha\ngamma");
keys("y", "y", "p");
assert("yy p", ed.getText(), "alpha\ngamma\ngamma");
keys("g", "g");
assert("gg", ed.getCursor(), { line: 0, col: 0 });
keys("G");
assert("G", ed.getCursor(), { line: 2, col: 0 });
keys("o");
assert("o", ed.getText(), "alpha\ngamma\ngamma\n");
keys("\x1b", "O");
assert("O", ed.getText(), "alpha\ngamma\ngamma\n\n");
keys("\x1b", "g", "g", "r", "Z");
assert("r replace", ed.getText(), "Zlpha\ngamma\ngamma\n\n");

// Composition with a pre-existing editor (simulates @extensions/ui installing
// its SimpleEditor before vim wraps it): render must stay with prev's editor.
let prevFactory: ((t: any, th: any, k: any) => any) | undefined;
const pi2 = {
	on(ev: string, h: (e: unknown, ctx: any) => void) {
		if (ev === "session_start")
			h({}, { ui: { getEditorComponent: () => prevFactory, setEditorComponent(f: typeof prevFactory) { prevFactory = f; } } });
	},
};
mod(pi2 as any);
const markerTheme = { borderColor: (s: string) => s, selectList: {} } as any;
const prevEditor = new (class extends Editor {
	// eslint-disable-next-line @typescript-eslint/no-unused-vars
	render(width: number): string[] {
		return ["<LAYOUT>" + this.getText()];
	}
})(tui, markerTheme);
prevFactory = (_t, _th, _k) => prevEditor;
await new Promise((r) => setTimeout(r, 5));
const wrapped = prevFactory!(tui, theme, kb);
const prender = wrapped.render(40);
assert("wrap keeps prev render (layout not replaced)", prender.join("\n").includes("<LAYOUT>"), true);
wrapped.setText("a\nb");
wrapped.handleInput("\x1b"); // normal
wrapped.handleInput("k");
assert("vim works through wrapped prev editor", wrapped.getCursor(), { line: 0, col: 1 }); // sticky col clamps to "a" end

if (failed > 0) {
	console.error(`\n${failed} check(s) failed`);
	process.exit(1);
}
console.log("\nAll vim-mode checks passed");
