#ifndef WATER_FOG_GLSL
#define WATER_FOG_GLSL 1 //[0 1]

#include "/lib/util.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/common.glsl"
#include "/lib/atmosphere/skyColor.glsl"
#include "/lib/lighting/lighting.glsl"
bool inWater=isEyeInWater==1.;

vec3 waterColor(vec3 color)
{
  color.r = ABSORPTION_R;
  color.g = ABSORPTION_G;
  color.b = ABSORPTION_B;

  return color;
}

vec3 waterScatter(vec3 color)
{
  color.r = SCATTER_R;
  color.g = SCATTER_G;
  color.b = SCATTER_B;

  return color;
}

vec3 waterExtinction(vec3 color, vec2 texcoord, vec2 lightmap, float depth, float depth1)
{
  
    float dist0=length(screenToView(texcoord,depth));
    float dist1=length(screenToView(texcoord,depth1));
    float dist=max(0,dist1-dist0);
     vec3 sunColor = vec3(0.0);
    sunColor = currentSunColor(sunColor);
    if(inWater)
    {
        dist = dist0;
    }
    vec3 absorptionColor = vec3(0.0);
    vec3 absorption= waterColor(absorptionColor);
    vec3 inscatteringAmount = vec3(0.0);
    inscatteringAmount = waterScatter(inscatteringAmount);
    inscatteringAmount *= SCATTER_COEFF;
    vec3 absorptionFactor=exp(-absorption*WATER_FOG_DENSITY*(dist* ABSORPTION_COEFF));
  
      color *= absorptionFactor;
      color += sunColor * inscatteringAmount / absorption* (1.- clamp(absorptionFactor, 0, 1));
      if(isNight && lightmap.g > 0.85)
      {
        color *= 0.3;
      }
    return color;
}
vec3 waterFog(vec3 color, vec2 texcoord, vec2 lightmap, float depth, float depth1)
{
    
    float dist0=length(screenToView(texcoord,depth)) / 3;
    float dist1=length(screenToView(texcoord,depth1));
    float dist=max(0,dist1-dist0);
    vec3 sunColor = vec3(0.0);
    sunColor = currentSunColor(sunColor);
    dist = dist0;
    vec3 absorptionColor = vec3(0.0);
    vec3 absorption= waterColor(absorptionColor);
    vec3 inscatteringAmount = vec3(0.0);
    inscatteringAmount = waterScatter(inscatteringAmount);
    inscatteringAmount *= SCATTER_COEFF;
    vec3 absorptionFactor=exp(-absorption * UNDERWATER_FOG_DENSITY *(dist* ABSORPTION_COEFF));
    color.rgb*=absorptionFactor;
    color.rgb +=  inscatteringAmount /absorption * (1.0 -absorptionFactor);

    
    return color.rgb;
}
vec3 waterMie(vec3 color, vec2 texcoord, vec2 lightmap, float depth, float depth1, vec3 pos)
{
    
    float dist0=length(screenToView(texcoord,depth));
    float dist1=length(screenToView(texcoord,depth1));
    float dist=max(0,dist1-dist0);
    vec3 sunPos = normalize(shadowLightPosition);
    vec3 worldSunPos = mat3(gbufferModelViewInverse) * sunPos;
     
    float VoL = dot(normalize(pos), worldSunPos);
    dist0 *= max(dist0, VoL);
    dist = dist0;
    vec3 absorptionColor = vec3(0.0);
    vec3 absorption= waterColor(absorptionColor);

    vec3 sunColor = vec3(0.0);
    sunColor = currentSunColor(sunColor) ;
  
    vec3 inscatteringAmount= calcMieSky(normalize(pos), worldSunPos, sunColor, pos, texcoord);
   
    vec3 absorptionFactor=exp(-absorption *WATER_FOG_DENSITY *(dist* ABSORPTION_COEFF));
    color.rgb*=absorptionFactor;
    color.rgb += inscatteringAmount * sunColor /absorption * (1.0 -absorptionFactor);
    
    

    
    return color.rgb;
}



#endif //WATER_FOG_GLSL