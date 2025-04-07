#ifndef WATER_GLSL
#define WATER_GLSL

const float waveHeight = 0.2;
const float waveSpeed = 0.05;

vec2 hash(vec2 p) {
    float h1 = sin(dot(p, vec2(127.1, 311.7)));
    float h2 = sin(dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(vec2(h1, h2) * 43758.5453123);
}

float fade(float t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float perlinNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    vec2 u = vec2(fade(f.x), fade(f.y));
    
    vec2 g00 = hash(i + vec2(0.0, 0.0));
    vec2 g10 = hash(i + vec2(1.0, 0.0));
    vec2 g01 = hash(i + vec2(0.0, 1.0));
    vec2 g11 = hash(i + vec2(1.0, 1.0));

    float n00 = dot(g00, f - vec2(0.0, 0.0));
    float n10 = dot(g10, f - vec2(1.0, 0.0));
    float n01 = dot(g01, f - vec2(0.0, 1.0));
    float n11 = dot(g11, f - vec2(1.0, 1.0));

    return mix(mix(n00, n10, u.x), mix(n01, n11, u.x), u.y);
}

float fbm(vec2 p) {
    float total = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < 4; i++) {
        total += amplitude * perlinNoise(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    return total;
}

float vsh_getWaveHeight(vec3 pos) {
    float time = float(frameCounter) * waveSpeed;

    vec2 timeOffset = vec2(time * 0.05);

    float noiseValue = fbm(pos.xz * 0.1 + timeOffset) * waveHeight;

    return noiseValue;
}
#endif