#ifndef LIGHTING_GLSL
#define LIGHTING_GLSL 1 //[0 1]

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"
#include "/lib/phaseFunctions.glsl"

const vec3 blocklightColor = vec3(1.0, 0.7961, 0.5451);
const vec3 skylightColor = vec3(0.6, 0.6824, 0.898);
const vec3 paleSkyColor = vec3(0.6314, 0.6314, 0.6314);
const vec3 nightSkylightColor = vec3(0.0667, 0.149, 0.5686) ;
const vec3 sunlightColor = vec3(1.0, 0.8784, 0.6353);
const vec3 morningSunlightColor = vec3(1.0, 0.4824, 0.1373);
const vec3 eveningSunlightColor = vec3(1.0, 0.298, 0.1216) * 1.16;
const vec3 moonlightColor = vec3(0.2353, 0.3451, 0.8824);
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
  vec3 shadowScreenPos,
  vec3 albedo,
  float ao
) {
  float t = fract(worldTime / 24000.0);

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
    moonlightColor,
    moonlightColor,
    morningSunlightColor
  );
    //sunlight Keyframes
  const vec3 keySky[K] = vec3[K](
    skylightColor,
    skylightColor,
    skylightColor,
    skylightColor,
    nightSkylightColor,
    nightSkylightColor,
    skylightColor
  );

  const float keySkyI[K] = float[K](
    0.741, // midnight
    0.9, // sunrise
    0.9, // day
    0.25, // sunset
    0.86,
    0.86, // dusk
    0.75 // midnight
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
  vec3 paleSky = mix(keySky[i], paleSkyColor, PaleGardenSmooth);
  vec3 sunlightBase = mix(keySun[i], keySun[i + 1], segW);
  vec3 skylightShift = mix(keySky[i], keySky[i + 1], segW);
  skylightShift = mix(skylightShift, paleSky, PaleGardenSmooth);
  float skyI = mix(keySkyI[i], keySkyI[i + 1], segW);
  float rainSunI = mix(keyRainSunI[i], keyRainSunI[i + 1], segW);

  vec3 blocklight = lightmap.r * blocklightColor;

  // Skylight: blend day/night tints, then apply keyframed intensity

  vec3 skylight = lightmap.g * skylightShift * skyI;

  vec3 rainSkyTint = vec3(0.5412, 0.6235, 0.6667) * skyI;

  float hasSSS = step(64.0 / 255.0, sss); 
  float VoL = dot(normalize(feetPlayerPos), sunPos);

  vec3 scatterSun = sunlightBase * (shadow * sss);
  vec3 SSSv = sunlightBase * (shadow * sss) ;
  scatterSun *= mix(CS(0.65, VoL) * 5, henyeyGreensteinPhase(VoL, -0.15), 1.0 - clamp(VoL, 0,1)) ;

  vec3 fullScatter = (SSSv + scatterSun) * 3.5;
  vec3 sunlight = fullScatter * hasSSS;

  vec3 rainSunBase = vec3(0.8353, 0.8353, 0.8353) * rainSunI;
  vec3 rainScatter = fullScatter * 0.1;
  vec3 rainScatterFactor = mix(fullScatter, rainScatter, wetness);

  skylight = mix(skylight, lightmap.g * rainSkyTint, wetness);
  
  skylight += max(5.95 * pow(skylight, vec3(2.55)), 0.0);
 
  skylight *= min(1.07 * pow(skylight, vec3(0.1)), 0.67);
  
  
  
  sunlight = mix(sunlight, rainSunBase, wetness);
  sunlight = mix(sunlight, rainScatterFactor, SSS_INTENSITY);
  
   blocklight += max(4.9 * pow(blocklight, vec3(0.75)), 0.0);
   blocklight *= 1.55;
  blocklight *= clamp(min(0.17 * pow(blocklight, vec3(0.8)), 5.2), 0.0, 1.0) ;

  vec3 ambientMood = vec3(0.8392, 0.8392, 0.8392);
  vec3 ambientColorLocal = vec3(0.5216, 0.5216, 0.5216);
  vec3 ambient = mix(ambientColorLocal, ambientMood, moodSmooth);

  vec3 indirect = (blocklight + skylight) * ao;

  float metalMask = isMetal ? 1.0 : 0.0;
  indirect = mix(indirect, indirect * 0.35, metalMask);

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
