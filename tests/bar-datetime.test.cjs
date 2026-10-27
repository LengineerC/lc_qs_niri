// Run with: node tests/bar-datetime.test.cjs
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const context = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname, '../modules/bar/BarDateTime.js'), 'utf8')
    .replace(/^\.pragma library\s*/, ''), context);
const cases = [
    ['HH:mm', false, ['HH', 'mm']],
    ['HH:mm:ss', false, ['HH', 'mm', 'ss']],
    ['h:mm AP', false, ['h', 'mm', 'AP']],
    ["hh'时'mm'分'", false, ["hh'时'", "mm'分'"]],
    ["HH 'o''clock' mm", false, ["HH'o''clock'", 'mm']],
    ['ss:mm:HH', false, ['ss', 'mm', 'HH']],
    ['HH:mm:ss.zzz ttt', false, ['HH', 'mm', 'ss', 'zzz', 'ttt']],
    ['MMM dd ddd', true, ['MMM', 'dd', 'ddd']],
    ['dddd, MMMM d yyyy', true, ['ddd', 'MMM', 'd', 'yyyy']],
    ['dd/MM/yyyy', true, ['dd', 'MM', 'yyyy']],
    ['yyyy年MM月dd日', true, ['yyyy年', 'MM月', 'dd日']],
    ["yyyy 'year' MMMM dd", true, ["yyyy'year'", 'MMM', 'dd']],
    ['', false, []]
];
for (const [format, date, expected] of cases)
    assert.deepEqual(Array.from(context.fieldFormats(format, date)), expected, format);
console.log(`${cases.length} configurable vertical date/time format cases passed`);
