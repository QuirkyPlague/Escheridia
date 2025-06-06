#ifndef LIGHTING_GLSL
#define LIGHTING_GLSL 1 //[0 1]

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"
#include "/lib/atmosphere/skyColor.glsl"

const vec3 blocklightColor = vec3(1.0, 0.8667, 0.6235) * 0.8;
vec3 skylightColor;
const vec3 sunlightColor= vec3(1.0, 0.8275, 0.5098);
const vec3 morningSunlightColor = vec3(0.9216, 0.4353, 0.2588);
const vec3 moonlightColor = vec3(0.1255, 0.3216, 0.6588);
const vec3 ambientColor = vec3(0.1);
 bool isNight = worldTime >= 13000 && worldTime < 24000;

vec3 doDiffuse(vec2 texcoord, vec2 lightmap, vec3 normal, vec3 sunPos, vec3 shadow)
{
    vec3 blocklight = lightmap.r * blocklightColor;
    vec3 skylight = lightmap.g * calcSkyColor(skylightColor) * 0.5;
    vec3 ambient = ambientColor;
    vec3 sunlight;
  if (worldTime >= 0 && worldTime < 1000)
  {
    //smoothstep equation allows interpolation between times of day
    float time = smoothstep(0, 1000, float(worldTime));
    sunlight = mix(morningSunlightColor, sunlightColor, time) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;
    skylight *= mix(0.1, 0.5, time);
  }
   else if (worldTime >= 1000 && worldTime < 11500)
  {
     float time = smoothstep(10000, 11500, float(worldTime));
    sunlight = mix(sunlightColor , morningSunlightColor* 0.4, time) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;;
	  skylight *= mix(0.3, 0.3, time);
  }
  else if (worldTime >= 11500 && worldTime < 13000)
  {
     float time = smoothstep(11500, 13000, float(worldTime));
    sunlight = mix(morningSunlightColor, moonlightColor * 0.8, time) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;;
	  skylight *= 0.3;
  }
   else if (worldTime >= 13000 && worldTime < 24000)
  {
    float time = smoothstep(23215, 24000, float(worldTime));
    sunlight = mix(moonlightColor * 0.8 , morningSunlightColor, time) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;;
	  skylight *= 0.3;
	  
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
    sunlight = mix(morningSunlightColor, sunlightColor, time) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;
  }
   else if (worldTime >= 1000 && worldTime < 11500)
  {
     float time = smoothstep(10000, 11500, float(worldTime));
    sunlight = mix(sunlightColor , morningSunlightColor* 0.4, time) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;;
  }
  else if (worldTime >= 11500 && worldTime < 13000)
  {
     float time = smoothstep(11500, 13000, float(worldTime));
    sunlight = mix(morningSunlightColor, moonlightColor * 0.8, time) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;;
  }
   else if (worldTime >= 13000 && worldTime < 24000)
  {
    float time = smoothstep(23215, 24000, float(worldTime));
    sunlight = mix(moonlightColor * 0.8 , morningSunlightColor, time) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;;
	  
  }
    return sunlight;
}

#endif //LIGHTING_GLSL
