const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

const context = vm.createContext({});
vm.runInContext(
    fs.readFileSync(path.join(__dirname, '../services/DesktopOpenGate.js'), 'utf8')
        .replace(/^\.pragma library\s*/, ''),
    context,
);

const state = context.createState();
const cooldown = 1200;
const a = 'file:///state/desktop/a.desktop';
const b = 'file:///state/desktop/b.txt';

assert.equal(context.tryAcquire(state, a, 1000, cooldown), true);
assert.equal(context.tryAcquire(state, a, 1001, cooldown), false,
    'active and queued opens for the same item must stay collapsed');
assert.equal(context.tryAcquire(state, b, 1002, cooldown), true,
    'different desktop items must not block one another');

context.release(state, a, 2000);
assert.equal(context.tryAcquire(state, a, 2100, cooldown), false,
    'double-click remnants must not launch during the cooldown');
assert.equal(context.tryAcquire(state, a, 3199, cooldown), false);
assert.equal(context.tryAcquire(state, a, 3200, cooldown), true,
    'an intentional later open must still work');

context.release(state, b, 2200);
context.release(state, a, 3300);
assert.equal(context.tryAcquire(state, a, 4500, cooldown), true);

console.log('PASS: in-flight deduplication, request cooldown and independent items');
