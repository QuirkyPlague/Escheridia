#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"
#include "/lib/lighting/lighting.glsl"
#include "/lib/common.glsl"
uniform int renderStage;

in vec3 normal;
in mat3 tbnMatrix;
vec3 horizon;
vec3 zenith;
in vec3 modelPos;
in vec3 viewPos;
in vec4 glcolor;
in vec2 texcoord;


vec3 horizonColor = vec3(0.0);
vec3 zenithColor = vec3(0.0);
vec3 earlyHorizon = vec3(0.0);
vec3 earlyZenith =  vec3(0.0);
vec3 lateHorizon = vec3(0.0);
vec3 lateZenith = vec3(0.0);
vec3 nightHorizon = vec3(0.0);
vec3 nightZenith = vec3(0.0);
vec3 rainHorizon = vec3(0.5098, 0.5098, 0.5098) *9 ;
vec3 rainZenith = vec3(0.2157, 0.2157, 0.2157) * 9; 

vec3 dayZenith(vec3 color)
{
  color.r = DAY_ZEN_R;
  color.g = DAY_ZEN_G;
  color.b = DAY_ZEN_B;
  return color;
}
vec3 dayHorizon(vec3 color)
{
  color.r = DAY_HOR_R;
  color.g = DAY_HOR_G;
  color.b = DAY_HOR_B;
  return color;
}
vec3 dawnZenith(vec3 color)
{
  color.r = DAWN_ZEN_R;
  color.g = DAWN_ZEN_G ;
  color.b = DAWN_ZEN_B;
  return color;
}
vec3 dawnHorizon(vec3 color)
{
  color.r = DAWN_HOR_R * 1.55 ;
  color.g = DAWN_HOR_G * 1.55;
  color.b = DAWN_HOR_B * 1.55;
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
  color.r = DUSK_HOR_R * 2.5;
  color.g = DUSK_HOR_G * 2.5;
  color.b = DUSK_HOR_B * 2.5;
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
  color.g = NIGHT_HOR_G * 1.64;
  color.b = NIGHT_HOR_B * 1.63;
  return color;
}

float fogify(float x, float w) {
	return w / (x * x + w);
}

vec3 calcSkyColor(vec3 pos) 
{
	  vec3 horizon; 
    vec3 zenith;
    bool inWater = isEyeInWater ==1.0;
    vec3 sunPos = normalize(shadowLightPosition);
    float VoL = dot(pos, sunPos);
    float rayleigh = Rayleigh(VoL) * RAYLEIGH_COEFF;
    //color assignments
    //DAY
    horizonColor = dayHorizon(horizonColor) * rayleigh * 41.14;
    zenithColor= dayZenith(zenithColor) * rayleigh * 41.14;
    //DAWN
    earlyHorizon = dawnHorizon(earlyHorizon) * rayleigh * 32.14;
    earlyZenith = dawnZenith(earlyZenith) * rayleigh * 32.14  ;
    //DUSK
    lateHorizon = duskHorizon(lateHorizon) * rayleigh * 32.14;
    lateZenith = duskZenith(lateZenith) * rayleigh * 32.14  ;
    //NIGHT
    nightHorizon = NightHorizon(nightHorizon) * rayleigh * 38.14;
    nightZenith = NightZenith(nightZenith) * rayleigh * 32.14;

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
      float time = smoothstep(23000, 24000, float(worldTime));
	    horizon = mix(nightHorizon, earlyHorizon , time);
   	  zenith = mix(nightZenith, earlyZenith,time);
	  
    }

    if(rainStrength <= 1.0 && rainStrength > 0.0)
    {
      vec3 currentZenithColor = zenith;
      vec3 currentHorizonColor = horizon;

      if(worldTime >= 13000 && worldTime < 24000)
      {
        rainZenith *=  0.2;
        rainHorizon *=  0.34;
      }

      float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
      zenith = mix(currentZenithColor, rainZenith, dryToWet);
      horizon = mix(currentHorizonColor, rainHorizon, dryToWet);
    }

    
	  float upDot = dot(pos, gbufferModelView[1].xyz); //not much, what's up with you?
	  vec3 sky = mix(zenith, horizon, fogify(max(upDot, 0.0), 0.021));
   
    vec3 sunColor = vec3(0.0);
    sunColor = currentSunColor(sunColor);
   float sun_a = acos(dot(sunPos, pos));
    const vec3 sun_col = .12 * (sunColor * vec3(0.7373, 0.4275, 0.1333)) / sun_a;
    const vec3 morning_sun_col = .03 * sunColor / sun_a;
    const vec3 evening_sun_col = .06 * sunColor / sun_a;
    const vec3 night_sun_col = 0.0 * vec3(0.0);
    vec3 sun = vec3(0.0);
    if(worldTime >= 0 && worldTime < 1000)
    {
      float time = smoothstep(0, 1000, float(worldTime));
      sun = mix(morning_sun_col, sun_col, time);
    }
    else if (worldTime >= 1000 && worldTime < 11500)
    {
      float time = smoothstep(10000, 11500, float(worldTime));
      sun = mix(sun_col, evening_sun_col, time);
    }
      else if (worldTime >= 11500 && worldTime < 13000)
    {
      float time = smoothstep(12800, 13000, float(worldTime));
      sun = mix(evening_sun_col , night_sun_col, time);
    }
    else if (worldTime >= 13000 && worldTime < 23000)
    {
      float time = smoothstep(22300, 23000, float(worldTime));
	    sun = mix(night_sun_col, morning_sun_col, time);
    }
      else if(worldTime >= 23000 && worldTime < 24000)
    {
      float time = smoothstep(23000, 24000, float(worldTime));
      sun = mix(night_sun_col, morning_sun_col, time);
    }
    sky = max(sky + .3 * sun , sun - wetness);
   
   
    return sky;
}

