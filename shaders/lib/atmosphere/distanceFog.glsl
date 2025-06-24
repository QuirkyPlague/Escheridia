#ifndef DISTANCE_FOG_GLSL
#define DISTANCE_FOG_GLSL 1 //[0 1]

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/skyColor.glsl"

vec3 distanceFog(vec3 color, vec3 viewPos,vec2 texcoord, float depth)
{
  
    vec3 distFog;
    distFog = calcSkyColor(normalize(viewPos));
    float dist = length(viewPos) / far;
    float fogFactor = exp(-5.0 * (1.0 - dist));
    float rainFogFactor = exp(-5.5 * (1.0 - dist));
    bool isRaining = rainStrength <= 1.0 && rainStrength > 0.0;
    if(isRaining)
    {
       float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
       fogFactor = mix(fogFactor, rainFogFactor, dryToWet);
   
       distFog = mix(distFog, distFog, dryToWet);
    }
   
    color = mix(color, distFog, clamp(fogFactor, 0.0, 1.0));
   
    return color;

}

vec3 atmosphericFog(vec3 color, vec3 viewPos,vec2 texcoord, float depth, vec2 lightmap)
{
  
     float dist0=length(screenToView(texcoord,depth)) / 25;
    float farPlane = far / 4.0;
    float dist1= length(viewPos) / farPlane;
    float dist=max(0,dist0-dist1);
    
  

    vec3 absorption= vec3(1.0, 1.0, 1.0);
      bool isRaining = rainStrength <= 1.0 && rainStrength > 0.0;
    vec3 inscatteringAmount= calcSkyColor(normalize(viewPos)) * 0.7 ;
   
    vec3 absorptionFactor=exp(-absorption* 1.0*(dist* .03));
    if(isRaining)
    {
       inscatteringAmount *= 12.6;
       absorptionFactor=exp(-absorption* 1.0*(dist* .003));
    }

      color*=absorptionFactor;
      color+= (inscatteringAmount * lightmap.g) /absorption*(1.- absorptionFactor);
    
    
   
    return color;

}

#endif //DISTANCE_FOG_GLSL