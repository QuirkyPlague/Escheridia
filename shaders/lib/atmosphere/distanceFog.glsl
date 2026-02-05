#ifndef FOG
#define FOG
#include "/lib/atmosphere/sky.glsl"
#include "/lib/shadows/distort.glsl"
#include "/lib/shadows/drawShadows.glsl"

vec3 borderFog(vec3 color, vec3 dir, float depth) {
    vec3 fogColor = skyScattering(normalize(dir));
    float dist = length(dir) / far;
    float fogFactor = exp(-18.0 * (1.0 - dist));
    float rainFogFactor = exp(-7.37 * (1.0 - dist));
    fogFactor = mix(fogFactor, rainFogFactor, wetness);
    return mix(color, fogColor, clamp(fogFactor, 0.0, 1.0));
}


float getFogDensity(vec3 pos) {
    const float TOTAL_DENSITY = 0.58;
    const float _DensityThreshold = DENSITY_THRESHOLD;
    float density = 0.00;
    float weight = 0.0;

    
    float height = smoothstep(MAX_HEIGHT,MIN_HEIGHT, pos.y);

    float jungleHeight = smoothstep(93,72, pos.y);
    height = mix(height, jungleHeight, jungleSmooth);
    
    pos = pos / 10000 * NOISE_SCALE;


    #if NOISE_SAMPLING == 1
    for (int i = 0; i < VL_ATMOSPHERIC_STEPS; i++) {
        float sampleWeight = exp2(-float(i));
        pos.xz += frameTimeCounter * 0.00005 * WIND_SPEED * sqrt(i + 1);
        vec2 samplePos = (pos.zx * exp2(float(i)));

        float noise = texture(fogTex, fract(samplePos)).r * sampleWeight;
        density = noise;
       
        density = clamp(density - _DensityThreshold,0,1) * TOTAL_DENSITY * 1.15;

        weight += sampleWeight ;
    }
    density /= weight;
    #else
    density = 0.0075 * FOG_DENSITY;
    #endif
    float shadowFade = smoothstep(0.23, 0.1, worldLightVector.y);
    density = mix(density, density * 2, wetness);
    density *= TOTAL_DENSITY;
    density = mix(density ,density * 3, shadowFade);
    density = mix(density, density * 3, jungleSmooth);
    density *= height;
    
   
    return density;
}




#endif //FOG
