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




float remap1(float value, float originalMin, float originalMax, float newMin, float newMax)
{
    return newMin + (((value - originalMin) / (originalMax - originalMin) * (newMax - newMin)));
}

float getFogDensity(vec3 pos)
{
    const float totalDensity = 0.0195;
    float jungleHeight = smoothstep(101, 85, pos.y);
    float height = smoothstep(mix(MAX_HEIGHT, MAX_HEIGHT + 30, wetness), mix(MIN_HEIGHT, MIN_HEIGHT + 30, wetness), pos.y);

    height = mix(height, jungleHeight, jungleSmooth);
    
    vec4 shape = vec4(0.0);
    vec4 detail1 = vec4(0.0);
    vec4 detail2 = vec4(0.0);
    float density = 0.0;
    
    vec3 uvw = pos * NOISE_SCALE * 0.0001 + 1.0 * 0.1 * (frameTimeCounter * 0.006) * WIND_SPEED;
    float baseDensity = 0.0043;
    shape = texture(fogTex, uvw.xz);
    if(!inWater)
    {
    #if NOISE_SAMPLING == 1
    detail1 = texture(cloudBase, uvw.xz);
    detail2 = texture(detail, uvw.xz);
    shape.r = remap1(shape.r, 1.0 - detail1.r , 1.0, 0.0, 1.0);
    shape.r = mix(shape.r, shape.r , jungleHeight);
    //shape = mix(shape, vec4(1.0), wetness);
    float threshold = max(0, shape.r - DENSITY_THRESHOLD);
    float jungleThreshold =   max(0.08, shape.r - 0.075);
    threshold = mix(threshold, jungleThreshold, jungleSmooth);
    
    density = threshold * FOG_DENSITY;
    #else
    density = 0.0325;
    #endif
    float morningFog = smoothstep(0.3, 0.1, worldLightVector.y);
    density = mix(density, density * 1.45, morningFog);
    density = mix(density, density * 6.15, jungleSmooth);
    baseDensity = mix(baseDensity, baseDensity * 1.25, morningFog);
    density *= totalDensity * height;
    density += baseDensity;
    }
    else
    {
        density = 0.04;
    }
    density = mix(density, density * 1.71, wetness);
     density = mix(density,0.05, float(inWater)) ;
     if(pos.y < 55 && eyeBrightness.y < 0.2 && !inWater) density = 0;
      
    return density  * FOG_DENSITY;
}


#endif //FOG
