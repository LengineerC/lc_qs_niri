.pragma library
// Adapted from Nyxuri Orbit (GPL-3.0), physics.py and window.py.
function spring(value, omega, zeta) {
    return {current: value, target: value, velocity: 0, omega: omega, zeta: zeta};
}
function update(s, dt) {
    dt = Math.min(0.05, Math.max(0.001, dt));
    const force = -s.omega * s.omega * (s.current - s.target) - 2 * s.zeta * s.omega * s.velocity;
    s.velocity += force * dt;
    s.current += s.velocity * dt;
    if (Math.abs(s.current - s.target) > 0.001 || Math.abs(s.velocity) > 0.001)
        return true;
    s.current = s.target;
    s.velocity = 0;
    return false;
}
function angle(index, count) { return -Math.PI / 2 + index * 2 * Math.PI / count; }
function sector(dx, dy, count, previous) {
    if (!count || Math.hypot(dx, dy) < 48) return -1;
    const theta = Math.atan2(dy, dx);
    let best = -1, distance = Infinity;
    for (let i = 0; i < count; ++i) {
        let diff = Math.abs(Math.atan2(Math.sin(theta - angle(i, count)), Math.cos(theta - angle(i, count))));
        if (i === previous) diff -= Math.PI / 30; // Original 6-degree hysteresis.
        if (diff < distance) { best = i; distance = diff; }
    }
    return best;
}
function validate(items, depth) {
    depth = depth || 0;
    if (!Array.isArray(items) || (!items.length && depth === 0) || items.length > 8 || depth > 5)
        throw new Error('Each orbit must have 1–8 items, with at most 6 levels');
    return items.map(item => {
        if (!item || typeof item.name !== 'string' || !item.name.trim())
            throw new Error('Each item needs a name');
        if (item.children) validate(item.children, depth + 1);
        else if (item.command) {
            if (!Array.isArray(item.command) || !item.command.length || !item.command.every(x => typeof x === 'string'))
                throw new Error('command must be a nonempty argument array');
        } else if (item.shell !== undefined) {
            if (typeof item.shell !== 'string' || !item.shell.trim() || item.shell.includes('\0'))
                throw new Error('Shell command cannot be blank or contain NUL');
        } else if (item.url !== undefined) {
            if (typeof item.url !== 'string' || !/^https?:\/\/[^\s/?#]+(?:[/?#][^\s]*)?$/.test(item.url))
                throw new Error('Enter a complete HTTP(S) URL without spaces');
        } else if (!['terminal', 'settings', 'desktop', 'wallpaperNext', 'wallpaperRandom', 'lock'].includes(item.action))
            throw new Error('Unknown action');
        return item;
    });
}

function migrate(document) {
    const result = JSON.parse(JSON.stringify(document));
    if ((result.schemaVersion || 1) >= 2) return result;
    if (Array.isArray(result.items)) {
        for (const item of result.items) {
            if (!Array.isArray(item.children)) continue;
            if (item.id === 'tools' || item.name === 'System Tools') {
                item.id = 'tools';
                item.children = item.children.filter(child => child.action !== 'lock');
            } else if (item.id === 'wallpapers' || item.name === 'Wallpapers') {
                item.id = 'wallpapers';
                item.children = item.children.filter(child => child.action !== 'settings');
            } else if (item.id === 'websites' || item.name === 'Websites') {
                item.id = 'websites';
            }
        }
    }
    result.schemaVersion = 2;
    return result;
}
