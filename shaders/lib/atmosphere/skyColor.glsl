#ifndef SKY_COLOR_GLSL
#define SKY_COLOR_GLSL

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"


const vec3 horizonColor = vec3(0.2275, 0.4549, 0.502);
const vec3 zenithColor = vec3(0.0275, 0.1765, 0.4118);
const vec3 earlyHorizon = vec3(0.298, 0.1922, 0.0471);
const vec3 earlyZenith =  vec3(0.0275, 0.3137, 0.4196);
const vec3 lateHorizon = vec3(0.3608, 0.1176, 0.0039);
const vec3 lateZenith = vec3(0.0118, 0.1686, 0.2549);
const vec3 nightHorizon = vec3(0.0096, 0.0192, 0.0327);
const vec3 nightZenith = vec3(0.0, 0.00039, 0.00157);
vec3 rainHorizon = vec3(0.8157, 0.8157, 0.8157);
vec3 rainZenith = vec3(0.3725, 0.3725, 0.3725); 
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
  
	
	float upDot = dot(pos, gbufferModelView[1].xyz); //not much, what's up with you?
	return mix(zenith, horizon, fogify(max(upDot, 0.0), 0.028));
}

vec3 MieScatter(vec3 color, vec3 lightPos, vec3 feetPlayerPos, vec3 viewPos, vec3 sunColor)
{
  color = calcSkyColor(normalize(viewPos));
  bool isNight = worldTime >= 13000 && worldTime < 23000;
  
  
  vec3 mieScatterColor = vec3(0.102, 0.0667, 0.0235) * MIE_SCALE * sunColor;
  if(isNight)
  {
    mieScatterColor = vec3(0.00039, 0.00039, 0.00078) * MIE_SCALE * sunColor;
  }
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
vec4 cloudScatter(vec4 color, vec3 lightPos, vec3 feetPlayerPos, vec3 viewPos)
{
  vec4 mieCloudScatter = vec4(0.4314, 0.3098, 0.1647, 1.0);
  float VoL = dot(normalize(feetPlayerPos), lightPos);
  float dist = length(viewPos) / far;
  float scatterCondense = HG(0.65, VoL);
  float scatterFactor = exp(15.0 * (1.0 - scatterCondense));
  color = mix(mieCloudScatter, color, clamp(scatterFactor, 0,1));
  
  return color;

}
#endif //SKY_COLOR_GLSL