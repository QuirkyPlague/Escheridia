#ifndef FOG
#define FOG
#include "/lib/atmosphere/sky.glsl"
#include "/lib/shadows/distort.glsl"
#include "/lib/shadows/drawShadows.glsl"

vec3 borderFog(vec3 color, vec3 dir, float depth) {
    vec3 fogColor = skyScattering(normalize(dir));
    float dist = length(dir) / far;
    float fogFactor = exp(-8.0 * (1.0 - dist));
    float rainFogFactor = exp(-7.37 * (1.0 - dist));
    fogFactor = mix(fogFactor, rainFogFactor, wetness);
    return mix(color, fogColor, clamp(fogFactor, 0.0, 1.0));
}

vec3 atmosphericFog(vec3 color, vec3 viewPos, float depth, vec2 uv, bool isWater) {
    vec3 sunColor = vec3(0.0);

    vec3 absorption = vec3(0.9373, 0.9373, 0.9373);
    vec3 inscatteringAmount = computeSkyColoring(viewPos) * 3.43;
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    vec3 worldPos = feetPlayerPos + cameraPosition;
    float worldHeight = smoothstep(214, 0, worldPos.y);
    float fogSmoothReduction = smoothstep(1.0,0.38,worldHeight);
    float scatterReduce = smoothstep(0, 185, eyeBrightnessSmooth.y);
    inscatteringAmount = pow(inscatteringAmount, vec3(2.2));
    inscatteringAmount *= scatterReduce;
    absorption = pow(absorption, vec3(2.2));
    vec3 noiseOffset = vec3(0.12,0.0,0.73) * frameTimeCounter * 0.003;
    float noise = texture(fogTex,mod((worldPos.xz) * noiseOffset.x , 1024.0) / 1024.0).r;

    float dist = length(viewPos) / far * (noise * 3);
    vec3 viewDir = normalize(viewPos);
    float smoothDepth = smoothstep(0.998, 1.0, depth);
    float VdotL = dot(viewDir, lightVector);
    float phase = CS(0.65, VdotL);
    float backPhase = CS(-0.15, VdotL);
    sunColor = currentSunColor(sunColor) * 12;
    float noiseDistributionFactor = smoothstep(1.0, 0.95, noise);
    vec3 absorptionFactor = exp(
        -absorption * (dist *0.313));

    float fogDistFalloff = length(feetPlayerPos) / far;
    float fogReduction = exp(0.5 * (-2.0 - fogDistFalloff));

    vec3 phaseLighting = sunColor  * phase  * scatterReduce * smoothDepth;
    phaseLighting *= fogReduction;
    vec3 scattering = inscatteringAmount * backPhase * worldHeight;
    vec3 totalScattering = (scattering + phaseLighting) * ENVIORNMENT_FOG_DENSITY;
    color.rgb *= absorptionFactor ;
    color.rgb += (totalScattering / absorption) * (1.0 - absorptionFactor) ;

    return color.rgb;
}


float getCloudDensity(vec3 pos) {
    const float TOTAL_DENSITY = 0.14;
    float density = 0.00;
    float weight = 0.0;

    pos = pos / 100000;

    for (int i = 0; i < VL_ATMOSPHERIC_STEPS; i++) {
        float sampleWeight = exp2(-float(i));
        pos.xz += frameTimeCounter * 0.000045 * sqrt(i + 1);
        vec2 samplePos = sin(pos.zx * exp2(float(i)));

        float noise = texture(fogTex, fract(samplePos)).r * sampleWeight;
        float noiseDot = dot(noise, noise) ;
        density =  max(0, noise - 0.04) * 1.0;

        weight += sampleWeight ;
    }
    density /= weight;

    density *= TOTAL_DENSITY;
    density = mix(density, density * 4, wetness);

    return density;
}


#endif //FOG