vec3 calcMieSky(vec3 pos, vec3 lightPos, vec3 sunColor, vec3 viewPos, vec2 texcoord) 
{
	  vec3 horizon; 
    vec3 zenith;
    bool inWater = isEyeInWater ==1.0;
     vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
      float VoL = dot(normalize(feetPlayerPos), lightPos);
      float rayleigh = Rayleigh(VoL) * RAYLEIGH_COEFF;
      //color assignments
     //DAY
    horizonColor = dayHorizon(horizonColor) * rayleigh * 32.14;
    zenithColor= dayZenith(zenithColor) * rayleigh * 32.14;
    //DAWN
    earlyHorizon = dawnHorizon(earlyHorizon) * rayleigh * 27.14;
    earlyZenith = dawnZenith(earlyZenith) * rayleigh * 27.14  ;
    //DUSK
    lateHorizon = duskHorizon(lateHorizon) * rayleigh * 25.14;
    lateZenith = duskZenith(lateZenith) * rayleigh * 25.14  ;
    //NIGHT
    nightHorizon = NightHorizon(nightHorizon) * rayleigh * 32.14;
    nightZenith = NightZenith(nightZenith) * rayleigh * 32.14;

    //Mie scattering assignments
    const vec3 earlyMieScatterColor = vec3(0.0314, 0.0118, 0.0039) * MIE_SCALE * sunColor;
    const vec3 mieScatterColor = vec3(0.0627, 0.0314, 0.0078) * MIE_SCALE * sunColor;
    const vec3 lateMieScatterColor = vec3(0.0706, 0.0157, 0.0078) * MIE_SCALE * sunColor;
    const vec3 nightMieScatterColor = vec3(0.0235, 0.0314, 0.0471) * MIE_SCALE * sunColor;
    vec3 mieScat = vec3(0.0);

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
	    horizon = mix(nightHorizon, earlyHorizon * 0.2, time);
   	  zenith = mix(nightZenith, earlyZenith,time * 0.2);
	    mieScat =mix(nightMieScatterColor,earlyMieScatterColor, time);
    }  
    if(rainStrength <= 1.0 && rainStrength > 0.0)
    {
      vec3 currentZenithColor = zenith;
      vec3 currentHorizonColor = horizon;
      
      if(worldTime >= 13000 && worldTime < 24000)
      {
        rainZenith *=  0.04;
        rainHorizon *=  0.04;
      }

      float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
      zenith = mix(currentZenithColor, rainZenith, dryToWet);
      horizon = mix(currentHorizonColor, rainHorizon, dryToWet);
    
    }

      bool isNight = worldTime >= 13000 && worldTime < 23000;
	    float upDot = dot(pos, gbufferModelView[1].xyz); //not much, what's up with you?
	    vec3 skyColor = mix(zenith, horizon, fogify(max(upDot, 0.0), 0.028));

    if(inWater)
    {
      mieScat *=  MIE_SCALE * sunColor;
      mieScat *= HG(0.32, VoL);
    }
  
    if(isNight)
    {
      mieScat *= HG(0.72, VoL);
    }
    else
    {
      mieScat *= HG(0.68, VoL);
    }
  return skyColor = mix(skyColor * 0.5  , mieScat, 1.913);
}

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;



void main() {
if (renderStage == MC_RENDER_STAGE_STARS) {
		color = glcolor * 3.2;
	} else {
		vec3 pos = viewPos;
    vec3 lightPos= normalize(shadowLightPosition);
    vec3 worldLightPos = mat3(gbufferModelViewInverse) * lightPos;
		vec4 skyMain = vec4(calcSkyColor(normalize(pos)), 1.0);
    vec3 sunColor = vec3(0.0);
    sunColor = currentSunColor(sunColor);
    vec4 skyMie = vec4(calcMieSky(normalize(pos), worldLightPos, sunColor, viewPos, texcoord), 1.0);
    color = mix(skyMain, skyMie, 0.5);
    
	}
}
