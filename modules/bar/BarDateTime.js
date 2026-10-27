.pragma library

// Split Qt date/time formats into fields, keeping quoted literals with their
// field. Only unquoted separators become line breaks. Preserve field order.
function fieldFormats(format, date) {
    const text = String(format || "");
    const fields = [];
    let prefix = "";
    const tokens = date ? /^(yyyy|yy|MMMM|MMM|MM|M|dddd|ddd|dd|d)/
        : /^(HH|H|hh|h|mm|m|ss|s|zzz|z|AP|ap|A|a|tttt|ttt|tt|t)/;
    for (let index = 0; index < text.length;) {
        if (text[index] === "'") {
            const start = index++;
            while (index < text.length) {
                if (text[index++] !== "'")
                    continue;
                if (text[index] === "'") { index++; continue; }
                break;
            }
            const literal = text.slice(start, index);
            if (fields.length) fields[fields.length - 1] += literal;
            else prefix += literal;
            continue;
        }
        const match = text.slice(index).match(tokens);
        if (match) {
            let token = match[0];
            index += token.length;
            if (date && token === "MMMM") token = "MMM";
            if (date && token === "dddd") token = "ddd";
            fields.push(prefix + token);
            prefix = "";
        } else {
            const character = text[index++];
            if (/[\s:.,/\\\-–—|]/.test(character)) continue;
            if (fields.length) fields[fields.length - 1] += character;
            else prefix += character;
        }
    }
    if (prefix) fields.push(prefix);
    return fields;
}
