#!/usr/bin/env node
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const source = fs.readFileSync(path.join(__dirname, '../modules/Island.qml'), 'utf8');
const expression = source.match(/^    WlrLayershell.layer: (.+)$/m);
assert.ok(expression, 'Island layer binding exists');
const layer = new Function('interactive', 'view', 'WlrLayer', `return ${expression[1]}`);
const layers = { Overlay: 'overlay', Top: 'top' };
assert.equal(layer(false, 'volume', layers), 'overlay', 'Volume/mute covers fullscreen');
assert.equal(layer(false, '', layers), 'top', 'Idle bar stays behind fullscreen');
for (const view of ['launcher', 'controls', 'notifications', 'polkit', 'audio']) {
    assert.equal(layer(true, view, layers), 'overlay', `${view} keeps existing layer`);
}
assert.match(source, /WlrLayershell.keyboardFocus: .*WlrKeyboardFocus.None/);
console.log('PASS audio fullscreen layer and existing panel layers');
