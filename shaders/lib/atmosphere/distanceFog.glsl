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
    float fogFactor = exp(-23.0 * (1.0 - dist));
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
vec3 distanceMieFog(vec3 color, vec3 viewPos,vec2 texcoord, float depth, vec3 lightPos, vec3 sunColor)
{
  
    vec3 distFog;
    distFog = calcMieSky(normalize(viewPos), lightPos, sunColor, viewPos, texcoord);
    float dist = length(viewPos) / far;
    float fogFactor = exp(-23.0 * (1.0 - dist));
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
  float lightmapSmooth = smoothstep(1.0,0.96, lightmap.g);
  float dist0=length(screenToView(texcoord,depth) /31);
        if(isNight)
   {
     dist0=length(screenToView(texcoord,depth)) /15;
   }
    float farPlane = far/ 4;
    float dist1= length(viewPos) / farPlane;
   
    
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    float scatterFactor = exp(-5.0 * (1.0 - dist1));
    vec3 absorption= vec3(1.0, 1.0, 1.0);
    bool isRaining = rainStrength <= 1.0 && rainStrength > 0.0;
    vec3 inscatteringAmount= calcSkyColor(normalize(viewPos));

     if(lightmap.g < 0.55)
     {
        vec3 caveInscatteringAmount= vec3(0.4549, 0.6902, 0.5451);
        inscatteringAmount *= smoothstep(0.0, 0.15, lightmap.g);
        inscatteringAmount += caveInscatteringAmount;
        dist0=length(screenToView(texcoord,depth) /43);
     }
      float dist=max(0,dist0-dist1);
     vec3 absorptionFactor=exp(-absorption* 1.0*(dist* .021));
     if(isRaining)
    {
       inscatteringAmount *= 4;
       absorptionFactor=exp(-absorption* 1.0*(dist* .03));
    }
      color*=absorptionFactor;
      color += (inscatteringAmount) /absorption*(1.- absorptionFactor);
    return color;
}
vec3 atmosphericMieFog(vec3 color, vec3 viewPos,vec2 texcoord, float depth, vec2 lightmap, vec3 lightPos,vec3 sunColor)
{
    float lightmapSmooth = smoothstep(1.0,0.97, lightmap.g);
     float z = depth * 2.0 - 1.0; // Convert from [0,1] to [-1,1]
     float linearDepth = (2.0 * near * far) / (far + near - z * (far - near));
     float dist0=length(screenToView(texcoord,depth) /13);
   
    float farPlane = far/ 4;
    float dist1= length(viewPos) / farPlane;
    float dist=max(0,dist0-dist1);
    
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    float scatterFactor = exp(-5.0 * (1.0 - dist1));
    vec3 absorption= vec3(1.0, 1.0, 1.0);
      bool isRaining = rainStrength <= 1.0 && rainStrength > 0.0;
    vec3 inscatteringAmount= calcMieSky(normalize(viewPos), lightPos, sunColor, viewPos, texcoord);
   
    vec3 absorptionFactor=exp(-absorption* 1.0*(dist* .29));
    if(isRaining)
    {
       inscatteringAmount *= 4;
       absorptionFactor=exp(-absorption* 1.0*(dist* .03));
    }
     if(lightmap.g <= 0.55)
     {
        vec3 caveInscatteringAmount= vec3(0.6824, 1.0, 0.8078);
        inscatteringAmount *= smoothstep(0.0, 0.2, lightmap.g);
     }
      float depthSmooth = smoothstep(0.99912, 1.0, depth);
      inscatteringAmount *= depthSmooth;
      color*=absorptionFactor;
      color += (inscatteringAmount)   /absorption*(1.- absorptionFactor);
      
    
   
    return color;
}

#endif //DISTANCE_FOG_GLSL