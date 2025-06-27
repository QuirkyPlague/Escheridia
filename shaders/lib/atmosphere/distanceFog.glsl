#ifndef DISTANCE_FOG_GLSL
#define DISTANCE_FOG_GLSL 1 //[0 1]

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/skyColor.glsl"

vec3 fogMie(vec3 color, vec3 lightPos, vec3 feetPlayerPos, vec3 viewPos)
{
  color = calcSkyColor(normalize(viewPos));
  bool isNight = worldTime >= 13000 && worldTime < 24000;
  vec3 mieScatterColor = vec3(0.00606, 0.00431, 0.00275) * MIE_SCALE;
  if(isNight)
  {
    mieScatterColor = vec3(0.0039, 0.0039, 0.0078);
  }
  
  float VoL = dot(normalize(feetPlayerPos), lightPos);
  
  color = mix(color * 0.24 , mieScatterColor, 0.667);
  if(isNight)
  {
     color = mix(color * 1.0, mieScatterColor, 0.01);
     color *= HG(0.75, VoL);
  }
  else
  {
    color *= HG(0.35, VoL);
  }
  
  return color;
}

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
  
     float dist0=length(screenToView(texcoord,depth) /52);
    float farPlane = far/ 4;
    float dist1= length(viewPos) / farPlane;
    float dist=max(0,dist0-dist1);
    
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    float scatterFactor = exp(-5.0 * (1.0 - dist1));
    vec3 absorption= vec3(1.0, 1.0, 1.0);
      bool isRaining = rainStrength <= 1.0 && rainStrength > 0.0;
    vec3 inscatteringAmount= calcSkyColor(normalize(viewPos)) ;
   if(isNight)
   {
     inscatteringAmount *= 3.3;
   }
    vec3 absorptionFactor=exp(-absorption* 1.0*(dist* .05));
    if(isRaining)
    {
       inscatteringAmount *= 4;
       absorptionFactor=exp(-absorption* 1.0*(dist* .03));
    }
     
      color*=absorptionFactor;
      color += inscatteringAmount   /absorption*(1.- absorptionFactor);
      
    
    
      
      
   
    return color;

}

#endif //DISTANCE_FOG_GLSL