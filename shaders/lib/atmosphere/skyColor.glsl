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
vec3 rainHorizon = vec3(0.298, 0.298, 0.298);
vec3 rainZenith = vec3(0.0745, 0.0745, 0.0745); 

vec3 dayZenith(vec3 color)
{
  color.r = DAY_ZEN_R  ;
  color.g = DAY_ZEN_G  ;
  color.b = DAY_ZEN_B  ;
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
  color.r = DAWN_HOR_R ;
  color.g = DAWN_HOR_G;
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
  color.r = DUSK_HOR_R;
  color.g = DUSK_HOR_G;
  color.b = DUSK_HOR_B;
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
  color.g = NIGHT_HOR_G;
  color.b = NIGHT_HOR_B;
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
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(pos, 1.0)).xyz;
    vec3 worldLightPos = mat3(gbufferModelViewInverse) * sunPos;
    float VoL = dot(normalize(feetPlayerPos), worldLightPos);
    const float rayleigh = Rayleigh(VoL) * RAYLEIGH_COEFF;

    //color assignments
    //DAY
    horizonColor = dayHorizon(horizonColor) * rayleigh * 7.14;
    zenithColor= dayZenith(zenithColor) * rayleigh * 5.14;
    //DAWN
    earlyHorizon = dawnHorizon(earlyHorizon) * rayleigh * 7.24;
    earlyZenith = dawnZenith(earlyZenith) * rayleigh * 7.54 ;
    //DUSK
    lateHorizon = duskHorizon(lateHorizon) * rayleigh * 11.14;
    lateZenith = duskZenith(lateZenith) * rayleigh * 5.14  ;
    //NIGHT
    nightHorizon = NightHorizon(nightHorizon) * rayleigh * 2.25;
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
      float time = smoothstep(23000, 24000, float(worldTime));
	    horizon = mix(nightHorizon, earlyHorizon , time);
   	  zenith = mix(nightZenith, earlyZenith,time);
    }

    vec3 currentZenithColor = zenith;
    vec3 currentHorizonColor = horizon;

    if(worldTime >= 13000 && worldTime < 24000)
    {
      rainZenith = rainZenith * 0.2 * rayleigh;
      rainHorizon = rainHorizon *  0.2 * rayleigh;
    }

      
    zenith = mix(currentZenithColor, rainZenith, pow(wetness, 1.0/9.0));
    horizon = mix(currentHorizonColor, rainHorizon, pow(wetness, 1.0/9.0));

	  float upDot = dot(normalize(pos), gbufferModelView[1].xyz); //not much, what's up with you?
	  vec3 sky = mix(zenith, horizon, fogify(max(upDot, 0.0), 0.021));

    return sky;
}


vec3 calcMieSky(vec3 pos, vec3 lightPos, vec3 sunColor, vec3 viewPos, vec2 texcoord) 
{
    //Mie scattering assignments
    const vec3 earlyMieScatterColor = vec3(0.1294, 0.051, 0.0118) * MIE_SCALE * sunColor;
    const vec3 mieScatterColor = vec3(0.0627, 0.0314, 0.0078) * MIE_SCALE * sunColor;
    const vec3 lateMieScatterColor = vec3(0.0549, 0.0118, 0.0078) * MIE_SCALE * sunColor;
    const vec3 nightMieScatterColor = vec3(0.0706, 0.102, 0.1647) * MIE_SCALE * sunColor;
    vec3 mieScat = vec3(0.0);

    if (worldTime >= 0 && worldTime < 1000)
    {
      //smoothstep equation allows interpolation between times of day
      float time = smoothstep(0, 1000, float(worldTime));
      mieScat = mix(earlyMieScatterColor, mieScatterColor, time);
    }
    else if (worldTime >= 1000 && worldTime < 11500)
    {
      float time = smoothstep(10000, 11500, float(worldTime));
      mieScat = mix(mieScatterColor, lateMieScatterColor, time);
    }
    else if (worldTime >= 11500 && worldTime < 13000)
    {
      float time = smoothstep(12800, 13000, float(worldTime));
      mieScat =mix(lateMieScatterColor, nightMieScatterColor, time);
    }
    else if (worldTime >= 13000 && worldTime < 24000)
    {
      float time = smoothstep(23000, 24000, float(worldTime));
	    mieScat =mix(nightMieScatterColor,earlyMieScatterColor, time);
    }  
    bool inWater = isEyeInWater ==1.0;
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    float VoL = dot(normalize(feetPlayerPos), lightPos);
    if(rainStrength <= 1.0 && rainStrength > 0.0)
    {
      float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
      mieScat = mix(mieScat, mieScat *0.8, rainStrength);
    }
    if(inWater)
    {
      mieScat *=  MIE_SCALE * sunColor;
      mieScat *= HG(0.62, VoL);
    }
    
 
    mieScat *= HG(0.75, VoL);
    return mieScat;
}

#endif //SKY_COLOR_GLSL