#ifdef PUDDLE_GLSL
#define PUDDLE_GLSL

// Returns a puddle mask and wet albedo modifier
struct PuddleData {
    float mask;   // puddle coverage 0–1
    vec3 color;   // modified surface color
};

PuddleData getPuddle(vec2 uv, vec3 baseColor)
{
    // sample the noise map for puddle distribution
    float noiseVal = texture(puddleTex, uv * 2.0).r;

    // blend based on wetness — higher wetness means more puddles appear
    float puddleMask = smoothstep(1.0 - wetness * 1.2, 1.0, noiseVal);

    // darken the albedo slightly where puddles form
    vec3 darkened = mix(baseColor, baseColor * 0.4, puddleMask);

    // add a little reflectivity/brightness to puddles
    vec3 specBoost = mix(vec3(0.0), vec3(0.3, 0.35, 0.4), puddleMask);

    return PuddleData(puddleMask, darkened + specBoost);
}
#endif