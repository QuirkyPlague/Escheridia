#ifndef LIGHTING_GLSL
#define LIGHTING_GLSL

#include "/lib/atmosphere/atmosphereColors.glsl"

//lighting variables
const vec3 blocklightColor = vec3(1.0, 0.6275, 0.451);
const  vec3 skylightColor = vec3(0.0471, 0.0941, 0.1451);
vec3 sunlightColor= vec3(1.0, 0.749, 0.4627);
vec3 morningSunlightColor = vec3(0.9216, 0.4353, 0.2588);
 vec3 moonlightColor = vec3(0.102, 0.1569, 0.5098);
const vec3 nightSkyColor = vec3(0.0902, 0.1373, 0.6314);
 const vec3 morningSkyColor = vec3(0.7804, 0.5216, 0.2471);
 const vec3 ambientColor = vec3(0.0353, 0.0353, 0.0353);
vec3 duskSunlightColor = vec3(0.8784, 0.298, 0.2471);
vec3 duskSkyColor = vec3(0.8353, 0.3725, 0.302);


vec3 getDiffuse (vec2 texcoord, vec2 lightmap, vec3 normal, vec3 shadow, float ao)
{
  
  sunlightColor = sunlightColor * sunRGB(sunlightColor);
  morningSunlightColor = morningSunlightColor * sunRGB(morningSunlightColor);
  duskSunlightColor = duskSunlightColor * sunRGB(duskSunlightColor);
  moonlightColor = moonlightColor * moonRGB(moonlightColor);
  vec3 LightVector = normalize(shadowLightPosition);
  vec3 worldLightVector = mat3(gbufferModelViewInverse) * LightVector;
  vec3 diffuseLight;  
    //Time of day changes

     vec3 sunlight;
    
	   vec3 skylight;
	   vec3 blocklight = lightmap.r * blocklightColor * LIGHT_INTENSITY;
	  vec3 ambient = ambientColor;

if (worldTime >= 0 && worldTime < 1000)
  {
    //smoothstep equation allows interpolation between times of day
    float time = smoothstep(0, 1000, float(worldTime));
    sunlight = mix(morningSunlightColor * 0.4, sunlightColor, time) * clamp(dot(normal, worldLightVector * SUN_ILLUMINANCE), 0.0, 1.0) * shadow;
	  skylight = mix(morningSkyColor * 0.01, skylightColor, time) * lightmap.g * SKY_INTENSITY;
  }
   else if (worldTime >= 1000 && worldTime < 11500)
  {
     float time = smoothstep(10000, 11500, float(worldTime));
    sunlight = mix(sunlightColor * 2.3, duskSunlightColor* 0.4, time) * clamp(dot(normal, worldLightVector * SUN_ILLUMINANCE ), 0.0, 1.0)  * shadow;
	   skylight = mix(skylightColor, duskSkyColor * 0.6, time) * lightmap.g * SKY_INTENSITY;
	  
  }
  else if (worldTime >= 11500 && worldTime < 13000)
  {
     float time = smoothstep(11500, 13000, float(worldTime));
    sunlight = mix(duskSunlightColor* 0.4, moonlightColor, time) * clamp(dot(normal, worldLightVector * SUN_ILLUMINANCE), 0.0, 3.0) * shadow;
	   skylight = mix(duskSkyColor * 0.01, nightSkyColor * 0.2, time) * lightmap.g * SKY_INTENSITY;
	  
  }
   else if (worldTime >= 13000 && worldTime < 24000)
  {
    float time = smoothstep(23215, 24000, float(worldTime));
    sunlight = mix(moonlightColor, morningSunlightColor, time) * clamp(dot(normal, worldLightVector * MOON_ILLUMINANCE), 0.0, 3.0) * shadow;
	   skylight = mix(nightSkyColor * 0.6, morningSkyColor * 0.6, time) * lightmap.g * NIGHT_SKY_INTENSITY;
	  
  }
  //convert all lighting values into one value
	diffuseLight = sunlight + skylight + blocklight + ambient * ao;

return diffuseLight;
}

vec3 getCurrentSunlight(vec3 sunlight, vec3 normal,vec3 shadow, vec3 worldLightVector)
{
    if (worldTime >= 0 && worldTime < 1000)
  {
    //smoothstep equation allows interpolation between times of day
    float time = smoothstep(0, 1000, float(worldTime));
    sunlight = mix(morningSunlightColor * 0.4, sunlightColor, time) * clamp(dot(normal, worldLightVector * SUN_ILLUMINANCE), 0.0, 1.0) * shadow;
  } 
   else if (worldTime >= 1000 && worldTime < 11500)
  {
     float time = smoothstep(10000, 11500, float(worldTime));
    sunlight = mix(sunlightColor * 2.3, duskSunlightColor, time) * clamp(dot(normal, worldLightVector * SUN_ILLUMINANCE ), 0.0, 1.0)  * shadow;
	   
	  
  }
  else if (worldTime >= 11500 && worldTime < 13000)
  {
     float time = smoothstep(11500, 13000, float(worldTime));
    sunlight = mix(duskSunlightColor, moonlightColor, time) * clamp(dot(normal, worldLightVector * SUN_ILLUMINANCE), 0.0, 3.0) * shadow;
	   
	  
  }
   else if (worldTime >= 13000 && worldTime < 24000)
  {
    float time = smoothstep(23215, 24000, float(worldTime));
    sunlight = mix(moonlightColor, morningSunlightColor, time) * clamp(dot(normal, worldLightVector * MOON_ILLUMINANCE), 0.0, 3.0) * shadow;
  }
  return sunlight;
}


#endif