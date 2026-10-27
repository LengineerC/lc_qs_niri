.pragma library

function isVertical(edge) {
    return edge === "left" || edge === "right";
}

function popupRect(edge, screenWidth, screenHeight, thickness, width, height,
                   centerX, centerY, progress) {
    const vertical = isVertical(edge);
    const fullWidth = Math.max(1, Math.min(width, screenWidth - (vertical ? thickness : 0)));
    const fullHeight = Math.max(1, Math.min(height, screenHeight - (vertical ? 0 : thickness)));
    const shownWidth = vertical ? fullWidth * progress : fullWidth;
    const shownHeight = vertical ? fullHeight : fullHeight * progress;
    const x = edge === "left" ? thickness : edge === "right"
        ? screenWidth - thickness - shownWidth
        : Math.max(0, Math.min(screenWidth - fullWidth, centerX - fullWidth / 2));
    const y = edge === "top" ? thickness : edge === "bottom"
        ? screenHeight - thickness - shownHeight
        : Math.max(0, Math.min(screenHeight - fullHeight, centerY - fullHeight / 2));
    return {x: x, y: y, width: shownWidth, height: shownHeight,
        fullWidth: fullWidth, fullHeight: fullHeight};
}

// Extend into the bar, in screen coordinates, to keep the metaball bridge
// identical for every edge. Content and background use the same deform axes.
function blobPopupRect(edge, x, y, width, height, overlap) {
    return {
        x: x - (edge === 'left' ? overlap : 0),
        y: y - (edge === 'top' ? overlap : 0),
        width: width + (isVertical(edge) ? overlap : 0),
        height: height + (isVertical(edge) ? 0 : overlap)
    };
}
