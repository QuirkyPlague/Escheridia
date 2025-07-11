#ifndef SKY_COLOR_GLSL
#define SKY_COLOR_GLSL

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"


const vec3 horizonColor = vec3(0.7529, 0.8784, 0.9922);
const vec3 zenithColor = vec3(0.2549, 0.5412, 1.0);
const vec3 earlyHorizon = vec3(0.7765, 0.4706, 0.2235);
const vec3 earlyZenith =  vec3(0.298, 0.6275, 1.0);
const vec3 lateHorizon = vec3(0.3608, 0.1176, 0.0039);
const vec3 lateZenith = vec3(0.0118, 0.1686, 0.2549);
const vec3 nightHorizon = vec3(0.0235, 0.0392, 0.0863);
const vec3 nightZenith = vec3(0.0078, 0.0078, 0.0353);
vec3 rainHorizon = vec3(0.298, 0.298, 0.298);
vec3 rainZenith = vec3(0.0745, 0.0745, 0.0745); 
vec3 horizon; 
vec3 zenith;


float fogify(float x, float w) {
	return w / (x * x + w);
}

vec3 calcSkyColor(vec3 pos) {
	 bool inWater = isEyeInWater ==1.0;
   if (worldTime >= 0 && worldTime < 1000)
  {
    //smoothstep equation allows interpolation between times of day
    float time = smoothstep(0, 1000, float(worldTime));
   horizon = mix(earlyHorizon, horizonColor, time);
   zenith = mix(earlyZenith, zenithColor,time);
  }
   else if (worldTime >= 1000 && worldTime < 11500)
  {
     float time = smoothstep(10000, 11500, float(worldTime));
	horizon = mix(horizonColor, lateHorizon, time);
   	zenith = mix(zenithColor, lateZenith,time);
  }
  else if (worldTime >= 11500 && worldTime < 13000)
  {
     float time = smoothstep(11500, 13000, float(worldTime));
    horizon = mix(lateHorizon, nightHorizon, time);
   	zenith = mix(lateZenith, nightZenith,time);
  }
   else if (worldTime >= 13000 && worldTime < 24000)
  {
    float time = smoothstep(23000, 24000, float(worldTime));
	horizon = mix(nightHorizon, earlyHorizon, time);
   	zenith = mix(nightZenith, earlyZenith,time);
	  
  }
  if(rainStrength <= 1.0 && rainStrength > 0.0)
  {
    vec3 currentZenithColor = zenith * 2;
    vec3 currentHorizonColor = horizon * 2;
    if(worldTime >= 13000 && worldTime < 24000)
    {
      rainZenith *=  0.1;
      rainHorizon *=  0.1;
    }
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    zenith = mix(currentZenithColor, rainZenith, dryToWet);
    horizon = mix(currentHorizonColor, rainHorizon, dryToWet);
  }
  
	horizon *= 4.5;
  zenith *= 4.5;
	float upDot = dot(pos, gbufferModelView[1].xyz); //not much, what's up with you?
	return mix(zenith, horizon, fogify(max(upDot, 0.0), 0.018));
}

vec3 MieScatter(vec3 color, vec3 lightPos, vec3 viewPos, vec3 sunColor)
{
  color = calcSkyColor(normalize(viewPos));
  bool isNight = worldTime >= 13000 && worldTime < 23000;
  
  
  vec3 mieScatterColor = vec3(0.2549, 0.2235, 0.1765) * MIE_SCALE * sunColor;
  if(isNight)
  {
    mieScatterColor = vec3(0.00039, 0.00039, 0.00078) * MIE_SCALE * sunColor;
  }
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  float VoL = dot(normalize(feetPlayerPos), lightPos);
  
  color = mix(color * 0.03 , mieScatterColor, 0.212);
  if(isNight)
  {
     color = mix(color * 1.0, mieScatterColor, 0.32);
     color *= HG(0.82, VoL);
  }
  else
  {
    color *= HG(0.73, VoL);
  }
  
  return color;
}

vec3 calcMieSky(vec3 pos, vec3 lightPos, vec3 sunColor, vec3 viewPos, vec2 texcoord) {
	 bool inWater = isEyeInWater ==1.0;
  const vec3 earlyMieScatterColor = vec3(0.8784, 0.5843, 0.3725) * MIE_SCALE * sunColor;
  const vec3 mieScatterColor = vec3(0.4275, 0.3451, 0.2863) * MIE_SCALE * sunColor;
  const vec3 lateMieScatterColor = vec3(1.0, 0.2392, 0.1216) * MIE_SCALE * sunColor;
  const vec3 nightMieScatterColor = vec3(0.9255, 0.9451, 1.0) * MIE_SCALE * sunColor;
  vec3 mieScat; 
   if (worldTime >= 0 && worldTime < 1000)
  {
    //smoothstep equation allows interpolation between times of day
    float time = smoothstep(0, 1000, float(worldTime));
    horizon = mix(earlyHorizon, horizonColor, time);
    zenith = mix(earlyZenith, zenithColor,time);
    mieScat = mix(earlyMieScatterColor, mieScatterColor, time);
  }
   else if (worldTime >= 1000 && worldTime < 11500)
  {
     float time = smoothstep(10000, 11500, float(worldTime));
	  horizon = mix(horizonColor, lateHorizon, time);
   	zenith = mix(zenithColor, lateZenith,time);
    mieScat = mix(mieScatterColor, lateMieScatterColor, time);
  }
  else if (worldTime >= 11500 && worldTime < 13000)
  {
    float time = smoothstep(11500, 13000, float(worldTime));
    horizon = mix(lateHorizon, nightHorizon, time);
   	zenith = mix(lateZenith, nightZenith,time);
    mieScat =mix(lateMieScatterColor, nightMieScatterColor, time);
  }
   else if (worldTime >= 13000 && worldTime < 24000)
  {
    float time = smoothstep(23000, 24000, float(worldTime));
	  horizon = mix(nightHorizon, earlyHorizon, time);
   	zenith = mix(nightZenith, earlyZenith,time);
	  mieScat =mix(nightMieScatterColor,earlyMieScatterColor, time);
  }
  if(rainStrength <= 1.0 && rainStrength > 0.0)
  {
    vec3 currentZenithColor = zenith;
    vec3 currentHorizonColor = horizon;
    if(worldTime >= 13000 && worldTime < 24000)
    {
      rainZenith *=  0.1;
      rainHorizon *=  0.1;
    }
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    zenith = mix(currentZenithColor, rainZenith, dryToWet);
    horizon = mix(currentHorizonColor, rainHorizon, dryToWet);
    
  }
    bool isNight = worldTime >= 13000 && worldTime < 23000;
	  float upDot = dot(pos, gbufferModelView[1].xyz); //not much, what's up with you?
	  vec3 skyColor = mix(zenith, horizon, fogify(max(upDot, 0.0), 0.028));
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    float VoL = dot(normalize(feetPlayerPos), lightPos);
 
  
  if(inWater)
  {
    mieScat *= vec3(0.098, 0.0, 1.0) * MIE_SCALE * sunColor;
  }
  
  if(isNight)
  {
     mieScat *= HG(0.92, VoL);
  }
  else
  {
    mieScat *= HG(0.64, VoL);
  }
  return skyColor = mix(skyColor * 0.3 , mieScat, 0.812);
}

#endif //SKY_COLOR_GLSL