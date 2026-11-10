const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const source = fs.readFileSync(path.join(__dirname, '../mods/vim-navigation/main.js'), 'utf8');
const calls = [];
let focus = { terminal: 't1', pane: 'p1' };
let program = 'fish';
let fail = false;
let changeFocus = false;
const sandbox = {
  View: class {},
  div: () => ({}),
  focused: () => focus,
  hc: async (args) => {
    calls.push(args);
    if (args[0] === 'get') {
      if (changeFocus) focus = { terminal: 't2', pane: 'p2' };
      return { code: 0, stdout: JSON.stringify({ foreground: { name: program } }), stderr: '' };
    }
    return { code: fail ? 1 : 0, stdout: '', stderr: fail ? 'send failed' : '' };
  },
  run: (command, args) => calls.push([command, args]),
  notify: (message) => calls.push(['notify', message]),
};
vm.createContext(sandbox);
vm.runInContext(source.replace(/^import .*;\n/gm, '').replace('export default class', 'globalThis.Navigation = class'), sandbox);
const navigation = new sandbox.Navigation();
async function check() {
  for (const [direction, key] of Object.entries({ left: 'h', down: 'j', up: 'k', right: 'l' })) {
    for (const name of ['fish', 'nvim', 'vim', 'view', 'vimdiff', 'NVIM', 'lazygit']) {
      calls.length = 0;
      program = name;
      await navigation.navigate(direction);
      assert.equal(calls[0][0], 'get');
      if (['fish', 'lazygit'].includes(name)) {
        assert.equal(calls[1][0], 'pane.go');
        assert.equal(calls[1][1].direction, direction);
      } else {
        assert.equal(calls[1].join(' '), `keys t1 ctrl+${key}`);
      }
    }
  }
  calls.length = 0;
  focus = null;
  await navigation.navigate('left');
  assert.equal(calls[0][0], 'pane.go');
  focus = { terminal: 't1', pane: 'p1' };
  program = 'nvim';
  changeFocus = true;
  calls.length = 0;
  await navigation.navigate('left');
  assert.equal(calls.length, 1);
  changeFocus = false;
  fail = true;
  calls.length = 0;
  await assert.rejects(navigation.navigate('left'), /send failed/);
  calls.length = 0;
  await navigation.navigate('invalid');
  assert.equal(calls.length, 0);
  const keys = JSON.parse(fs.readFileSync(path.join(__dirname, '../keys.json')));
  for (const direction of ['left', 'down', 'up', 'right']) {
    assert(Object.values(keys.global).includes(`vim-navigation.${direction}`));
  }
  assert.equal(keys.terminal['ctrl-shift-v'], 'terminal.paste');
  for (const name of ['matugen', 'matugen-herdr']) {
    const layout = JSON.parse(fs.readFileSync(path.join(__dirname, `../layouts/${name}.json`)));
    assert(layout.floating.some((block) => block.content.mod === 'vim-navigation'));
  }
  fs.writeFileSync('/tmp/herdr-navigation-check.json', JSON.stringify({ desktop: 'passed', directions: 4, focusRace: 'passed', failedSend: 'passed' }, null, 2) + '\n');
  console.info('PASS Desktop navigation, key forwarding, focus race, errors, bindings, and layouts');
}
check().catch((error) => { console.error(error); process.exitCode = 1; });
