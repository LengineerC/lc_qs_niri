const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const context = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname, '../modules/orbit/OrbitMath.js'), 'utf8').replace(/^\.pragma library\s*/, ''), context);
const {spring, update, sector, validate} = context;
for (let count = 1; count <= 8; ++count) {
    assert.equal(sector(0, 0, count, 0), -1);
    for (let i = 0; i < count; ++i) {
        const angle = -Math.PI / 2 + i * 2 * Math.PI / count;
        assert.equal(sector(180 * Math.cos(angle), 180 * Math.sin(angle), count, -1), i);
    }
}
assert.equal(sector(100 * Math.cos(-44 * Math.PI / 180), 100 * Math.sin(-44 * Math.PI / 180), 4, 0), 0);
assert.equal(sector(100 * Math.cos(-35 * Math.PI / 180), 100 * Math.sin(-35 * Math.PI / 180), 4, 0), 1);
for (const hz of [60, 120, 144]) {
    const s = spring(0, 14, .7); s.target = 1;
    for (let i = 0; i < hz * 4; ++i) update(s, 1 / hz);
    assert.equal(s.current, 1);
    assert.equal(s.velocity, 0);
}
validate([{name: 'Tools', children: [{name: 'Settings', action: 'settings'}]}]);
assert.throws(() => validate([{name: 'Bad', command: 'rm -rf /'}]));
assert.throws(() => validate([{name: 'Bad', url: 'file:///tmp/test'}]));
assert.throws(() => validate([]));
console.log('Orbit sectors, hysteresis, springs and configuration validation passed');

validate([{name: 'Empty websites', children: []}]);
validate([{name: 'Shell', shell: 'printf hello | cat'}]);
assert.throws(() => validate([{name: 'Bad', shell: '   '}]));
assert.throws(() => validate([{name: 'Bad', shell: 'echo\0bad'}]));
assert.throws(() => validate([{name: 'Bad URL', url: 'https://'}]));
assert.throws(() => validate([{name: 'Bad URL', url: 'https://a b/'}]));
const oldConfig = {other: 'keep', items: [
    {name: 'System Tools', children: [{name: 'Lock', action: 'lock'}, {name: 'Mine', command: ['true']}]},
    {name: 'Wallpapers', children: [{name: 'Settings', action: 'settings'}, {name: 'Next', action: 'wallpaperNext'}]},
    {name: 'Websites', children: [{name: 'Mine', url: 'https://example.com'}]}
]};
const migrated = context.migrate(oldConfig);
assert.equal(migrated.schemaVersion, 2);
assert.equal(migrated.other, 'keep');
assert.equal(migrated.items[0].children.length, 1);
assert.equal(migrated.items[0].children[0].name, 'Mine');
assert.equal(migrated.items[1].children.length, 1);
assert.equal(migrated.items[2].id, 'websites');
assert.equal(JSON.stringify(context.migrate(migrated)), JSON.stringify(migrated));
assert.equal(oldConfig.items[0].children.length, 2);
console.log('Orbit shell/URL validation and non-destructive config migration passed');
