#version 330 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"
#include "/lib/lighting/lighting.glsl"
#include "/lib/common.glsl"

uniform int renderStage;

in vec3 normal;
in mat3 tbnMatrix;
vec3 horizon;
vec3 zenith;
in vec3 modelPos;
in vec3 viewPos;
in vec4 glcolor;
in vec2 texcoord;
in vec3 feetPlayerPos;


vec3 rainHorizon = vec3(0.5765, 0.5765, 0.5765);
vec3 rainZenith = vec3(0.1137, 0.1137, 0.1137);

// Replace the color-setting functions with constants
const vec3 DAY_ZENITH = vec3(DAY_ZEN_R, DAY_ZEN_G, DAY_ZEN_B);
const vec3 DAY_HORIZON = vec3(DAY_HOR_R, DAY_HOR_G, DAY_HOR_B);
const vec3 DAWN_ZENITH = vec3(DAWN_ZEN_R, DAWN_ZEN_G, DAWN_ZEN_B);
const vec3 DAWN_HORIZON = vec3(DAWN_HOR_R, DAWN_HOR_G, DAWN_HOR_B);
const vec3 DUSK_ZENITH = vec3(DUSK_ZEN_R, DUSK_ZEN_G, DUSK_ZEN_B);
const vec3 DUSK_HORIZON = vec3(DUSK_HOR_R, DUSK_HOR_G, DUSK_HOR_B);
const vec3 NIGHT_ZENITH_C = vec3(NIGHT_ZEN_R, NIGHT_ZEN_G, NIGHT_ZEN_B);
const vec3 NIGHT_HORIZON_C = vec3(NIGHT_HOR_R, NIGHT_HOR_G, NIGHT_HOR_B);

vec3 calcMieSky(
  vec3 pos,
  vec3 lightPos,
  vec3 sunColor,
  vec3 viewPos,
  vec2 texcoord
) {
  //Mie scattering assignments
  vec3 mieScatterColor = vec3(0.1922, 0.149, 0.1137) * MIE_SCALE * sunColor;
  vec3 moonMieScatterColor =
    vec3(0.0549, 0.0549, 0.1529) * MIE_SCALE * sunColor;
  vec3 mieScat = mieScatterColor;
  vec3 mMieScat = moonMieScatterColor;
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  vec3 sunPos = normalize(sunPosition);
  vec3 worldSunPos = mat3(gbufferModelViewInverse) * sunPos;
  vec3 moonPos = normalize(moonPosition);
  vec3 worldMoonPos = mat3(gbufferModelViewInverse) * moonPos;
  float sVoL = dot(normalize(feetPlayerPos), worldSunPos);
  float mVoL = dot(normalize(feetPlayerPos), worldMoonPos);

  if (rainStrength <= 1.0 && rainStrength > 0.0) {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    mieScat = mix(mieScat, mieScat * 0.8, rainStrength);
  }

  mieScat *= CS(0.72, sVoL);
  if (isNight) {
    mieScat *= 0.0;
    mieScat = vec3(0.6275, 0.4824, 0.3686) * MIE_SCALE * sunColor;
    mieScat *= CS(0.45, sVoL);
  }
  mMieScat *= CS(0.72, mVoL);
  mieScat += mMieScat;
  return mieScat;
}

