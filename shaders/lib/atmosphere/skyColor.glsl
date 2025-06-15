#ifndef SKY_COLOR_GLSL
#define SKY_COLOR_GLSL

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"

const vec3 horizonColor = vec3(0.4588, 0.6667, 0.7137);
const vec3 zenithColor = vec3(0.2784, 0.4235, 0.651);
const vec3 earlyHorizon = vec3(0.4902, 0.4196, 0.2667);
const vec3 earlyZenith =  vec3(0.2549, 0.4667, 0.4745);
const vec3 lateHorizon = vec3(0.3804, 0.1765, 0.098);
const vec3 lateZenith = vec3(0.2706, 0.451, 0.5529);
const vec3 nightHorizon = vec3(0.0353, 0.1059, 0.2118);
const vec3 nightZenith = vec3(0.0118, 0.0118, 0.0118);
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
    float time = smoothstep(23215, 24000, float(worldTime));
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
  
	 horizon = pow(horizon, vec3(2.2));
	 zenith = pow(zenith, vec3(2.2));
	float upDot = dot(pos, gbufferModelView[1].xyz); //not much, what's up with you?
	return mix(zenith, horizon, fogify(max(upDot, 0.0), 0.028));
}

vec3 MieScatter(vec3 color, vec3 lightPos, vec3 feetPlayerPos, vec3 viewPos)
{
  color = calcSkyColor(normalize(viewPos));
  bool isNight = worldTime >= 13000 && worldTime < 24000;
  vec3 mieScatterColor = vec3(0.0588, 0.0353, 0.0039) * MIE_SCALE;
  if(isNight)
  {
    mieScatterColor = vec3(0.0039, 0.0039, 0.0078);
  }
  float VoL = dot(normalize(feetPlayerPos), lightPos);
  
  color = mix(color * 0.5, mieScatterColor, 0.9);
  if(isNight)
  {
     color = mix(color * 0.6, mieScatterColor, 0.01);
     color *= HG(0.95, VoL);
  }
  else
  {
    color *= HG(0.65, VoL);
  }
  
  return color;
}
vec4 cloudScatter(vec4 color, vec3 lightPos, vec3 feetPlayerPos, vec3 viewPos)
{
  vec4 mieCloudScatter = vec4(0.1216, 0.0706, 0.0235, 1.0);
  float VoL = dot(normalize(feetPlayerPos), lightPos);
  color = mix(color, mieCloudScatter, 1.0);
  color *= HG(0.65, VoL);
  return color;

}
#endif //SKY_COLOR_GLSL