#ifndef LIGHTING_GLSL
#define LIGHTING_GLSL 1 //[0 1]

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"



const vec3 blocklightColor = vec3(1.0, 0.9725, 0.9216) * 1.2;
const vec3 skylightColor = vec3(0.5412, 0.6314, 0.9961) * 2;
const vec3 nightSkylightColor = vec3(0.0863, 0.2196, 0.898) * 1.2;
const vec3 sunlightColor= vec3(1.0, 0.7333, 0.4275) * 5.3;
const vec3 morningSunlightColor = vec3(0.9882, 0.4902, 0.1804)* 6.3;
const vec3 eveningSunlightColor = vec3(1.0, 0.4078, 0.3059) * 2.4;
const vec3 moonlightColor = vec3(0.1176, 0.2941, 0.6235) * 3;
vec3 ambientColor = vec3(0.2235, 0.2235, 0.2235) + moodSmooth;



vec3 doDiffuse(vec2 texcoord, vec2 lightmap, vec3 normal, vec3 sunPos, vec3 shadow, vec3 viewPos, float sss, vec3 feetPlayerPos, bool isMetal, float ao)
{
    vec3 blocklight = lightmap.r * blocklightColor;
    vec3 skylight = lightmap.g * skylightColor;
    vec3 scatterSun;
    vec3 SSS;
    vec3 fullScatter;
    vec3 sunlight;
    float VoL = dot(normalize(feetPlayerPos), sunPos);
  if (worldTime >= 0 && worldTime < 1000)
  {
    //smoothstep equation allows interpolation between times of day
    float time = smoothstep(0, 1000, float(worldTime));
      if(sss > 64.0/255.0)
    {
      
      scatterSun = mix(morningSunlightColor, sunlightColor, time) *  (shadow );
      SSS = mix(morningSunlightColor, sunlightColor, time) *  (shadow);
      scatterSun*= HG(SSS_HG, VoL);
      fullScatter = mix(SSS,scatterSun, 0.5) * 2;
      sunlight = mix(sunlight, fullScatter, SSS_INTENSITY);
    }
    
    skylight *= mix(0.8, 1.0, time);
  }
   else if (worldTime >= 1000 && worldTime < 11500)
  {
     float time = smoothstep(10000, 11500, float(worldTime));
     
    if(sss > 64.0/255.0)
    {

      scatterSun = mix(sunlightColor, eveningSunlightColor, time) *  (shadow * sss );
      SSS = mix(sunlightColor, eveningSunlightColor, time) *  (shadow * sss);
      scatterSun*= HG(SSS_HG, VoL);
      fullScatter = mix(SSS,scatterSun, 0.5) * 2;
      sunlight = mix(sunlight, fullScatter, SSS_INTENSITY);
    }
    skylight *= mix(1.1, 1.0, time); 
  }
  else if (worldTime >= 11500 && worldTime < 13000)
  {
     float time = smoothstep(12800, 13000, float(worldTime));
      if(sss > 64.0/255.0)
    {
      scatterSun =  mix(eveningSunlightColor, moonlightColor , time) *  (shadow * sss );
      SSS = mix(eveningSunlightColor, moonlightColor , time) *  (shadow * sss);
      scatterSun*= HG(SSS_HG, VoL);
      fullScatter = mix(SSS,scatterSun, 0.5) * 2;
      sunlight = mix(sunlight, fullScatter, SSS_INTENSITY);
    }
	  skylight *= 0.7;
  }
   else if (worldTime >= 13000 && worldTime < 24000)
  {
    float time = smoothstep(23250, 24000, float(worldTime));
    if(sss > 64.0/255.0)
    {
      scatterSun = mix(moonlightColor , morningSunlightColor, time) *   (shadow * sss ) * 0.2;
      SSS = mix(moonlightColor , morningSunlightColor, time) *  (shadow * sss);
      scatterSun*= HG(SSS_HG, VoL);
      fullScatter = mix(SSS,scatterSun, 0.5) * 2;
      sunlight = mix(sunlight, fullScatter, SSS_INTENSITY);
    }
	  skylight = lightmap.g * nightSkylightColor;
	  
  }
    if(isRaining)
  {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    vec3 currentSunlight = sunlight;
    vec3 rainSun = vec3(0.8353, 0.8353, 0.8353);
    vec3 rainSkylight = lightmap.g * vec3(0.7412, 0.8235, 0.8667);
    vec3 rainScatter = fullScatter * 0.1;
    vec3 rainScatterFactor = mix(fullScatter, rainScatter, dryToWet);
   if(isNight)
   {
    rainSun *= 0.1;
    rainSkylight *= 0.1;
   }
    vec3 currentSkylight = skylight;
    
    skylight = mix(currentSkylight, rainSkylight, dryToWet) * lightmap.g;
    sunlight = mix(currentSunlight, rainSun, dryToWet);
    sunlight = mix(sunlight, rainScatterFactor, SSS_INTENSITY);
  }
  
   blocklight += max(0.9 * pow(blocklight, vec3(12.8)), 0.0);
   blocklight += min(0.17 * pow(blocklight, vec3(1.8)), 0.2);

   
   
   vec3 ambientMood = vec3(0.6157, 0.6157, 0.6157);
    vec3 ambient = mix(ambientColor, ambientMood * 1.2, moodSmooth);
    float lightmapSmooth = smoothstep( 1.0,0.515, lightmap.g);
    vec3 indirect =  ambient+ blocklight+ skylight;
    indirect *= ao;
    vec3 diffuse = sunlight;
    diffuse += indirect;
   
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
    sunlight = mix(morningSunlightColor, sunlightColor, time) * shadow;
   
  }
   else if (worldTime >= 1000 && worldTime < 11500)
  {
     float time = smoothstep(10000, 11500, float(worldTime));
     sunlight = mix(sunlightColor, eveningSunlightColor, time)  * shadow;
  }
  else if (worldTime >= 11500 && worldTime < 13000)
  {
     float time = smoothstep(12800, 13000, float(worldTime));
    sunlight = mix(eveningSunlightColor, moonlightColor * 0.4, time) * shadow;

  }
   else if (worldTime >= 13000 && worldTime < 24000)
  {
    float time = smoothstep(23250, 24000, float(worldTime));
    sunlight = mix(moonlightColor , morningSunlightColor, time)  * shadow;

	
  }
  if(isRaining)
  {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    vec3 currentSunlight = sunlight;
    vec3 rainSun = vec3(1.0, 1.0, 1.0) * 2 ;
   if(isNight)
   {
    rainSun *= 0.03;
   }
    sunlight = mix(currentSunlight, rainSun, dryToWet)  * shadow;
   

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
    color = mix(morningSunlightColor * 0.3, sunlightColor * 0.23, time);
  }
   else if (worldTime >= 1000 && worldTime < 11500)
  {
     float time = smoothstep(10000, 11500, float(worldTime));
    color = mix(sunlightColor * 0.3, eveningSunlightColor * 1.5, time);
  }
  else if (worldTime >= 11500 && worldTime < 13000)
  {
     float time = smoothstep(12800, 13000, float(worldTime));
    color = mix(eveningSunlightColor * 0.4, moonlightColor * 0.2 , time);
  }
   else if (worldTime >= 13000 && worldTime < 24000)
  {
    float time = smoothstep(21000, 24000, float(worldTime));
    color = mix(moonlightColor * 0.1  , morningSunlightColor* 1.5, time);
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
    color = mix(currentSunlight, rainSun, dryToWet);
  
  }
  return color;
  }
  
  
#endif //LIGHTING_GLSL
