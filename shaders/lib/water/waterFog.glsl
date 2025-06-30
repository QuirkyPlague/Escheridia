#ifndef WATER_FOG_GLSL
#define WATER_FOG_GLSL 1 //[0 1]

#include "/lib/util.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/common.glsl"

bool inWater=isEyeInWater==1.;

vec3 waterExtinction(vec3 color, vec2 texcoord, vec2 lightmap, float depth, float depth1)
{
    bool isNight = worldTime >= 13000 && worldTime < 24000;
    float dist0=length(screenToView(texcoord,depth));
    float dist1=length(screenToView(texcoord,depth1));
    float dist=max(0,dist1-dist0);
    
    if(inWater)
    {
        dist = dist0;
    }

    vec3 absorption= WATER_EXTINCTION;
    vec3 inscatteringAmount= WATER_SCATTERING
    inscatteringAmount *= 0.35;
    
    vec3 absorptionFactor=exp(-absorption*WATER_FOG_DENSITY*(dist* .35));
  
      color*=absorptionFactor;
      color+=vec3(.6471,.4784,.2824)*inscatteringAmount/absorption*(1.- clamp(absorptionFactor, 0, 1));
      if(isNight)
      {
        color *= 0.3;
      }
    return color;
}
vec3 waterFog(vec3 color, vec2 texcoord, vec2 lightmap, float depth, float depth1)
{
    
    float dist0=length(screenToView(texcoord,depth));
    float dist1=length(screenToView(texcoord,depth1));
    float dist=max(0,dist1-dist0);
    
    dist = dist0;
    vec3 absorption= WATER_EXTINCTION;
    vec3 inscatteringAmount= WATER_SCATTERING;
    
    vec3 absorptionFactor=exp(-absorption *WATER_FOG_DENSITY *(dist* .15));
    color.rgb*=absorptionFactor;
    color.rgb += vec3(.6471,.4784,.2824)* inscatteringAmount /absorption * (1.0 -absorptionFactor);

    
    return color.rgb;
}



#endif //WATER_FOG_GLSL