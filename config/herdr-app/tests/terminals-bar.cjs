const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const root = path.join(__dirname, '..');
const layout = JSON.parse(fs.readFileSync(path.join(root, 'layouts/matugen.json')));
assert.equal(layout.children[0].content.mod, 'matugen-terminals-bar');
const source = fs.readFileSync(path.join(root, 'mods/matugen-terminals-bar/main.js'), 'utf8');

function render(palette, activeSpace, windowState) {
  const nodes = [];
  const calls = [];
  function element() {
    const node = { styles: {}, actions: {}, childNodes: [] };
    const proxy = new Proxy(node, {
      get(target, key) {
        if (key in target) return target[key];
        return (...args) => {
          if (key === 'id') target.id = args[0];
          else if (key === 'child') target.childNodes.push(args[0]);
          else if (key === 'children') target.childNodes.push(...args[0]);
          else if (key === 'when' && args[0]) args[1](proxy);
          else if (key === 'hover') {
            const hover = new Proxy({}, { get: (_target, property) => (...values) => { target.styles[`hover.${property}`] = values[0]; return hover; } });
            args[0](hover);
          }
          else if (key === 'on_click') target.actions.click = args[0];
          else if (['bg', 'border_color', 'text_color'].includes(key)) target.styles[key] = args[0];
          return proxy;
        };
      },
    });
    nodes.push(node);
    return proxy;
  }
  const sandbox = {
    View: class {}, div: element, h_flex: element, svg: element, image: element,
    theme: () => palette,
    spaces: () => activeSpace ? [{ active: true, id: 'space', name: 'home', tabs: [{ id: 'a', name: '1', active: true }, { id: 'b', name: '2', active: false }] }] : [],
    panes: () => [{ tab: 'a', focused: true, cwd: '/home/user', program: { icon: 'terminal', tint: true, color: '#program', tile: '#tile' } }, { tab: 'b' }],
    home: () => '/home/user', win: () => windowState,
    run: (...args) => calls.push(args), openOverlay: (...args) => calls.push(['overlay', ...args]),
  };
  vm.createContext(sandbox);
  vm.runInContext(source.replace(/^import .*;\n/gm, '').replace('export default class', 'globalThis.TerminalsBar = class'), sandbox);
  new sandbox.TerminalsBar().render();
  return { nodes, calls };
}

for (const suffix of ['one', 'two']) {
  const theme = Object.fromEntries(['chrome', 'surface', 'raised', 'hover', 'border', 'foreground', 'muted', 'dim'].map((key) => [key, `${key}-${suffix}`]));
  const { nodes, calls } = render(theme, true, { buttons: true });
  const byId = (id) => nodes.find((node) => node.id === id);
  assert.equal(byId('tm-a').styles.bg, theme.raised);
  assert.equal(byId('tm-a').styles.border_color, theme.border);
  assert.equal(byId('tm-b').styles['hover.bg'], theme.hover);
  assert.equal(byId('tm-space').styles.bg, theme.surface);
  assert.equal(byId('tm-min').styles.bg, theme.surface);
  assert.equal(byId('tm-new').styles.text_color, theme.dim);
  assert(nodes.some((node) => node.styles.bg === theme.chrome));
  assert(nodes.some((node) => node.styles.text_color === theme.foreground));
  assert(nodes.some((node) => node.styles.text_color === theme.muted));
  assert(nodes.some((node) => node.styles.bg === '#tile'));
  byId('tm-b').actions.click();
  byId('tm-new').actions.click();
  byId('tm-min').actions.click();
  assert.deepEqual(calls.map((call) => call[0]), ['tab.select', 'tab.new', 'window.minimize']);
}
assert.equal(render({}, false, {}).nodes.length, 1);
fs.writeFileSync('/tmp/herdr-terminals-bar-check.json', JSON.stringify({ palettes: 2, activeAndInactiveTabs: 'passed', missingProgram: 'passed', emptySpace: 'passed', actions: 'passed' }, null, 2) + '\n');
console.info('PASS terminal bar palette and actions; /tmp/herdr-terminals-bar-check.json');
