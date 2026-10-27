// Run with: node tests/bar-geometry.test.cjs
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const context = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname, '../modules/bar/BarGeometry.js'), 'utf8')
    .replace(/^\.pragma library\s*/, ''), context);
let cases = 0;
for (const edge of ['top', 'bottom', 'left', 'right']) {
    for (const [sw, sh] of [[1920, 1080], [800, 600], [400, 300]]) {
        for (const [cx, cy] of [[0, 0], [sw / 2, sh / 2], [sw, sh]]) {
            for (const progress of [0, 0.5, 1]) {
                const r = context.popupRect(edge, sw, sh, 40, 850, 650, cx, cy, progress);
                assert.ok(r.x >= 0 && r.y >= 0);
                assert.ok(r.x + r.width <= sw && r.y + r.height <= sh);
                if (edge === 'top') assert.equal(r.y, 40);
                if (edge === 'bottom') assert.equal(r.y + r.height, sh - 40);
                if (edge === 'left') assert.equal(r.x, 40);
                if (edge === 'right') assert.equal(r.x + r.width, sw - 40);
                if (edge === 'left' || edge === 'right')
                    assert.equal(r.width, r.fullWidth * progress);
                else
                    assert.equal(r.height, r.fullHeight * progress);
                const bridge = context.blobPopupRect(edge, r.x, r.y, r.width, r.height, 8);
                // The outer panel edge stays fixed; only the edge adjoining
                // the bar overlaps it, including during reveal/close.
                if (edge === 'top') {
                    assert.equal(bridge.y, 32);
                    assert.equal(bridge.y + bridge.height, r.y + r.height);
                } else if (edge === 'bottom') {
                    assert.equal(bridge.y, r.y);
                    assert.equal(bridge.y + bridge.height, sh - 32);
                } else if (edge === 'left') {
                    assert.equal(bridge.x, 32);
                    assert.equal(bridge.x + bridge.width, r.x + r.width);
                } else {
                    assert.equal(bridge.x, r.x);
                    assert.equal(bridge.x + bridge.width, sw - 32);
                }
                cases++;
            }
        }
    }
}
// Exercise the real settings save/load functions without file IO.
const settings = fs.readFileSync(path.join(__dirname, '../common/ShellSettings.qml'), 'utf8');
const savedFields = [...settings.slice(settings.indexOf('    function save()'),
    settings.indexOf('    function applySavedSettings(')).matchAll(/^            \w+: (\w+),?$/gm)]
    .map(match => match[1]).filter(value => value !== '29');
const state = {console: {warn(message, error) { throw error; }}, Font: {Normal: 400}, storageReady: true, applyingState: false,
    Qt: {callLater() {}}, saveTimer: {restart() {}}, root: {save() {}}};
for (const field of savedFields) state[field] = undefined;
state.settingsStorage = {setText(text) { state.saved = JSON.parse(text); }};
const settingsContext = vm.createContext(state);
vm.runInContext(settings.slice(settings.indexOf('    function stripFileProtocol('),
    settings.indexOf('    function load()')), settingsContext);
for (const edge of ['top', 'bottom', 'left', 'right']) {
    settingsContext.resetDefaults();
    settingsContext.barPosition = edge;
    settingsContext.save();
    assert.equal(settingsContext.saved.barPosition, edge);
    settingsContext.barPosition = 'top';
    settingsContext.applySavedSettings(JSON.stringify(settingsContext.saved));
    assert.equal(settingsContext.barPosition, edge);
}
settingsContext.resetDefaults();
settingsContext.applySavedSettings('{}');
assert.equal(settingsContext.barPosition, 'top');
settingsContext.applySavedSettings('{"barPosition":"invalid"}');
assert.equal(settingsContext.barPosition, 'top');
assert.match(settings, /onBarPositionChanged: scheduleSave\(\)/);
console.log(`${cases} popup geometry cases and bar position persistence tests passed`);
