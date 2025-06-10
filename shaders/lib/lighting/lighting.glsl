#ifndef LIGHTING_GLSL
#define LIGHTING_GLSL 1 //[0 1]

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"
#include "/lib/atmosphere/skyColor.glsl"

const vec3 blocklightColor = vec3(0.9922, 0.7804, 0.5333) ;
const vec3 skylightColor = vec3(0.4902, 0.7608, 1.0);
const vec3 sunlightColor= vec3(1.0, 0.8078, 0.4471);
const vec3 morningSunlightColor = vec3(0.898, 0.6078, 0.3216);
const vec3 moonlightColor = vec3(0.1255, 0.3216, 0.6588);
const vec3 ambientColor = vec3(0.0706, 0.0706, 0.0706);
bool isNight = worldTime >= 13000 && worldTime < 24000;
bool isRaining = rainStrength <= 1.0 && rainStrength > 0.0;
vec3 doDiffuse(vec2 texcoord, vec2 lightmap, vec3 normal, vec3 sunPos, vec3 shadow, vec3 viewPos)
{
    vec3 blocklight = lightmap.r * blocklightColor;
    vec3 skylight = lightmap.g * skylightColor;
    vec3 ambient = ambientColor;
    vec3 sunlight;
    
  if (worldTime >= 0 && worldTime < 1000)
  {
    //smoothstep equation allows interpolation between times of day
    float time = smoothstep(0, 1000, float(worldTime));
    sunlight = mix(morningSunlightColor * 1.3, sunlightColor, time) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;
    skylight *= mix(0.3, 0.4, time);
  }
   else if (worldTime >= 1000 && worldTime < 11500)
  {
     float time = smoothstep(10000, 11500, float(worldTime));
    sunlight = mix(sunlightColor * 1.25, morningSunlightColor* 0.4, time) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;
	
    skylight *= mix(0.4, 0.2, time);
  }
  else if (worldTime >= 11500 && worldTime < 13000)
  {
     float time = smoothstep(11500, 13000, float(worldTime));
    sunlight = mix(morningSunlightColor, moonlightColor * 0.4, time) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;
	  skylight *= 0.2;
  }
   else if (worldTime >= 13000 && worldTime < 24000)
  {
    float time = smoothstep(23215, 24000, float(worldTime));
    sunlight = mix(moonlightColor * 0.4 , morningSunlightColor, time) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;
	  skylight *= 0.15;
	  
  }
    if(isRaining)
  {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    vec3 currentSunlight = sunlight;
    vec3 rainSun = vec3(1.3);
    vec3 rainSkylight = lightmap.g * vec3(0.6);
   if(isNight)
   {
    rainSun *= 0.3;
    rainSkylight *= 0.3;
   }
    sunlight = mix(currentSunlight, rainSun * 0.3, dryToWet) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;
    vec3 currentSkylight = skylight;
    
    skylight = mix(currentSkylight, rainSkylight * 0.2, dryToWet) * lightmap.g;

  }
   

    vec3 diffuse =  ambient+ blocklight+ skylight + sunlight;
    return diffuse;
}

vec3 getCurrentSunlight(vec3 sunlight, vec3 normal,vec3 shadow, vec3 sunPos)
{
     if (worldTime >= 0 && worldTime < 1000)
  {
    //smoothstep equation allows interpolation between times of day
    float time = smoothstep(0, 1000, float(worldTime));
    sunlight = mix(morningSunlightColor * 1.3, sunlightColor, time) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;
  }
   else if (worldTime >= 1000 && worldTime < 11500)
  {
     float time = smoothstep(10000, 11500, float(worldTime));
    sunlight = mix(sunlightColor * 1.4, morningSunlightColor* 0.4, time) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;;
  }
  else if (worldTime >= 11500 && worldTime < 13000)
  {
     float time = smoothstep(11500, 13000, float(worldTime));
    sunlight = mix(morningSunlightColor, moonlightColor * 0.1, time) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;;
  }
   else if (worldTime >= 13000 && worldTime < 24000)
  {
    float time = smoothstep(23215, 24000, float(worldTime));
    sunlight = mix(moonlightColor * 0.1 , morningSunlightColor, time) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;;
	  
  }
  if(isRaining)
  {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    vec3 currentSunlight = sunlight;
    vec3 rainSun = vec3(0.3);
   if(isNight)
   {
    rainSun *= 0.03;
   }
    sunlight = mix(currentSunlight, rainSun * 0.3, dryToWet) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;
   

  }
    return sunlight;
}

#endif //LIGHTING_GLSL
