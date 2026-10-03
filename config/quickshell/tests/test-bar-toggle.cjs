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
const width = source.match(/        width: (Math\.min\(win\.width - 24,.*)\n/);
assert.ok(width, 'Island width binding exists');
const islandWidth = new Function('win', 'bar', 'Config', `return ${width[1]};`);
for (const view of ['', 'controls', 'notifications', 'launcher', 'audio']) {
    const state = { width: 1920, view, activePanel: { implicitWidth: 380 } };
    assert.equal(islandWidth(state, { implicitWidth: 720 }, { launcherWidth: 680 }),
        view === 'controls' || view === 'notifications' ? 400 : 720);
    state.width = 360;
    assert.equal(islandWidth(state, { implicitWidth: 720 }, { launcherWidth: 680 }), 336);
}
console.log('PASS bar panel toggle and width');
