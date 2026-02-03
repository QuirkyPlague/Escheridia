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

    
    float height = smoothstep(115,81, pos.y);

    pos = pos / 10000 * NOISE_SCALE;


    #if NOISE_SAMPLING == 1
    for (int i = 0; i < VL_ATMOSPHERIC_STEPS; i++) {
        float sampleWeight = exp2(-float(i));
        pos.xz += frameTimeCounter * 0.00015 * WIND_SPEED * sqrt(i + 1);
        vec2 samplePos = (pos.zx * exp2(float(i)));

        float noise = texture(fogTex, fract(samplePos)).r * sampleWeight;
        density += dot(noise, noise);
       
        density = clamp(density - _DensityThreshold,0,1) * TOTAL_DENSITY * 1.1;

        weight += sampleWeight ;
    }
    density /= weight;
    #else
    density = 0.0055 * FOG_DENSITY;
    #endif
    float shadowFade = smoothstep(0.23, 0.1, worldLightVector.y);
    density = mix(density, density * 6, wetness);
    density *= TOTAL_DENSITY;
    density = mix(density ,density * 3, shadowFade);
    density *= height;
    
   
    return density;
}

float getCloudDensity(vec3 pos) {
    const float TOTAL_DENSITY = 0.84;
    const float _DensityThreshold2 = CLOUD_DENSITY_THRESHOLD;
    float cloudDensity = 0.0;
    float weight = 0.0;

    vec3 cloudPos = pos;
    float height = smoothstep(164, 182, cloudPos.y);
    if(cloudPos.y > 190) return 0.0;
    cloudPos = cloudPos / 10000 * CLOUD_NOISE_SCALE;

    for (int i = 0; i < 4; i++) {
        float sampleWeight = exp2(-float(i));
        cloudPos.xz += frameTimeCounter * 0.00004 * sqrt(i + 1);
        vec2 cloudSamplePos = (cloudPos.zx * exp2(float(i)));
        float cloudNoise = texture(clouds, fract(cloudSamplePos)).r * sampleWeight;

        cloudDensity += dot(cloudNoise,cloudNoise);
        cloudDensity = clamp(cloudDensity - _DensityThreshold2,0,1) * TOTAL_DENSITY;

        weight += sampleWeight ;
    }

    cloudDensity /= weight;
    

    cloudDensity *= 1.0;
    cloudDensity *= height;

    

   
    return  cloudDensity;
}


#endif //FOG
