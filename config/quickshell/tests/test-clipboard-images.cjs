const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const source = fs.readFileSync(path.join(__dirname, '../modules/launcher/LauncherModel.qml'), 'utf8');
const body = source.match(/readonly property var results: \{([\s\S]*?)\n    \}\n\n    signal/)[1];
const results = new Function('root', 'clipSvc', body);
const history = [
    { text: 'new text', time: 30, preview: 'new text' },
    { img: '/tmp/new.png', text: '', time: 20 },
    { img: '/tmp/old.png', text: '', time: 10 }
];
const clips = { history };
const root = { mode: 'clipboard-images', _debouncedQuery: '' };
assert.deepEqual(results(root, clips).map(item => item.img), ['/tmp/new.png', '/tmp/old.png']);
assert.deepEqual(results(root, clips).map(item => item.index), [1, 2]);
root._debouncedQuery = 'image';
assert.equal(results(root, clips).length, 2);
root._debouncedQuery = 'new text';
assert.equal(results(root, clips).length, 0);
root._debouncedQuery = '';
root.mode = 'clipboard';
assert.equal(results(root, clips).length, 3);
assert.deepEqual(results(root, { history: [] }), []);
root.mode = 'clipboard-images';
assert.deepEqual(results(root, { history: [history[0]] }), []);
const hypr = fs.readFileSync(path.join(__dirname, '../../hypr/bind.lua'), 'utf8');
const niri = fs.readFileSync(path.join(__dirname, '../../niri/config.kdl'), 'utf8');
assert.match(hypr, /mainMod \..*" \+ CTRL \+ P".*launcher open clipboard-images/);
assert.match(niri, /Mod\+Ctrl\+P.*launcher open clipboard-images/);
console.info('Clipboard image filter and shortcut checks passed');
