#ifndef LIGHTING_GLSL
#define LIGHTING_GLSL 1 //[0 1]

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"

const vec3 blocklightColor = vec3(1.0, 0.9294, 0.8392) * 1.2;
const vec3 skylightColor = vec3(0.5137, 0.6118, 1.0) * 3.5;
const vec3 nightSkylightColor = vec3(0.0863, 0.2196, 0.898) * 2.2;
const vec3 sunlightColor = vec3(1.0, 0.8549, 0.4196) * 6.3;
const vec3 morningSunlightColor = vec3(0.9882, 0.4902, 0.1804) * 5.3;
const vec3 eveningSunlightColor = vec3(0.9882, 0.3333, 0.098) * 5.4;
const vec3 moonlightColor = vec3(0.1608, 0.4118, 0.8824) * 3;
vec3 ambientColor = vec3(0.3216, 0.3216, 0.3216);
vec3 rainSun = vec3(0.8353, 0.8353, 0.8353);

vec3 doDiffuse(
  vec2 texcoord,
  vec2 lightmap,
  vec3 normal,
  vec3 sunPos,
  vec3 shadow,
  vec3 viewPos,
  float sss,
  vec3 feetPlayerPos,
  bool isMetal,
  float ao
) {
  vec3 blocklight = lightmap.r * blocklightColor;
  vec3 skylight = lightmap.g * skylightColor;
  const vec3 nightSkylight = lightmap.g * nightSkylightColor;
  vec3 rainSkylight = lightmap.g * vec3(0.5412, 0.6235, 0.6667);
  vec3 scatterSun;
  vec3 SSS;
  vec3 fullScatter;
  vec3 sunlight;
  float VoL = dot(normalize(feetPlayerPos), sunPos);
  if (worldTime >= 0 && worldTime < 1000) {
    //smoothstep equation allows interpolation between times of day
    float time = smoothstep(0, 1000, float(worldTime));
    if (sss > 64.0 / 255.0) {
      scatterSun = mix(morningSunlightColor, sunlightColor, time) * shadow * 2;
      SSS = mix(morningSunlightColor, sunlightColor, time) * shadow * 3;
      scatterSun *= CS(SSS_HG, VoL);
      fullScatter = mix(SSS, scatterSun, 0.5);
      sunlight = mix(sunlight, fullScatter, SSS_INTENSITY);
    }

    skylight *= mix(0.5, 0.7, time);
  } else if (worldTime >= 1000 && worldTime < 6000) {
    float time = smoothstep(2500, 4000, float(worldTime));

    if (sss > 64.0 / 255.0) {
      scatterSun = mix(sunlightColor, sunlightColor, time) * (shadow * sss) * 2;
      SSS = mix(sunlightColor, sunlightColor, time) * (shadow * sss) * 1.25;
      scatterSun *= CS(SSS_HG, VoL);
      fullScatter = mix(SSS, scatterSun, 0.5) * 2;
      fullScatter = mix(fullScatter, fullScatter * 0.7, time);
      sunlight = mix(sunlight, fullScatter, SSS_INTENSITY);
    }
    skylight *= mix(0.67, 0.4, time);
  } else if (worldTime >= 6000 && worldTime < 11500) {
    float time = smoothstep(10000, 11500, float(worldTime));

    if (sss > 64.0 / 255.0) {
      scatterSun =
        mix(sunlightColor, eveningSunlightColor, time) * (shadow * sss) * 2;
      SSS =
        mix(sunlightColor, eveningSunlightColor, time) * (shadow * sss) * 1.25;
      scatterSun *= CS(SSS_HG, VoL);
      fullScatter = mix(SSS, scatterSun, 0.5) * 2;
      fullScatter = mix(fullScatter * 0.65, fullScatter, time);
      sunlight = mix(sunlight, fullScatter, SSS_INTENSITY);
    }
    skylight *= mix(0.7, 0.4, time);
  } else if (worldTime >= 11500 && worldTime < 13000) {
    float time = smoothstep(12800, 13000, float(worldTime));
    if (sss > 64.0 / 255.0) {
      scatterSun =
        mix(eveningSunlightColor, moonlightColor, time) * (shadow * sss) * 2;
      SSS = mix(eveningSunlightColor, moonlightColor, time) * (shadow * sss);
      scatterSun *= CS(SSS_HG, VoL);
      fullScatter = mix(SSS, scatterSun, 0.5);
      sunlight = mix(sunlight, fullScatter, SSS_INTENSITY);
      rainSun = mix(rainSun, rainSun * 0.2, time);

    }
    skylight = mix(skylight * 0.4, nightSkylight, time);
    rainSkylight = mix(rainSkylight, rainSkylight * 0.1, time);
  } else if (worldTime >= 13000 && worldTime < 24000) {
    float time = smoothstep(23250, 24000, float(worldTime));
    if (sss > 64.0 / 255.0) {
      scatterSun =
        mix(moonlightColor, morningSunlightColor, time) * (shadow * sss) * 2;
      SSS = mix(moonlightColor, morningSunlightColor, time) * (shadow * sss);
      scatterSun *= CS(SSS_HG, VoL);
      fullScatter = mix(SSS, scatterSun, 0.5);
      sunlight = mix(sunlight, fullScatter, SSS_INTENSITY);
      rainSun = mix(rainSun * 0.2, rainSun, time);

    }
    skylight = mix(nightSkylight, skylight, time);
    rainSkylight = mix(rainSkylight * 0.1, rainSkylight, time);
  }

  vec3 rainScatter = fullScatter * 0.1;
  vec3 rainScatterFactor = mix(fullScatter, rainScatter, wetness);

  skylight = mix(skylight, rainSkylight, wetness);
  sunlight = mix(sunlight, rainSun, wetness);
  sunlight = mix(sunlight, rainScatterFactor, SSS_INTENSITY);

  blocklight += max(1.9 * pow(blocklight, vec3(4.8)), 0.0);
  blocklight += clamp(min(0.17 * pow(blocklight, vec3(0.8)), 5.2), 0, 1);

  vec3 ambientMood = vec3(0.6157, 0.6157, 0.6157);
  vec3 ambient = mix(ambientColor, ambientMood, moodSmooth);
  float lightmapSmooth = smoothstep(1.0, 0.515, lightmap.g);
  vec3 indirect = blocklight + skylight;
  indirect *= ao;
  if (isMetal) {
    indirect *= 0.5;
  }
  indirect += ambient;
  vec3 diffuse = sunlight;
  diffuse += indirect;

  return diffuse;
}

vec3 currentSunColor(vec3 color) {
  if (worldTime >= 0 && worldTime < 1000) {
    //smoothstep equation allows interpolation between times of day
    float time = smoothstep(0, 1000, float(worldTime));
    color = mix(morningSunlightColor, sunlightColor, time);
  } else if (worldTime >= 1000 && worldTime < 11500) {
    float time = smoothstep(10000, 11500, float(worldTime));
    color = mix(sunlightColor, eveningSunlightColor, time);
  } else if (worldTime >= 11500 && worldTime < 13000) {
    float time = smoothstep(12800, 13000, float(worldTime));
    color = mix(eveningSunlightColor, moonlightColor, time);
    rainSun = mix(rainSun, rainSun * 0.2, time);
  } else if (worldTime >= 13000 && worldTime < 24000) {
    float time = smoothstep(22500, 24000, float(worldTime));
    color = mix(moonlightColor * 0.5, morningSunlightColor, time);
    rainSun = mix(rainSun * 0.2, rainSun, time);
  }

  color = mix(color, rainSun, wetness);

  return color;
}

#endif //LIGHTING_GLSL
