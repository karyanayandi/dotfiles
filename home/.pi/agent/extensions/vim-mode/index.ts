/**
 * Vim motion for pi's TUI input editor.
 *
 * Layers vim (normal/insert modal) onto the *existing* editor instead of
 * replacing it. It waits until every other extension's `session_start` handler
 * (notably @extensions/ui, which owns layout/borders/status) has installed its
 * editor, then wraps that editor instance and overrides only `handleInput`.
 * Rendering and layout stay entirely with the base editor.
 *
 * Install: drop in ~/.pi/agent/extensions/vim-mode/index.ts, then /reload.
 *
 * ponytail: skips visual mode, numeric counts, search, macros, . repeat, ^, {}.
 */

import { CustomEditor, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { matchesKey, type Editor } from "@earendil-works/pi-tui";

// Key sequences the pi editor already understands (default keybindings).
// Verified against pi-tui's parseKey.
const SEQ = {
	up: "\x1b[A",
	down: "\x1b[B",
	left: "\x1b[D",
	right: "\x1b[C",
	lineStart: "\x01", // ctrl+a
	lineEnd: "\x05", // ctrl+e
	delForward: "\x1b[3~", // delete
	delBackward: "\x7f", // backspace
	wordLeft: "\x1bb", // alt+left
	wordRight: "\x1bf", // alt+right
	delWordForward: "\x1b[3;3~", // alt+delete
	delToLineEnd: "\x0b", // ctrl+k
	undo: "\x1f", // ctrl+-
} as const;

type Mode = "normal" | "insert";

/**
 * Build a handleInput that layers vim mode over `base`. All text ops and the
 * base editor's own state stay authoritative. Returns a wrapper that inherits
 * every other method (render, autocomplete, ...) from `base`.
 */
function wrapEditor(base: Editor): Editor {
	const inject = (seq: string) => base.handleInput(seq);
	const cursor = () => base.getCursor();
	const lines = () => base.getLines();

	const moveTo = (targetLine: number, targetCol: number) => {
		const start = cursor();
		const dy = targetLine - start.line;
		const v = dy < 0 ? SEQ.up : SEQ.down;
		for (let i = 0; i < Math.abs(dy); i++) inject(v);
		const after = cursor();
		const dx = targetCol - after.col;
		const h = dx < 0 ? SEQ.left : SEQ.right;
		for (let i = 0; i < Math.abs(dx); i++) inject(h);
	};

	const deleteCurrentLine = () => {
		const l = lines();
		const cur = cursor();
		if (l.length === 0) return;
		l.splice(cur.line, 1);
		base.setText(l.join("\n"));
		moveTo(cur.line, 0);
	};

	const changeCurrentLine = () => {
		deleteCurrentLine();
		mode = "insert";
	};

	const yankCurrentLine = () => {
		register = lines()[cursor().line] ?? "";
	};

	const pasteAfter = () => {
		if (!register) return;
		const l = lines();
		const cur = cursor();
		const next = [...l.slice(0, cur.line + 1), register, ...l.slice(cur.line + 1)];
		base.setText(next.join("\n"));
		moveTo(cur.line + 1, 0);
	};

	const pasteBefore = () => {
		if (!register) return;
		const l = lines();
		const cur = cursor();
		const next = [...l.slice(0, cur.line), register, ...l.slice(cur.line)];
		base.setText(next.join("\n"));
		moveTo(cur.line, 0);
	};

	const openBelow = () => {
		const l = lines();
		const cur = cursor();
		const next = [...l.slice(0, cur.line + 1), "", ...l.slice(cur.line + 1)];
		base.setText(next.join("\n"));
		moveTo(cur.line + 1, 0);
		mode = "insert";
	};

	const openAbove = () => {
		const l = lines();
		const cur = cursor();
		const next = [...l.slice(0, cur.line), "", ...l.slice(cur.line)];
		base.setText(next.join("\n"));
		moveTo(cur.line, 0);
		mode = "insert";
	};

	const normal = (key: string) => {
		switch (key) {
			case "h": inject(SEQ.left); return;
			case "j": inject(SEQ.down); return;
			case "k": inject(SEQ.up); return;
			case "l": inject(SEQ.right); return;
			case "w":
			case "e": inject(SEQ.wordRight); return;
			case "b": inject(SEQ.wordLeft); return;
			case "0": inject(SEQ.lineStart); return;
			case "$": inject(SEQ.lineEnd); return;
			case "G": moveTo(lines().length - 1, 0); return;
			case "x": inject(SEQ.delForward); return;
			case "X": inject(SEQ.delBackward); return;
			case "u": inject(SEQ.undo); return;
			case "D": inject(SEQ.delToLineEnd); return;
			case "i": mode = "insert"; return;
			case "a": inject(SEQ.right); mode = "insert"; return;
			case "I": inject(SEQ.lineStart); mode = "insert"; return;
			case "A": inject(SEQ.lineEnd); mode = "insert"; return;
			case "o": openBelow(); return;
			case "O": openAbove(); return;
			case "s": inject(SEQ.delForward); mode = "insert"; return;
			case "S": changeCurrentLine(); return;
			case "p": pasteAfter(); return;
			case "P": pasteBefore(); return;
			case "d": pending = "d"; return;
			case "c": pending = "c"; return;
			case "y": pending = "y"; return;
			case "g": pending = "g"; return;
			case "r": pending = "r"; return;
			default:
				// Unbound printable key: ignore (vim does too).
				return;
		}
	};

	const operator = (key: string) => {
		const op = pending;
		pending = "";
		if (op === "d") {
			if (key === "d") return deleteCurrentLine();
			if (key === "w") return inject(SEQ.delWordForward);
			if (key === "$") return inject(SEQ.delToLineEnd);
		} else if (op === "c") {
			if (key === "c") return changeCurrentLine();
			if (key === "w") { inject(SEQ.delWordForward); mode = "insert"; return; }
			if (key === "$") { inject(SEQ.delToLineEnd); mode = "insert"; return; }
		} else if (op === "y") {
			if (key === "y") return yankCurrentLine();
		} else if (op === "g") {
			if (key === "g") return moveTo(0, 0);
		} else if (op === "r") {
			inject(SEQ.delForward);
			base.insertTextAtCursor(key);
			inject(SEQ.left);
		}
	};

	let mode: Mode = "insert";
	let register = "";
	let pending = "";

	// Inherit every method/field from base. Guard `state` so any assignment like
	// `this.state = draft` (setTextInternal, undo) lands on base instead of
	// creating a detached own property on the wrapper.
	const wrapped = Object.create(base) as Editor;
	const baseAny = base as unknown as { state: unknown };
	Object.defineProperty(wrapped, "state", {
		configurable: true,
		get() { return baseAny.state; },
		set(v) { baseAny.state = v; },
	});

	wrapped.handleInput = (data: string) => {
		// Escape: insert -> normal; in normal, pass through (abort agent, etc).
		if (matchesKey(data, "escape")) {
			if (mode === "insert") mode = "normal";
			else base.handleInput(data);
			return;
		}

		if (mode === "insert") {
			base.handleInput(data);
			return;
		}

		// Normal mode: only single printable chars are vim commands.
		// Control sequences / arrows / ctrl shortcuts pass through (both modes).
		if (data.length !== 1 || data.charCodeAt(0) < 32) {
			base.handleInput(data);
			return;
		}

		if (pending) operator(data);
		else normal(data);
	};

	return wrapped;
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		// Defer to the next macrotask so every other extension's session_start
		// handler (e.g. @extensions/ui) has installed its editor first. We then
		// wrap that editor rather than replacing it.
		setTimeout(() => {
			const prev = ctx.ui.getEditorComponent();
			ctx.ui.setEditorComponent((tui, theme, kb) => {
				const base = prev ? (prev(tui, theme, kb) as Editor) : new CustomEditor(tui, theme, kb);
				return wrapEditor(base);
			});
		}, 0);
	});
}
