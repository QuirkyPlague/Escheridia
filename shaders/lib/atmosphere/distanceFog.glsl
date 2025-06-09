#ifndef DISTANCE_FOG_GLSL
#define DISTANCE_FOG_GLSL 1 //[0 1]

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/skyColor.glsl"

vec3 distanceFog(vec3 color, vec3 viewPos,vec2 texcoord, float depth)
{
    bool isNight = worldTime >= 13000 && worldTime < 24000;
    vec3 distFog;
    distFog = calcSkyColor(normalize(viewPos));
    float dist = length(viewPos) / far;
    float fogFactor = exp(-8.0 * (1.0 - dist));
    float rainFogFactor = exp(-5.0 * (1.0 - dist));
    bool isRaining = rainStrength <= 1.0 && rainStrength > 0.0;
    if(isRaining)
    {
       float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
       fogFactor = mix(fogFactor, rainFogFactor, dryToWet); 
    }
    color = mix(color, distFog, clamp(fogFactor, 0.0, 1.0));
   
    return color;

}

#endif //DISTANCE_FOG_GLSL