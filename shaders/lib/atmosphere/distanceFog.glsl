#ifndef DISTANCE_FOG_GLSL
#define DISTANCE_FOG_GLSL

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/skyColor.glsl"

vec3 distanceFog(vec3 color, vec3 viewPos,vec2 texcoord, float depth)
{

    vec3 distFog;
    distFog = calcSkyColor(normalize(viewPos));
    float dist = length(viewPos) / far;
    float fogFactor = exp(-6.0 * (1.0 - dist));

    color = mix(color, distFog, clamp(fogFactor, 0.0, 1.0));
    
    return color;

}

#endif //DISTANCE_FOG_GLSL