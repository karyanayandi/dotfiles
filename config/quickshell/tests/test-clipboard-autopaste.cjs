const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const source = fs.readFileSync(path.join(__dirname, '../services/ClipboardService.qml'), 'utf8');
const body = source.match(/function autopaste\(text\) \{([\s\S]*?)\n    \}/)[1];
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'clipboard-autopaste-'));
try {
    for (const backend of ['wtype', 'ydotool', 'missing']) {
        const bin = path.join(dir, backend);
        fs.mkdirSync(bin);
        for (const tool of ['sleep', 'notify-send', ...(backend === 'missing' ? [] : [backend])]) {
            fs.writeFileSync(path.join(bin, tool), '#!/bin/sh\nprintf "%s\\n" "$0" "$@" >> "$TRACE"\n', { mode: 0o755 });
        }
        const process = {};
        let copied;
        new Function('text', 'copy', 'Qt', 'root', body)('multiline\ntext\n', text => { copied = text; }, { createQmlObject() { return process; } }, {});
        assert.equal(copied, 'multiline\ntext\n', 'Copy must preserve original newlines');
        assert.equal(process.running, true);
        const trace = path.join(bin, 'trace');
        const result = spawnSync('/bin/sh', process.command.slice(1), { encoding: 'utf8', env: { ...global.process.env, PATH: bin, TRACE: trace } });
        assert.equal(result.status, 0, result.stderr);
        const actions = fs.readFileSync(trace, 'utf8').split('\n').slice(2);
        if (backend === 'wtype') {
            assert.deepEqual(actions, [path.join(bin, backend), '-M', 'ctrl', '-k', 'v', '-m', 'ctrl', '']);
        } else if (backend === 'ydotool') {
            assert.deepEqual(actions, [path.join(bin, backend), 'key', '29:1', '47:1', '47:0', '29:0', '']);
        } else {
            assert.equal(actions[0], path.join(bin, 'notify-send'));
        }
    }
    console.info('Clipboard autopaste checks passed: Ctrl+V only, no Enter; fallback notification preserved');
} finally {
    fs.rmSync(dir, { recursive: true, force: true });
}
