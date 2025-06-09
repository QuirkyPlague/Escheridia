#ifndef WATER_FOG_GLSL
#define WATER_FOG_GLSL 1 //[0 1]

#include "/lib/util.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/common.glsl"

bool inWater=isEyeInWater==1.;

vec3 waterExtinction(vec3 color, vec2 texcoord, vec2 lightmap, float depth, float depth1)
{
    
    float dist0=length(screenToView(texcoord,depth));
    float dist1=length(screenToView(texcoord,depth1));
    float dist=max(0,dist1-dist0);
    
    if(inWater)
    {
        dist = dist0;
    }

    vec3 absorption= WATER_EXTINCTION;
    vec3 inscatteringAmount= WATER_SCATTERING
    inscatteringAmount *= 0.25;
    
    vec3 absorptionFactor=exp2(-absorption*WATER_FOG_DENSITY*(dist* .45));
  
      color*=absorptionFactor;
      color+=vec3(.6471,.4784,.2824)*inscatteringAmount/absorption*(1.-absorptionFactor);
    return color;
}
vec3 waterFog(vec4 color, vec2 texcoord, vec2 lightmap, float depth, float depth1)
{
    
    float dist0=length(screenToView(texcoord,depth));
    float dist1=length(screenToView(texcoord,depth1));
    float dist=max(0,dist1-dist0);
    
    dist = dist0;
    vec3 absorption= WATER_EXTINCTION;
    absorption *= vec3(1.0, 0.9725, 0.6784);
    vec3 inscatteringAmount= WATER_SCATTERING;
    
    vec3 absorptionFactor=exp(-absorption *WATER_FOG_DENSITY *(dist* .4));
    color.rgb*=absorptionFactor;
    color.rgb += inscatteringAmount /absorption * (1.0 -absorptionFactor);

    
    return color.rgb;
}



#endif //WATER_FOG_GLSL