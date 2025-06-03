#ifndef WATER_FOG_GLSL
#define WATER_FOG_GLSL

#include "/lib/util.glsl"
#include "/lib/common.glsl"

vec3 waterExtinction(vec4 color, vec2 texcoord, vec2 lightmap, float depth, float depth1)
{
    
    float dist0=length(screenToView(texcoord,depth));
    float dist1=length(screenToView(texcoord,depth1));
    float dist=max(0,dist1-dist0);
    
    vec3 absorption= WATER_EXTINCTION;
    vec3 inscatteringAmount= WATER_SCATTERING

    vec3 absorptionFactor=exp(-absorption*WATER_FOG_DENSITY*(dist* .45));
    color.rgb*=absorptionFactor;
    color.rgb +=vec3(.6471,.4784,.2824) * lightmap.g * inscatteringAmount/absorption * (1.0 -absorptionFactor);
    return color.rgb;
}

#endif //WATER_FOG_GLSL