.pragma library

// Recursive descent parser: never evaluate user input as JavaScript.
// Percent is postfix (20% = 0.2); powers are right associative.
function calculate(input) {
    var source = input.trim().replace(/×/g, "*").replace(/[÷]/g, "/")
        .replace(/[−–]/g, "-").replace(/\*\*/g, "^").replace(/=\s*$/, "");
    if (!source || source.length > 256 || !/[+*/^%()-]/.test(source)
            || /[^\d\s.eE+*/^%()-]/.test(source))
        return null;
    var position = 0;
    function skip() {
        while (/\s/.test(source.charAt(position)) && position < source.length)
            position++;
    }
    function take(token) {
        skip();
        if (source.charAt(position) !== token)
            return false;
        position++;
        return true;
    }
    function primary() {
        var value;
        if (take("(")) {
            value = sum();
            if (!take(")")) throw new Error("Missing parenthesis");
        } else {
            skip();
            var match = /^(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?/.exec(source.slice(position));
            if (!match) throw new Error("Expected number");
            position += match[0].length;
            value = Number(match[0]);
        }
        while (take("%")) value /= 100;
        return value;
    }
    function power() {
        var value = primary();
        return take("^") ? Math.pow(value, unary()) : value;
    }
    function unary() {
        if (take("+")) return unary();
        if (take("-")) return -unary();
        return power();
    }
    function product() {
        var value = unary();
        while (true) {
            if (take("*")) value *= unary();
            else if (take("/")) value /= unary();
            else return value;
        }
    }
    function sum() {
        var value = product();
        while (true) {
            if (take("+")) value += product();
            else if (take("-")) value -= product();
            else return value;
        }
    }
    try {
        var result = sum();
        skip();
        if (position !== source.length || !isFinite(result)) return null;
        // Hide floating point noise such as 0.1 + 0.2 = 0.30000000000000004.
        return String(Number(result.toPrecision(15)));
    } catch (error) {
        // Incomplete expressions are normal while typing.
        return null;
    }
}
