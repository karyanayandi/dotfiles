#!/usr/bin/env node
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const source = fs.readFileSync(path.join(__dirname, '../modules/Island.qml'), 'utf8');
const bar = source.slice(source.lastIndexOf('        Bar {'));
const handler = bar.match(/onPanelRequested: panel => \{([\s\S]*?)\n            \}/);
assert.ok(handler, 'Bar panel handler exists');
const click = new Function('win', 'panel', handler[1]);
const win = {
    view: '',
    dismiss() { this.view = ''; },
    panelRequested(panel) { this.view = panel; },
};

for (const panel of ['audio', 'calendar', 'capture']) {
    click(win, panel);
    assert.equal(win.view, panel, 'First click opens');
    click(win, panel);
    assert.equal(win.view, '', 'Second click closes');
}
win.view = 'audio';
click(win, 'calendar');
assert.equal(win.view, 'calendar', 'Different icon switches panel');
console.log('PASS bar panel toggle');