vec3 newSky(vec3 pos) {
  vec3 dir = normalize(pos);
  float VoL = dot(dir, worldLightVector);
  float rayleigh = Rayleigh(VoL) * RAYLEIGH_COEFF;

  float upPos = clamp(dir.y, 0, 1);
  float downPos = clamp(dir.y, -1, 0);
  float negatedDownPos = -1 * downPos;
  float midPos = upPos + negatedDownPos;
  float negatedMidPos = 1 - midPos;

  float zenithBlend = pow(upPos, ZENITH_BLEND);
  float horizonBlend = pow(negatedMidPos, HORIZON_BLEND);
  float groundBlend = pow(negatedDownPos, GROUND_BLEND);

  vec3 zenithCol;
  vec3 horizonCol;
  float t = fract(worldTime / 24000.0);

  const int keys = 7;
  const float keyFrames[keys] = float[keys](
    0.0,
    0.0417,
    0.25,
    0.4792,
    0.5417,
    0.8417,
    1.0
  );

  const vec3 zenithColors[keys] = vec3[keys](
    DAWN_ZENITH * 2,
    DAY_ZENITH,
    DAY_ZENITH,
    DUSK_ZENITH * 0.7,
    NIGHT_ZENITH_C * 0.35,
    NIGHT_ZENITH_C * 0.35,
    DAWN_ZENITH * 2
  );
  const vec3 horizonColors[keys] = vec3[keys](
    DAWN_HORIZON * 2,
    DAY_HORIZON,
    DAY_HORIZON,
    DUSK_HORIZON * 0.8,
    NIGHT_HORIZON_C * 0.8,
    NIGHT_HORIZON_C * 0.8,
    DAWN_HORIZON * 2
  );

  int i = 0;
  // step(edge, x) returns 0.0 if x<edge, else 1.0
  // Accumulate how many key boundaries t has passed.
  for (int k = 0; k < keys - 1; ++k) {
    i += int(step(keyFrames[k + 1], t));
  }
  i = clamp(i, 0, keys - 2);

  // Local segment interpolation in [0..1]
  float segW = (t - keyFrames[i]) / max(1e-6, keyFrames[i + 1] - keyFrames[i]);
  segW = smoothstep(0.0, 1.0, segW);

  zenithCol = mix(zenithColors[i], zenithColors[i + 1], segW);
  horizonCol = mix(horizonColors[i], horizonColors[i + 1], segW);

  zenithCol = mix(zenithCol, rainZenith, wetness);
  horizonCol = mix(horizonCol, rainZenith, wetness);

  zenithCol *= rayleigh * 20 * zenithBlend;
  horizonCol *= rayleigh * 25 * horizonBlend;
  vec3 groundCol = vec3(0.0588, 0.1059, 0.2235) * rayleigh * 20 * groundBlend;

  vec3 sky = zenithCol + horizonCol + groundCol;

  return sky;
}

vec3 calcSun(
  vec3 pos,
  vec3 lightPos,
  vec3 sunColor,
  vec3 viewPos,
  vec2 texcoord
) {
  //Mie scattering assignments
  vec3 mieScatterColor = vec3(0.0784, 0.0471, 0.0118) * MIE_SCALE * sunColor;

  vec3 mieScat = mieScatterColor;

  bool inWater = isEyeInWater == 1.0;
  vec3 sunPos = normalize(sunPosition);
  vec3 worldSunPos = mat3(gbufferModelViewInverse) * sunPos;
  float VoL = dot(normalize(feetPlayerPos), worldSunPos);
  if (rainStrength <= 1.0 && rainStrength > 0.0) {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    mieScat = mix(mieScat, mieScat * 0.1, rainStrength);
  }

  mieScat *= max(CS(0.9998, VoL), 0.00001);

  return mieScat;
}



/* RENDERTARGETS: 0,8,8*/
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 stars;
layout(location = 2) out vec4 sun;
void main() {
  if (renderStage == MC_RENDER_STAGE_STARS) {
    color = glcolor * 1.5;

    // precompute values once
    float starBrightnessShift = length(feetPlayerPos) * 0.1;
    vec2 posShift;
    posShift = vec2(0.0, 1.0);
    float baseX =
      dot(feetPlayerPos.xz, posShift) * 2.5 +
      (frameTimeCounter * 4.9 + starBrightnessShift);

    float starTwinkleFactor = exp(sin(baseX - 1.6));
    float starFluctuation = starTwinkleFactor - exp(cos(baseX - 1.0));
    vec2 starTwinkle =
      vec2(starTwinkleFactor, -starFluctuation) +
      starBrightnessShift * posShift;
    stars += float(starTwinkle) * 0.96;
  } else {
    vec3 pos = viewPos;


    vec3 sunColor = currentSunColor(vec3(0.0));

    vec3 skyMie = vec3(
      calcSun(normalize(pos), worldLightVector, sunColor, viewPos, texcoord)
    );
    vec3 eyePlayerPos = feetPlayerPos - gbufferModelViewInverse[3].xyz;
    vec3 skyMain = newSky(eyePlayerPos);
    vec3 skySun = vec3(
      calcSun(normalize(pos), worldLightVector, sunColor, viewPos, texcoord)
    );

    color.rgb = skyMain + skySun + skyMie;
    sun.rgb = skySun;
  }
}
