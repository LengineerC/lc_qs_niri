// Run with: node tests/tray-settings.test.cjs
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, '../common/ShellSettings.qml'), 'utf8');
const context = vm.createContext({
    SystemTray: {items: {values: []}},
    pinnedTrayItemIds: [], trayItemOrderKeys: []
});
vm.runInContext(source.slice(source.indexOf('    function sanitizedTrayItemIds('),
    source.indexOf('    function scheduleSave(')), context);
const qq = {id: 'electron', title: 'QQ'};
const baidu = {id: 'electron', title: '百度网盘'};
context.SystemTray.items.values = [qq, baidu];
context.setTrayItemPinned(qq, true);
assert.equal(context.trayItemPinned(qq), true);
assert.equal(context.trayItemPinned(baidu), false);
context.setTrayItemPinned(baidu, true);
context.setTrayItemPinned(qq, false);
assert.equal(context.trayItemPinned(baidu), true);
context.setTrayItemOrder([baidu, qq]);
assert.deepEqual(Array.from(context.orderedTrayItems([qq, baidu])), [baidu, qq]);
context.moveTrayItem([qq, baidu], 0, 1);
assert.deepEqual(Array.from(context.orderedTrayItems([qq, baidu])), [qq, baidu]);
context.pinnedTrayItemIds = ['id:electron'];
assert.equal(context.trayItemPinned(qq), false);
assert.equal(context.trayItemPinned(baidu), false);
context.reconcileTrayItems([qq, baidu]);
assert.equal(context.pinnedTrayItemIds.length, 0);
context.pinnedTrayItemIds = ['title:QQ'];
context.reconcileTrayItems([qq, baidu]);
assert.equal(context.pinnedTrayItemIds[0], context.trayItemKey(qq));
assert.equal(context.trayItemPinned(baidu), false);
const other = {id: 'different-app', title: 'QQ'};
context.SystemTray.items.values = [qq, other];
context.pinnedTrayItemIds = [context.trayItemKey(qq)];
assert.equal(context.trayItemPinned(other), false);
context.pinnedTrayItemIds = ['title:QQ'];
context.reconcileTrayItems([qq, other]);
assert.equal(context.pinnedTrayItemIds.length, 0);
console.log('Tray identity, independent pinning/order, and legacy migration tests passed');
