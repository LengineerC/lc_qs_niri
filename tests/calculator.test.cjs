// Run with: node tests/calculator.test.cjs
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const context = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname,
    '../modules/launcher/Calculator.js'), 'utf8')
    .replace(/^\.pragma library\s*/, ''), context);

const cases = [
    ['1+2*3', '7'], ['(1+2)*3', '9'], ['0.1+0.2', '0.3'],
    ['200*15%', '30'], ['2^3^2', '512'], ['-2^2', '-4'],
    ['(-2)^2', '4'], ['2^-2', '0.25'], ['2**3', '8'],
    ['12 × 3 ÷ 2 =', '18'], ['5−8', '-3'], ['.5 + .25', '0.75'],
    ['1e3 / 4', '250'], ['1--2', '3'], ['1-1', '0'],
    ['1/0', null], ['0/0', null], ['2^1024', null],
    ['1+', null], ['(1+2', null], ['1+2)', null], ['1..2+3', null],
    ['1 2+3', null], ['2(3)', null], ['', null], ['123', null],
    ['firefox', null], ['7zip', null], ['org.app-2', null],
    ['Math.random()', null], ['1;process.exit()', null],
    ['('.repeat(257), null]
];
for (const [input, expected] of cases)
    assert.equal(context.calculate(input), expected, input);
console.log(`${cases.length} calculator tests passed`);
