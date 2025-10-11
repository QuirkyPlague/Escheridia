#ifndef LIGHTING
#define LIGHTING

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"
#include "/lib/brdf.glsl"
#include "/lib/phaseFunctions.glsl"
#include "/lib/tonemapping.glsl"

//Sun/moon
const vec4 sunlightColor = vec4(0.7098, 0.6, 0.4, 0.91);
const vec4 noonSunlightColor = vec4(0.6824, 0.6824, 0.6824, 1.0);
const vec4 morningSunlightColor = vec4(0.5451, 0.3137, 0.2078, 1.0);
const vec4 eveningSunlightColor = vec4(0.7529, 0.3765, 0.1451, 1.0);
const vec4 moonlightColor = vec4(0.0549, 0.098, 0.2353, 0.3);

const vec4 skylightColor = vec4(0.7216, 0.8, 1.0, 0.891);
const vec4 morningSkylightColor = vec4(0.4863, 0.6667, 0.8745, 0.821);
const vec4 eveningSkylightColor = vec4(0.3294, 0.4549, 0.8235, 0.721);
const vec4 nightSkylightColor = vec4(0.1647, 0.3255, 0.7333, 0.651);

const vec4 blocklightColor = vec4(1.0, 0.7961, 0.5451, 1.0);
const vec4 ambientColor = vec4(0.2392, 0.2392, 0.2392, 1.0);

vec3 getLighting(
  vec3 color,
  vec2 lightmap,
  vec3 normal,
  vec3 shadow,
  vec3 H,
  vec3 F0,
  float roughness,
  vec3 V,
  float ao,
  float sss,
  float VdotL,
  bool isMetal
) {
  float t = fract(worldTime / 24000.0);
  const int keys = 7;
  const float keyFrames[keys] = float[keys](
    0.0, //sunrise
    0.0417, //day
    0.45, //noon
    0.5192, //sunset
    0.5417, //night
    0.9527, //midnight
    1.0 //sunrise
  );

  //sunlight Keyframes
  const vec4 sunCol[keys] = vec4[keys](
    morningSunlightColor,
    sunlightColor,
    noonSunlightColor,
    eveningSunlightColor,
    moonlightColor,
    moonlightColor,
    morningSunlightColor
  );

  const vec4 skyCol[keys] = vec4[keys](
    morningSkylightColor,
    skylightColor,
    skylightColor,
    eveningSkylightColor,
    nightSkylightColor,
    nightSkylightColor,
    morningSkylightColor
  );

  int i = 0;
  //assings the keyframes
  for (int k = 0; k < keys - 1; ++k) {
    i += int(step(keyFrames[k + 1], t));
  }
  i = clamp(i, 0, keys - 2);

  //Interpolation factor based on the time
  float timeInterp =
    (t - keyFrames[i]) / max(1e-6, keyFrames[i + 1] - keyFrames[i]);
  timeInterp = smoothstep(0.0, 1.0, timeInterp);

  vec3 sunlight = mix(sunCol[i].rgb, sunCol[i + 1].rgb, timeInterp);
  float sunIntensity = mix(sunCol[i].a, sunCol[i + 1].a, timeInterp);
  float sunHeight = dot(worldLightVector, vec3(0.0, 1.0, 0.0));
  float shadowFade = smoothstep(0.05, 0.1, worldLightVector.y);

  sunlight = mix(sunlight, vec3(0.1765, 0.1765, 0.1765), wetness);
  sunlight *= sunIntensity;
  sunlight *= shadowFade;

  vec3 skylight =
    mix(skyCol[i].rgb, skyCol[i + 1].rgb, timeInterp) * lightmap.g;
  float skyIntensity = mix(skyCol[i].a, skyCol[i + 1].a, timeInterp);
  ;
  skylight *= skyIntensity;
  skylight += max(5.95 * pow(skylight, vec3(2.55)), 0.0);
  skylight *= min(1.07 * pow(skylight, vec3(0.6)), 0.67);

  vec3 blocklight = blocklightColor.rgb * lightmap.r;
  blocklight += max(4.9 * pow(blocklight, vec3(0.75)), 0.0);
  blocklight *= 1.55;
  blocklight *= clamp(min(0.17 * pow(blocklight, vec3(0.8)), 5.2), 0.0, 1.0);

  float hasSSS = step(64.0 / 255.0, sss);
  float phase =
    henyeyGreensteinPhase(VdotL, 0.675) * 6 +
    henyeyGreensteinPhase(VdotL, -0.15);

  vec3 scatter = sunlight * phase * shadow * color;
  vec3 baseScatter = sunlight * shadow * color;
  scatter += baseScatter * 2;
  scatter *= hasSSS;
  scatter *= sss;

  vec3 blocklightSSS = blocklight * color;
  blocklightSSS *= exp(-lightmap.r * sss / 0.61);
  blocklightSSS *= clamp(
    min(21.17 * pow(blocklightSSS, vec3(2.8)), 0.5 * sss),
    0.0,
    1.0
  );
  blocklightSSS *= hasSSS;

  vec3 skylightSSS = skylight * color;
  skylightSSS *= exp(-lightmap.g * sss / 0.71);
  skylightSSS *= clamp(
    min(21.17 * pow(skylightSSS, vec3(2.8)), 0.55 * sss),
    0.0,
    1.0
  );
  skylightSSS *= hasSSS;

  vec3 ambientLight = ambientColor.rgb * color;
  vec3 indirect = (skylight + blocklight) * ao;
  float metalMask = isMetal ? 1.0 : 0.0;
  indirect = mix(indirect, indirect * 0.35, metalMask);
  vec3 specular = brdf(
    color,
    F0,
    sunlight,
    normal,
    H,
    V,
    roughness,
    indirect,
    shadow,
    isMetal
  );
  scatter = clamp(scatter, 0, 1);
  scatter += blocklightSSS + skylightSSS;
  return specular + ambientLight + scatter;

}

vec3 currentSunColor(vec3 color) {
  float t = fract(worldTime / 24000.0);
  const int keys = 7;
  const float keyFrames[keys] = float[keys](
    0.0, //sunrise
    0.0417, //day
    0.45, //noon
    0.5192, //sunset
    0.5417, //night
    0.9417, //midnight
    1.0 //sunrise
  );

  //sunlight Keyframes
  const vec4 sunCol[keys] = vec4[keys](
    morningSunlightColor,
    sunlightColor,
    sunlightColor,
    eveningSunlightColor,
    moonlightColor,
    moonlightColor,
    morningSunlightColor
  );

  int i = 0;
  //assings the keyframes
  for (int k = 0; k < keys - 1; ++k) {
    i += int(step(keyFrames[k + 1], t));
  }
  i = clamp(i, 0, keys - 2);

  //Interpolation factor based on the time
  float timeInterp =
    (t - keyFrames[i]) / max(1e-6, keyFrames[i + 1] - keyFrames[i]);
  timeInterp = smoothstep(0.0, 1.0, timeInterp);

  vec3 sunlight = mix(sunCol[i].rgb, sunCol[i + 1].rgb, timeInterp);
  float sunIntensity = mix(sunCol[i].a, sunCol[i + 1].a, timeInterp);
  float sunHeight = dot(worldLightVector, vec3(0.0, 1.0, 0.0));
  float shadowFade = smoothstep(0.05, 0.1, worldLightVector.y);
  sunlight = mix(sunlight, vec3(0.4745, 0.4745, 0.4745), wetness);
  sunlight *= sunIntensity;
  sunlight *= shadowFade;
  return sunlight;
}

#endif //LIGHTING_GLSL
