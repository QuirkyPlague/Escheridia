#ifndef LIGHTING
#define LIGHTING

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"
#include "/lib/brdf.glsl"
#include "/lib/phaseFunctions.glsl"
#include "/lib/tonemapping.glsl"

//Sun/moon
const vec4 sunlightColor = vec4(1.0, 0.860, 0.622, 1.8);
const vec4 noonSunlightColor = vec4(0.6824, 0.6824, 0.6824, 1.0);
const vec4 morningSunlightColor = vec4(0.7569, 0.4745, 0.2333, 1.9);
const vec4 eveningSunlightColor = vec4(0.7725, 0.2863, 0.0824, 1.0);
const vec4 moonlightColor = vec4(0.0549, 0.098, 0.2353, 0.4);

const vec4 skylightColor = vec4(0.8314, 0.8824, 1.0, 0.748);
const vec4 morningSkylightColor = vec4(0.6353, 0.7333, 0.851, 0.761);
const vec4 eveningSkylightColor = vec4(0.3294, 0.4549, 0.8235, 0.721);
const vec4 nightSkylightColor = vec4(0.3137, 0.3725, 0.5255, 0.924);

const vec4 blocklightColor = vec4(1.0, 0.8627, 0.7176, 1.0);
const vec4 ambientColor = vec4(0.0, 0.0, 0.0, 1.0);
const vec4 caveAmbient = vec4(0.4157, 0.4157, 0.4157, 1.0);
const vec3 rainTint = vec3(0.2235, 0.3216, 0.6549);

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
  color = pow(color, vec3(2.2));
  float t = fract(worldTime / 24000.0);
  const int keys = 7;
  const float keyFrames[keys] = float[keys](
    0.0, //sunrise
    0.0417, //day
    0.45, //noon
    0.4892, //sunset
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
    moonlightColor * 1.5,
    moonlightColor  * 1.5,
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
    0.25,
    0.75,
    0.75,
    0.25,
    0.15,
    0.15,
    0.25

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
  float shadowFade = smoothstep(0.005, 0.1, worldLightVector.y);
  float shadowSmooth = exp(-1.0 * SHADOW_DISTANCE);
  float shadowSmoothFade = smoothstep(1.0, 0.0, shadowSmooth);
  shadow *= shadowSmoothFade;
  if (wetness > 0)
  {
    sunlight *= mix(sunlight, rainTint, wetness * hotBiomeSmooth);
    sunlight *= mix(1.0, 0.36, wetness * hotBiomeSmooth);
  }
  
  sunlight *= sunIntensity;
  sunlight *= shadowFade;

  vec3 skylight =
    mix(skyCol[i].rgb, skyCol[i + 1].rgb, timeInterp) * lightmap.g;
    skylight = mix(skylight, vec3(0.5294, 0.5804, 0.6471) * rain * lightmap.g, wetness * hotBiomeSmooth);
  float skyIntensity = mix(skyCol[i].a, skyCol[i + 1].a, timeInterp);
  ;
  skylight *= skyIntensity;
  skylight *= max(1.95 * pow(skylight, vec3(2.55)), 0.0);
  skylight += min(1.7 * pow(skylight, vec3(1.25)), 1.9);

  vec3 blocklight = blocklightColor.rgb * lightmap.r;
  
  blocklight *= max(3.59 * pow(blocklight, vec3(1.75)), 0.0);
  blocklight += min(1.7 * pow(blocklight, vec3(1.25)), 3.9);
  blocklight  *= smoothstep(0.0, 0.125, blocklight); 

  float faceNdl = dot(faceNormal, worldLightVector);
 
  float hasSSS = step(64.0 / 255.0, sss);
  float phase =
    henyeyGreensteinPhase(VdotL, 0.635) * 2;

vec3 skylightSSS = vec3(0.0);
vec3 scatter = vec3(0.0);
 scatter = sunlight * phase * shadow;
  vec3 baseScatter = sunlight * shadow;
  scatter += baseScatter * 2 ;
  scatter *= hasSSS;
  scatter *= sss;
  if (faceNdl >= 1e-6) {
    scatter *= 0.45;
  }
 

  float ambientFactor = smoothstep(141, 0, eyeBrightnessSmooth.y);
  
  //ao *= ao * (1.0 - float(shadow));
  vec3 ambientLight = (mix(ambientColor.rgb,caveAmbient.rgb * 0.06, ambientFactor)* ao) * color  ;

  
  vec3 indirect = (skylight + blocklight) * ao;
  float metalMask = isMetal ? 1.0 : 0.0;
  indirect = mix(indirect, indirect * 0.3, metalMask);
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
  
  //specular = pow(specular, vec3(2.2));
  
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
    0.4892, //sunset
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
    moonlightColor * 1.55,
    moonlightColor * 1.55,
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
  float phaseIncFactor = smoothstep(225, 0, eyeBrightnessSmooth.y);
  float ambientMult = mix(1.0, 0.0, phaseIncFactor);
  vec3 sunlight = mix(sunCol[i].rgb, sunCol[i + 1].rgb, timeInterp);
  float sunIntensity = mix(sunCol[i].a, sunCol[i + 1].a, timeInterp);
  float sunHeight = dot(worldLightVector, vec3(0.0, 1.0, 0.0));
  float shadowFade = smoothstep(0.05, 0.1, worldLightVector.y);

  if (wetness > 0)
  {
    sunlight *= mix(sunlight, rainTint, wetness * hotBiomeSmooth);
    sunlight *= mix(1.0, 0.86, wetness * hotBiomeSmooth);
  }
  sunlight *= sunIntensity;
  sunlight *= shadowFade;
  return sunlight;
}

#endif //LIGHTING_GLSL
