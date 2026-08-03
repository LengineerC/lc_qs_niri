#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float transitionKind;
    float aspectRatio;
    float direction;
    float stripeCount;
    float stripeAngle;
    vec2 centerPoint;
} ubuf;

layout(binding = 1) uniform sampler2D source1;
layout(binding = 2) uniform sampler2D source2;

const float PI = 3.14159265359;

vec2 rotatePoint(vec2 point, float angle) {
    float sine = sin(angle);
    float cosine = cos(angle);
    return mat2(cosine, -sine, sine, cosine) * point;
}

vec4 sampleImage(sampler2D image, vec2 uv) {
    return texture(image, clamp(uv, vec2(0.001), vec2(0.999)));
}

float radialDistance(vec2 uv) {
    vec2 delta = uv - ubuf.centerPoint;
    delta.x *= ubuf.aspectRatio;
    return length(delta);
}

float maximumRadius() {
    float horizontal = max(ubuf.centerPoint.x, 1.0 - ubuf.centerPoint.x)
        * ubuf.aspectRatio;
    float vertical = max(ubuf.centerPoint.y, 1.0 - ubuf.centerPoint.y);
    return length(vec2(horizontal, vertical));
}

void main() {
    vec2 uv = qt_TexCoord0;
    float progress = clamp(ubuf.progress, 0.0, 1.0);
    int kind = int(ubuf.transitionKind + 0.5);
    vec4 previousColor;
    vec4 nextColor;
    float mask = progress;

    if (kind == 5) {
        float peak = sin(progress * PI);
        float blockSize = mix(1.0 / 900.0, 1.0 / 28.0, peak);
        vec2 pixelUv = (floor(uv / blockSize) + 0.5) * blockSize;
        previousColor = sampleImage(source1, pixelUv);
        nextColor = sampleImage(source2, pixelUv);
        mask = smoothstep(0.32, 0.68, progress);
    } else if (kind == 6) {
        vec2 centered = uv - ubuf.centerPoint;
        float pulse = sin(progress * PI);
        vec2 previousUv = ubuf.centerPoint
            + rotatePoint(centered * (1.0 + 0.18 * progress),
                pulse * 0.45);
        vec2 nextUv = ubuf.centerPoint
            + rotatePoint(centered * (1.24 - 0.24 * progress),
                -pulse * 0.55);
        previousColor = sampleImage(source1, previousUv);
        nextColor = sampleImage(source2, nextUv);
        float radius = progress * maximumRadius();
        float edge = 0.035 + pulse * 0.025;
        mask = 1.0 - smoothstep(radius - edge, radius + edge,
            radialDistance(uv));
    } else {
        previousColor = sampleImage(source1, uv);
        nextColor = sampleImage(source2, uv);

        if (kind == 1) {
            int direction = int(ubuf.direction + 0.5) % 4;
            float coordinate = direction == 0 ? uv.x
                : direction == 1 ? 1.0 - uv.x
                : direction == 2 ? uv.y : 1.0 - uv.y;
            mask = 1.0 - smoothstep(progress - 0.035,
                progress + 0.035, coordinate);
        } else if (kind == 2) {
            float radius = progress * maximumRadius();
            mask = 1.0 - smoothstep(radius - 0.025, radius + 0.025,
                radialDistance(uv));
        } else if (kind == 3) {
            float angle = ubuf.stripeAngle * PI / 180.0;
            vec2 stripeUv = rotatePoint(uv - vec2(0.5), angle)
                + vec2(0.5);
            float stripe = floor(stripeUv.y * max(4.0, ubuf.stripeCount));
            float delay = fract(stripe * 0.61803398875) * 0.34;
            float localProgress = clamp((progress - delay) / 0.66, 0.0, 1.0);
            mask = 1.0 - smoothstep(localProgress - 0.025,
                localProgress + 0.025, stripeUv.x);
        } else if (kind == 4) {
            vec2 delta = uv - ubuf.centerPoint;
            delta.x *= ubuf.aspectRatio;
            float angle = atan(delta.y, delta.x);
            float petals = 1.0 + sin(angle * 8.0) * 0.085
                * sin(progress * PI);
            float radius = progress * maximumRadius() * petals;
            mask = 1.0 - smoothstep(radius - 0.035, radius + 0.035,
                length(delta));
        }
    }

    fragColor = mix(previousColor, nextColor, clamp(mask, 0.0, 1.0))
        * ubuf.qt_Opacity;
}
