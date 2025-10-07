#ifndef FOG
#define FOG
#include "/lib/atmosphere/sky.glsl"

vec3 borderFog(vec3 color, vec3 dir, float depth)
{
    
    vec3 fogColor = skyScattering(normalize(dir));
    fogColor = pow(fogColor, vec3(2.2));
    float dist = length(dir) / far;
    float fogFactor = exp(-9.0 * (1.0 - dist));
    
    return mix(color, fogColor, clamp(fogFactor,0.0,1.0));
}
#endif //FOG