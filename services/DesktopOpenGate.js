.pragma library

function createState() {
    return { inFlight: {}, completed: {} };
}

function tryAcquire(state, key, now, cooldownMs) {
    if (!key || state.inFlight[key])
        return false;
    const completedAt = state.completed[key] || 0;
    if (completedAt && now - completedAt < cooldownMs)
        return false;
    state.inFlight[key] = true;
    return true;
}

function release(state, key, now) {
    delete state.inFlight[key];
    state.completed[key] = now;
}
