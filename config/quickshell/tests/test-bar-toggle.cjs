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
const width = source.match(/        width: (Math\.min\(win\.width - 32,.*)\n/);
assert.ok(width, 'Detached panel width binding exists');
const panelWidth = new Function('win', 'Config', `return ${width[1]};`);
const config = { launcherWidth: 680, centerWidth: 420, osdWidth: 200 };
for (const [view, expected] of [['controls', 420], ['notifications', 420], ['launcher', 680], ['audio', 440], ['volume', 200]]) {
    const state = { width: 1920, view, centeredSearch: view === 'launcher', activePanel: { implicitWidth: 380 } };
    assert.equal(panelWidth(state, config), expected);
    state.width = 360;
    assert.equal(panelWidth(state, config), Math.min(328, expected));
}
console.log('PASS bar panel toggle and detached panel width');
