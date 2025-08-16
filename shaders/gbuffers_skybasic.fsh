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

vec3 rainHorizon = vec3(0.8941, 0.8941, 0.8941);
vec3 rainZenith = vec3(0.7529, 0.7529, 0.7529);

const vec3 DAY_ZENITH = vec3(DAY_ZEN_R, DAY_ZEN_G, DAY_ZEN_B * 0.6);
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
  vec3 mieScatterColor = vec3(0.1059, 0.0745, 0.0431) * MIE_SCALE * sunColor;

  vec3 mieScat = mieScatterColor;

  bool inWater = isEyeInWater == 1.0;
  float VoL = dot(normalize(feetPlayerPos), lightPos);
  if (rainStrength <= 1.0 && rainStrength > 0.0) {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    mieScat = mix(mieScat, mieScat * 0.8, rainStrength);
  }
  

  mieScat *= max(CS(0.75, VoL), 0.00001);
  return mieScat;
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
  float VoL = dot(normalize(feetPlayerPos), lightPos);
  if (rainStrength <= 1.0 && rainStrength > 0.0) {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    mieScat = mix(mieScat, mieScat * 0.1, rainStrength);
  }

  if (worldTime > 13000) {
    float t = smoothstep(12800.0, 13000.0, float(worldTime));
    mieScat *= mix(mieScat, mieScat * 0.0, t);
  } else if (worldTime < 2400) {
    float t = smoothstep(12800.0, 13000.0, float(worldTime));
    mieScat *= mix(mieScat, mieScatterColor, t);
  }
  mieScat *= max(CS(0.9994, VoL), 0.00001);
  return mieScat;
}

vec3 newSky(vec3 pos) {
  vec3 eyePlayerPos = feetPlayerPos - gbufferModelViewInverse[3].xyz;
  vec3 dir = normalize(eyePlayerPos);
  float VoL = dot(normalize(feetPlayerPos), worldLightVector);
  float rayleigh = Rayleigh(VoL) * RAYLEIGH_COEFF;

  float upPos = clamp(dir.y, 0, 1);
  float downPos = clamp(dir.y, -1, 0);
  float negatedDownPos = -1 * downPos;
  float midPos = upPos + negatedDownPos;
  float negatedMidPos = 1 - midPos;

  float zenithBlend = pow(upPos, 0.45);
  float horizonBlend = pow(negatedMidPos, 5.5);
  float groundBlend = pow(negatedDownPos, 0.45);

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
    DAWN_ZENITH,
    DAY_ZENITH,
    DAY_ZENITH,
    DUSK_ZENITH * 0.7,
    NIGHT_ZENITH_C * 0.5,
    NIGHT_ZENITH_C * 0.5,
    DAWN_ZENITH
  );
  const vec3 horizonColors[keys] = vec3[keys](
    DAWN_HORIZON,
    DAY_HORIZON,
    DAY_HORIZON,
    DUSK_HORIZON * 0.8,
    NIGHT_HORIZON_C,
    NIGHT_HORIZON_C,
    DAWN_HORIZON
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

  zenithCol *= rayleigh * 25 * zenithBlend;
  horizonCol *= rayleigh * 25 * horizonBlend;
  vec3 groundCol = vec3(0.1686, 0.2196, 0.3333) * rayleigh * 25 * groundBlend;

  vec3 sky = zenithCol + horizonCol + groundCol;

  return sky;
}

/* RENDERTARGETS: 0,8,8*/
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 stars;
layout(location = 2) out vec4 sun;
void main() {
  if (renderStage == MC_RENDER_STAGE_STARS) {
    color = glcolor * 0.5;

    // precompute values once
    float starBrightnessShift = length(feetPlayerPos) * 3.1;
    vec2 posShift;
    posShift = vec2(0.0, 1.0);
    float baseX =
      dot(feetPlayerPos.xz, posShift) * 2.5 +
      (frameTimeCounter * 0.9 + starBrightnessShift);

    float starTwinkleFactor = exp(sin(baseX - 1.6));
    float starFluctuation = starTwinkleFactor - exp(cos(baseX - 1.0));
    vec2 starTwinkle =
      vec2(starTwinkleFactor, -starFluctuation) +
      starBrightnessShift * posShift;
    stars += float(starTwinkle) * 0.56;
  } else {
    vec3 pos = viewPos;
  

    vec4 skyMain = vec4(newSky(pos), 1.0);
    vec3 sunColor = currentSunColor(vec3(0.0));
    vec4 skyMie = vec4(
      calcMieSky(normalize(pos), worldLightVector, sunColor, viewPos, texcoord),
      1.0
    );
    vec4 skySun = vec4(
      calcSun(normalize(pos), worldLightVector, sunColor, viewPos, texcoord),
      1.0
    );
    color = skyMain + skyMie + skySun;
   sun = skySun;
  }
}
