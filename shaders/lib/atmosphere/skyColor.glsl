#ifndef SKY_COLOR_GLSL
#define SKY_COLOR_GLSL

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"

vec3 horizonColor = vec3(0.0);
vec3 zenithColor = vec3(0.0);
vec3 earlyHorizon = vec3(0.0);
vec3 earlyZenith =  vec3(0.0);
vec3 lateHorizon = vec3(0.0);
vec3 lateZenith = vec3(0.0);
vec3 nightHorizon = vec3(0.0);
vec3 nightZenith = vec3(0.0);
vec3 rainHorizon = vec3(0.5765, 0.5765, 0.5765);
vec3 rainZenith = vec3(0.4196, 0.4196, 0.4196); 

vec3 dayZenith(vec3 color)
{
  color.r = DAY_ZEN_R * 1.34 ;
  color.g = DAY_ZEN_G * 2.34 ;
  color.b = DAY_ZEN_B * 3.34 ;
  return color;
}
vec3 dayHorizon(vec3 color)
{
  color.r = DAY_HOR_R;
  color.g = DAY_HOR_G ;
  color.b = DAY_HOR_B ;
  return color;
}
vec3 dawnZenith(vec3 color)
{
  color.r = DAWN_ZEN_R;
  color.g = DAWN_ZEN_G;
  color.b = DAWN_ZEN_B;
  return color;
}
vec3 dawnHorizon(vec3 color)
{
  color.r = DAWN_HOR_R * 2.5;
  color.g = DAWN_HOR_G * 1.25;
  color.b = DAWN_HOR_B;
  return color;
}
vec3 duskZenith(vec3 color)
{
  color.r = DUSK_ZEN_R;
  color.g = DUSK_ZEN_G;
  color.b = DUSK_ZEN_B;
  return color;
}
vec3 duskHorizon(vec3 color)
{
  color.r = DUSK_HOR_R * 2.4;
  color.g = DUSK_HOR_G * 1.2;
  color.b = DUSK_HOR_B * 0.7;
  return color;
}
vec3 NightZenith(vec3 color)
{
  color.r = NIGHT_ZEN_R;
  color.g = NIGHT_ZEN_G;
  color.b = NIGHT_ZEN_B;
  return color;
}
vec3 NightHorizon(vec3 color)
{
  color.r = NIGHT_HOR_R;
  color.g = NIGHT_HOR_G ;
  color.b = NIGHT_HOR_B * 3;
  return color;
}

float fogify(float x, float w) {
	return w / (x * x + w);
}

vec3 calcSkyColor(vec3 pos) 
{
	  vec3 horizon; 
    vec3 zenith;
  
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(pos, 1.0)).xyz;
    float VoL = dot(normalize(feetPlayerPos), worldLightVector);
    const float rayleigh = Rayleigh(VoL) * RAYLEIGH_COEFF;

    //color assignments
    //DAY
    horizonColor = dayHorizon(horizonColor) * rayleigh * 7.14;
    zenithColor= dayZenith(zenithColor) * rayleigh * 7.14;
    //DAWN
    earlyHorizon = dawnHorizon(earlyHorizon) * rayleigh * 5.24;
    earlyZenith = dawnZenith(earlyZenith) * rayleigh * 7.54 ;
    //DUSK
    lateHorizon = duskHorizon(lateHorizon) * rayleigh * 2.14;
    lateZenith = duskZenith(lateZenith) * rayleigh * 5.14  ;
    //NIGHT
    nightHorizon = NightHorizon(nightHorizon) * rayleigh;
    nightZenith = NightZenith(nightZenith) * rayleigh;

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
      float time = smoothstep(12800, 13000, float(worldTime));
      horizon = mix(lateHorizon, nightHorizon, time);
   	  zenith = mix(lateZenith, nightZenith,time);
    }
   else if (worldTime >= 13000 && worldTime < 24000)
    {
      float time = smoothstep(23500, 24000, float(worldTime));
	    horizon = mix(nightHorizon, earlyHorizon , time);
   	  zenith = mix(nightZenith, earlyZenith,time);
      rainHorizon = rainHorizon * rayleigh;
      rainZenith = rainZenith * rayleigh;
    }



      
       zenith = mix(zenith, rainZenith, wetness);
      horizon = mix(horizon, rainHorizon, wetness);

	  float upDot = dot(normalize(pos), gbufferModelView[1].xyz); //not much, what's up with you?
	  vec3 sky = mix(zenith, horizon, fogify(max(upDot, 0.0), 0.032));

    return sky;
}


vec3 calcMieSky(vec3 pos, vec3 lightPos, vec3 sunColor, vec3 viewPos, vec2 texcoord) 
{
  //Mie scattering assignments
  const vec3 mieScatterColor = vec3(0.1922, 0.1608, 0.1333) * MIE_SCALE * sunColor;
  
  vec3 mieScat = mieScatterColor;
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  float VoL = dot(normalize(feetPlayerPos), lightPos);
  if(rainStrength <= 1.0 && rainStrength > 0.0)
  {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    mieScat = mix(mieScat, mieScat *0.8, rainStrength);
  }
  if(inWater)
  {
    mieScat *= HG(0.65, VoL);
  }
    
 
  mieScat *= HG(0.65, VoL);
  return mieScat;
}

#endif //SKY_COLOR_GLSL