#ifndef LIGHTING_GLSL
#define LIGHTING_GLSL 1 //[0 1]

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"



  const vec3 blocklightColor = vec3(1.0, 0.8941, 0.7255);
const vec3 skylightColor = vec3(0.4706, 0.549, 0.8863);
const vec3 nightSkylightColor = vec3(0.0588, 0.1686, 0.7255);
const vec3 sunlightColor= vec3(0.9843, 0.8667, 0.7922);
const vec3 morningSunlightColor = vec3(1.0, 0.6431, 0.4235)* 1.35;
const vec3 eveningSunlightColor = vec3(1.0, 0.4078, 0.3059) * 1.4;
const vec3 moonlightColor = vec3(0.1176, 0.2941, 0.6235);
vec3 ambientColor = vec3(0.1804, 0.1804, 0.1804);

const bool isNight = worldTime >= 13000 && worldTime < 23000;
const bool isRaining = rainStrength <= 1.0 && rainStrength > 0.0;

vec3 doDiffuse(vec2 texcoord, vec2 lightmap, vec3 normal, vec3 sunPos, vec3 shadow, vec3 viewPos, float sss, vec3 feetPlayerPos, bool isMetal)
{
    vec3 blocklight = lightmap.r * blocklightColor;
    vec3 skylight = lightmap.g * skylightColor;
    
    vec3 sunlight;
  
  if (worldTime >= 0 && worldTime < 1000)
  {
    //smoothstep equation allows interpolation between times of day
    float time = smoothstep(0, 1000, float(worldTime));
   
    sunlight = mix(morningSunlightColor, sunlightColor, time) * clamp(max(dot(normal, sunPos),0), 0.0, 1.0) * shadow;
      if(sss > 64.0/255.0)
    {
      float VoL = dot(normalize(feetPlayerPos), sunPos);
      
      vec3 scatterSun = mix(morningSunlightColor, sunlightColor, time) *  (shadow );
      vec3 SSS = mix(morningSunlightColor, sunlightColor, time) *  (shadow);
      scatterSun*= HG(SSS_HG, VoL);
      vec3 fullScatter = mix(SSS * 3,scatterSun, 0.4);
      sunlight = mix(sunlight, fullScatter, SSS_INTENSITY);
    }
    
    skylight *= mix(0.75, 1.0, time);
  }
   else if (worldTime >= 1000 && worldTime < 11500)
  {
     float time = smoothstep(10000, 11500, float(worldTime));
     sunlight = mix(sunlightColor , morningSunlightColor, time) * clamp((dot(normal, sunPos)), 0.0, 1.0) * shadow;
    if(sss > 64.0/255.0)
    {
      float VoL = dot(normalize(feetPlayerPos), sunPos);
      
      vec3 scatterSun = mix(sunlightColor, eveningSunlightColor, time) *  (shadow * sss );
      vec3 SSS = mix(sunlightColor, eveningSunlightColor, time) *  (shadow * sss);
      scatterSun*= HG(SSS_HG, VoL);
      vec3 fullScatter = mix(SSS * 3,scatterSun, 0.4);
      sunlight = mix(sunlight, fullScatter, SSS_INTENSITY);
    }
    skylight *= mix(1.0, 1.0, time); 
    
  }
  else if (worldTime >= 11500 && worldTime < 13000)
  {
     float time = smoothstep(12800, 13000, float(worldTime));
    sunlight = mix(eveningSunlightColor, moonlightColor, time) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;
      if(sss > 64.0/255.0)
    {
      float VoL = dot(normalize(feetPlayerPos), sunPos);
      
      
      vec3 scatterSun =  mix(eveningSunlightColor, moonlightColor , time) *  (shadow * sss );
      vec3 SSS = mix(eveningSunlightColor, moonlightColor , time) *  (shadow * sss);
      scatterSun*= HG(SSS_HG, VoL);
      vec3 fullScatter = mix(SSS * 3,scatterSun, 0.4);
      sunlight = mix(sunlight, fullScatter, SSS_INTENSITY);
    }
	  skylight *= 0.7;
  }
   else if (worldTime >= 13000 && worldTime < 24000)
  {
    float time = smoothstep(23250, 24000, float(worldTime));
    sunlight = mix(moonlightColor , morningSunlightColor, time) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;
    if(sss > 64.0/255.0)
    {
      float VoL = dot(normalize(feetPlayerPos), sunPos);
      
     
      vec3 scatterSun = mix(moonlightColor , morningSunlightColor, time) *   (shadow * sss ) * 0.2;
      vec3 SSS = mix(moonlightColor , morningSunlightColor, time) *  (shadow * sss);
      scatterSun*= HG(SSS_HG, VoL);
      vec3 fullScatter = mix(SSS * 3 ,scatterSun, 0.4);
      sunlight = mix(sunlight, fullScatter, SSS_INTENSITY);
    }
	  skylight = lightmap.g * nightSkylightColor;
	  
  }
    if(isRaining)
  {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    vec3 currentSunlight = sunlight;
    vec3 rainSun = vec3(0.4118, 0.4118, 0.4118);
    vec3 rainSkylight = lightmap.g * vec3(0.1765, 0.1765, 0.1765);
   if(isNight)
   {
    rainSun *= 0.1;
    rainSkylight *= 0.1;
   }
    sunlight = mix(currentSunlight, rainSun, dryToWet) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;
    vec3 currentSkylight = skylight;
    
    skylight = mix(currentSkylight, rainSkylight, dryToWet) * lightmap.g;

  }
  
   blocklight += max(0.7 * pow(blocklight, vec3(4.8)), 0.1);
   blocklight += min(0.17 * pow(blocklight, vec3(6.8)), 0.8);
   blocklight *= smoothstep(0.0, 0.712, blocklight);
   
   
   
    const vec3 ambient = ambientColor;
    float lightmapSmooth = smoothstep( 1.0,0.515, lightmap.g);
    vec3 diffuse =  ambient+ blocklight+ skylight + sunlight;
    if(isMetal && lightmap.g != lightmapSmooth)
  {
    diffuse *= 0.5;
  }
    return diffuse;
}

