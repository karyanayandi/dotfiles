const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const source = fs.readFileSync(path.join(__dirname, '../services/ClipboardService.qml'), 'utf8');
const command = new Function('root', `return ${source.match(/command: (\["sh", "-c",[^\n]+)/)[1]};`);
const body = source.match(/(?:onRead: data =>|onStreamFinished:) \{([\s\S]*?)\n            \}/)[1];
const receive = new Function('data', 'text', 'root', body);
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'clipboard-check-'));
try {
    fs.writeFileSync(path.join(dir, 'wl-paste'), '#!/bin/sh\n[ "$1" = "--list-types" ] && { printf "text/plain\\n"; exit; }\ncat "$PAYLOAD"\n');
    fs.chmodSync(path.join(dir, 'wl-paste'), 0o755);
    const root = { imgDir: path.join(dir, 'images'), history: [], maxSize: 100, _lastHash: '', historyChanged() {}, save() {} };
    const payload = '  start\n' + 'long 🦄 text\n'.repeat(2000) + '\nend  \n\n';
    fs.writeFileSync(path.join(dir, 'payload'), payload);
    const argv = command(root);
    const result = spawnSync(argv[0], argv.slice(1), { encoding: 'utf8', env: { ...process.env, PATH: `${dir}:${process.env.PATH}`, PAYLOAD: path.join(dir, 'payload') } });
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.stdout, payload, 'Polling must preserve entire multiline payload');
    assert.match(source, /stdout: StdioCollector/, 'Capture must collect full stream, not separate lines');
    receive(result.stdout, result.stdout, root);
    assert.equal(root.history[0].text, payload, 'History must preserve whitespace and Unicode');
    receive(payload, payload, root);
    assert.equal(root.history.length, 1, 'Repeated polls must not duplicate entries');
    const changed = payload.replace('end', 'END');
    receive(changed, changed, root);
    assert.equal(root.history[0].text, changed, 'Same-length changes beyond prefix must not be lost');
    assert.equal(root.history.length, 2);
    receive('', '', root);
    assert.equal(root.history.length, 2);
    receive('   \n', '   \n', root);
    assert.equal(root.history[0].text, '   \n', 'Whitespace-only selections remain valid');
    receive('IMG:/tmp/clipboard.png\n', 'IMG:/tmp/clipboard.png\n', root);
    assert.equal(root.history[0].img, '/tmp/clipboard.png');
    console.info('Clipboard full-text checks passed');
} finally {
    fs.rmSync(dir, { recursive: true, force: true });
}
