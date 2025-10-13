#ifndef LIGHTING
#define LIGHTING

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"
#include "/lib/brdf.glsl"
#include "/lib/phaseFunctions.glsl"
#include "/lib/tonemapping.glsl"

//Sun/moon
const vec4 sunlightColor = vec4(1.1, 0.83627, 0.602, 0.81);
const vec4 noonSunlightColor = vec4(0.6824, 0.6824, 0.6824, 1.0);
const vec4 morningSunlightColor = vec4(0.7451, 0.3137, 0.1078, 0.85);
const vec4 eveningSunlightColor = vec4(0.7529, 0.3765, 0.1451, 1.0);
const vec4 moonlightColor = vec4(0.0549, 0.098, 0.2353, 0.8);

const vec4 skylightColor = vec4(0.8314, 0.8784, 1.0, 0.8);
const vec4 morningSkylightColor = vec4(0.4863, 0.6667, 0.8745, 0.821);
const vec4 eveningSkylightColor = vec4(0.3294, 0.4549, 0.8235, 0.721);
const vec4 nightSkylightColor = vec4(0.1647, 0.3255, 0.7333, 0.651);

const vec4 blocklightColor = vec4(1.0, 0.8941, 0.8157, 1.0);
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
  bool isMetal,
  vec3 faceNormal
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

    const float rainLight[keys] = float[keys](
    0.15,
    0.55,
    0.55,
    0.15,
    0.05,
    0.05,
    0.15

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
  float rain = mix(rainLight[i], rainLight[i + 1], timeInterp);
  float sunHeight = dot(worldLightVector, vec3(0.0, 1.0, 0.0));
  float shadowFade = smoothstep(0.05, 0.1, worldLightVector.y);
  float shadowSmooth = exp(-1.0 * SHADOW_DISTANCE);
  float shadowSmoothFade = smoothstep(1.0, 0.0, shadowSmooth);
  shadow *= shadowSmoothFade;
  sunlight = mix(sunlight, vec3(0.5529, 0.5529, 0.5529) * rain, wetness);
  sunlight *= sunIntensity;
  sunlight *= shadowFade;

  vec3 skylight =
    mix(skyCol[i].rgb, skyCol[i + 1].rgb, timeInterp) * lightmap.g;
    skylight = mix(skylight, vec3(0.1882, 0.1882, 0.1882) * rain * lightmap.g, wetness);
  float skyIntensity = mix(skyCol[i].a, skyCol[i + 1].a, timeInterp);
  ;
  skylight *= skyIntensity;
  skylight += max(5.95 * pow(skylight, vec3(2.55)), 0.0);
  skylight *= min(1.07 * pow(skylight, vec3(0.6)), 0.67);

  vec3 blocklight = blocklightColor.rgb * lightmap.r;
  
  blocklight *= max(1.39 * pow(blocklight, vec3(3.75)), 0.0);
  blocklight += min(4.7 * pow(blocklight, vec3(0.5)), 3.9);
  blocklight  *= smoothstep(0.0, 0.125, blocklight); 

  float faceNdl = dot(faceNormal, worldLightVector);
 
  float hasSSS = step(64.0 / 255.0, sss);
  float phase =
    henyeyGreensteinPhase(VdotL, 0.635) * 4;

vec3 skylightSSS = vec3(0.0);
vec3 scatter = vec3(0.0);
  if (faceNdl <= 1e-6) {
  scatter = sunlight * phase * shadow;
  vec3 baseScatter = sunlight * shadow;
  scatter += baseScatter * 2 ;
  scatter *= hasSSS;
  scatter *= sss;
  }
 
  skylightSSS = skylight;
  skylightSSS *= exp(-lightmap.g * sss / 0.61);
  skylightSSS *= clamp(
    min(21.17 * pow(skylightSSS, vec3(2.8)),  sss),
    0.0,
    1.0
  );
  skylightSSS *= hasSSS;
  
  
  vec3 ambientLight = (ambientColor.rgb)   *color;
  vec3 ambientDir = faceNormal;
  
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
  
  scatter += (skylightSSS);
  scatter *= ao;
  scatter *= color;
  return specular + scatter + ambientLight ;

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