vec3 getCurrentSunlight(vec3 sunlight, vec3 normal,vec3 shadow, vec3 sunPos, float sss, vec3 feetPlayerPos, bool isWater)
{
  if(!isWater)
  {
    if (worldTime >= 0 && worldTime < 1000)
  {
    //smoothstep equation allows interpolation between times of day
    float time = smoothstep(0, 1000, float(worldTime));
    sunlight = mix(morningSunlightColor, sunlightColor, time) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;
      if(sss > 64.0/255.0)
    {
      float VoL = dot(normalize(feetPlayerPos), sunPos);
      
      vec3 scatterSun = mix(morningSunlightColor, sunlightColor, time) *  (shadow * sss);
      scatterSun*= HG(SSS_HG, VoL);
      sunlight = mix(sunlight, scatterSun, SSS_INTENSITY);
    }
  }
   else if (worldTime >= 1000 && worldTime < 11500)
  {
     float time = smoothstep(10000, 11500, float(worldTime));
     sunlight = mix(sunlightColor, morningSunlightColor* 0.7, time) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;
    if(sss > 64.0/255.0)
    {
      float VoL = dot(normalize(feetPlayerPos), sunPos);
      
      vec3 scatterSun = mix(sunlightColor, morningSunlightColor* 0.7, time) * (shadow * sss);
      scatterSun*= HG(SSS_HG, VoL);
      sunlight = mix(sunlight, scatterSun, SSS_INTENSITY);
    }
  }
  else if (worldTime >= 11500 && worldTime < 13000)
  {
     float time = smoothstep(11500, 13000, float(worldTime));
    sunlight = mix(morningSunlightColor * 1.1, moonlightColor * 0.4, time) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;
      if(sss > 64.0/255.0)
    {
      float VoL = dot(normalize(feetPlayerPos), sunPos);
      
      vec3 scatterSun = mix(morningSunlightColor * 1.1, moonlightColor * 0.4, time) * (shadow * sss);
      scatterSun*= HG(SSS_HG, VoL);
      sunlight = mix(sunlight, scatterSun, SSS_INTENSITY);
    }
  }
   else if (worldTime >= 13000 && worldTime < 24000)
  {
    float time = smoothstep(23250, 24000, float(worldTime));
    sunlight = mix(moonlightColor * 0.7 , morningSunlightColor, time) * clamp(dot(normal, sunPos), 0.0, 1.0) * shadow;
    if(sss > 64.0/255.0)
    {
      float VoL = dot(normalize(feetPlayerPos), sunPos);
      
      vec3 scatterSun = mix(moonlightColor * 0.3 , morningSunlightColor, time) * (shadow * sss);
      scatterSun*= HG(SSS_HG, VoL);
      sunlight = mix(sunlight, scatterSun, SSS_INTENSITY);
    }
	
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
  }
     
    return sunlight;
}

vec3 currentSunColor(vec3 color)
{
   if (worldTime >= 0 && worldTime < 1000)
  {
    //smoothstep equation allows interpolation between times of day
    float time = smoothstep(0, 1000, float(worldTime));
    color = mix(morningSunlightColor * 1.5, sunlightColor, time);
  }
   else if (worldTime >= 1000 && worldTime < 11500)
  {
     float time = smoothstep(10000, 11500, float(worldTime));
    color = mix(sunlightColor, morningSunlightColor * 1.5, time);
  }
  else if (worldTime >= 11500 && worldTime < 13000)
  {
     float time = smoothstep(11500, 13000, float(worldTime));
    color = mix(morningSunlightColor * 1.5, moonlightColor * 0.2 , time);
  }
   else if (worldTime >= 13000 && worldTime < 24000)
  {
    float time = smoothstep(21000, 24000, float(worldTime));
    color = mix(moonlightColor * 0.3  , morningSunlightColor* 1.5, time);
  }
  if(isRaining)
  {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    vec3 currentSunlight = color;
    vec3 rainSun = vec3(0.7255, 0.7255, 0.7255);
   if(isNight)
   {
    rainSun *= 0.03;
   }
    color = mix(currentSunlight, rainSun * 0.3, dryToWet);
  
  }
  return color;
  }
  
  vec3 currentSkylight(vec2 lightmap)
  {
    vec3 skylight = lightmap.g * skylightColor;
  if (worldTime >= 0 && worldTime < 1000)
  {
    //smoothstep equation allows interpolation between times of day
    float time = smoothstep(0, 1000, float(worldTime));
    skylight *= mix(0.53, 0.63, time);
  }
   else if (worldTime >= 1000 && worldTime < 11500)
  {
    float time = smoothstep(10000, 11500, float(worldTime));
    skylight *= mix(0.63, 0.4, time);
  }
  else if (worldTime >= 11500 && worldTime < 13000)
  {
	  skylight *= 0.4;
  }
   else if (worldTime >= 13000 && worldTime < 24000)
  {
	  skylight *= 0.35;
  }
    if(isRaining)
  {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    vec3 rainSkylight = lightmap.g * vec3(0.1765, 0.1765, 0.1765);
   if(isNight)
   {
    rainSkylight *= 0.3;
   }
    vec3 currentSkylight = skylight;
    skylight = mix(currentSkylight, rainSkylight, dryToWet) * lightmap.g;
  }
    return skylight;
  }


#endif //LIGHTING_GLSL
