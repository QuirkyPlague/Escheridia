#ifndef LIGHTING_GLSL
#define LIGHTING_GLSL 1 //[0 1]

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"

const vec3 blocklightColor = vec3(1.0, 0.9137, 0.8784) * 1.15;
const vec3 skylightColor = vec3(0.3255, 0.4157, 0.5216) * 3;
const vec3 nightSkylightColor = vec3(0.0, 0.1647, 1.0) * 3.2;
const vec3 sunlightColor = vec3(1.0, 0.7569, 0.4627) * 3.5;
const vec3 morningSunlightColor = vec3(1.0, 0.4431, 0.1412) * 3.5;
const vec3 eveningSunlightColor = vec3(1.0, 0.3529, 0.1216) * 2.4;
const vec3 moonlightColor = vec3(0.0941, 0.3333, 0.7843) * 3;
const vec3 rainSun = vec3(0.8353, 0.8353, 0.8353);



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
  float t = fract(worldTime / 24000.0);

  // Key times across the day (monotonic, last=1.0 == midnight wrap)
  //  0.000  = midnight
  //  0.0417 ~ 1000/24000 = sunrise band start
  //  0.2500 ~ 6000/24000 = day
  //  0.4792 ~ 11500/24000 = sunset band start
  //  0.5417 ~ 13000/24000 = dusk
  //  1.000  = midnight again

  const int K = 7;
  const float keyT[K] = float[K](
    0.0,
    0.0417,
    0.25,
    0.4792,
    0.5417,
    0.8417,
    1.0
  );

  //sunlight Keyframes
  const vec3 keySun[K] = vec3[K](
    morningSunlightColor,
    sunlightColor,
    sunlightColor,
    eveningSunlightColor,
    moonlightColor * 0.5,
    moonlightColor * 0.5,
    morningSunlightColor
  );

  //Skylight keyframes
  const float keyNight[K] = float[K](
    0.3, // midnight
    0.0, // sunrise
    0.0, // day
    0.4, // sunset
    1.0,
    1.0, // dusk
    0.3 // midnight
  );

  
  const float keySkyI[K] = float[K](
    0.5, // midnight
    0.65, // sunrise
    0.65, // day
    0.4, // sunset
    0.3,
    0.3, // dusk
    0.5 // midnight
  );

  // Rain “sun replacement” strength (you dimmed it near dusk/night)
  const float keyRainSunI[K] = float[K](
    0.2, // midnight
    1.0, // sunrise
    1.0, // day
    0.2, // sunset
    0.2,
    0.2, // dusk
    0.2 // midnight
  );

  int i = 0;
  // step(edge, x) returns 0.0 if x<edge, else 1.0
  // Accumulate how many key boundaries t has passed.
  for (int k = 0; k < K - 1; ++k) {
    i += int(step(keyT[k + 1], t));
  }
  i = clamp(i, 0, K - 2);

  // Local segment interpolation in [0..1]
  float segW = (t - keyT[i]) / max(1e-6, keyT[i + 1] - keyT[i]);
  segW = smoothstep(0.0, 1.0, segW);

  // Interpolate keyframes
  vec3 sunlightBase = mix(keySun[i], keySun[i + 1], segW);
  float nightFactor = mix(keyNight[i], keyNight[i + 1], segW);
  float skyI = mix(keySkyI[i], keySkyI[i + 1], segW);
  float rainSunI = mix(keyRainSunI[i], keyRainSunI[i + 1], segW);

  vec3 blocklight = lightmap.r * blocklightColor;

  // Skylight: blend day/night tints, then apply keyframed intensity
  vec3 skyTint = mix(skylightColor, nightSkylightColor, nightFactor);
  vec3 skylight = lightmap.g * skyTint * skyI;

  vec3 rainSkyTint = vec3(0.5412, 0.6235, 0.6667) * skyI;

  float hasSSS = step(64.0 / 255.0, sss); // 1 if sss >= threshold, else 0
  float VoL = dot(normalize(feetPlayerPos), sunPos);

  vec3 scatterSun = sunlightBase * (shadow * sss) * 4.0;
  vec3 SSSv = sunlightBase * (shadow * sss) * 2;
  scatterSun *= CS(SSS_HG, VoL);

  vec3 fullScatter = mix(SSSv, scatterSun, 0.5);
  vec3 sunlight = fullScatter * hasSSS;

  vec3 rainSunBase = vec3(0.8353, 0.8353, 0.8353) * rainSunI;
  vec3 rainScatter = fullScatter * 0.1;
  vec3 rainScatterFactor = mix(fullScatter, rainScatter, wetness);

  skylight = mix(skylight, lightmap.g * rainSkyTint, wetness);
  sunlight = mix(sunlight, rainSunBase, wetness);
  sunlight = mix(sunlight, rainScatterFactor, SSS_INTENSITY);

  blocklight += max(1.9 * pow(blocklight, vec3(4.8)), 0.0);
  blocklight += clamp(min(0.17 * pow(blocklight, vec3(0.8)), 5.2), 0.0, 1.0);

  vec3 ambientMood = vec3(0.7843, 0.7843, 0.7843);
  vec3 ambientColorLocal = vec3(0.251, 0.251, 0.251);
  vec3 ambient = mix(ambientColorLocal, ambientMood, moodSmooth);
  

  vec3 indirect = (blocklight + skylight) * ao;

  float metalMask = isMetal ? 1.0 : 0.0;
  indirect = mix(indirect, indirect * 0.5, metalMask);

  vec3 diffuse = sunlight + indirect + ambient;
  
  return diffuse;
}

vec3 currentSunColor(vec3 color) {
  // Normalize Minecraft time to [0.0, 1.0)
  float t = fract(worldTime / 24000.0);

  // Key times (fractions of day)
  const int K = 7;
  const float keyT[K] = float[K](
    0.0,
    0.0417,
    0.25,
    0.4792,
    0.5417,
    0.8417,
    1.0
  );
  const vec3 keySun[K] = vec3[K](
    morningSunlightColor,
    sunlightColor,
    sunlightColor,
    eveningSunlightColor,
    moonlightColor * 0.5,
    moonlightColor * 0.5,
    morningSunlightColor
  );

  vec3 keyRain[K] = vec3[K](
    rainSun,
    rainSun,
    rainSun,
    rainSun * 0.2,
    rainSun * 0.2,
    rainSun * 0.2,
    rainSun
  );

  int i = 0;
  for (int k = 0; k < K - 1; ++k) {
    i += int(step(keyT[k + 1], t));
  }
  i = clamp(i, 0, K - 2);

  // Interpolation within segment
  float segW = (t - keyT[i]) / max(1e-6, keyT[i + 1] - keyT[i]);
  segW = smoothstep(0.0, 1.0, segW);

  // Interpolate sun & rain colors
  vec3 baseColor = mix(keySun[i], keySun[i + 1], segW);
  vec3 rainBase = mix(keyRain[i], keyRain[i + 1], segW);

  // Apply wetness blending at the end
  return mix(baseColor, rainBase, wetness);
}

#endif //LIGHTING_GLSL
