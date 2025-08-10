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

vec3 horizonColor = vec3(0.0);
vec3 zenithColor = vec3(0.0);
vec3 earlyHorizon = vec3(0.0);
vec3 earlyZenith = vec3(0.0);
vec3 lateHorizon = vec3(0.0);
vec3 lateZenith = vec3(0.0);
vec3 nightHorizon = vec3(0.0);
vec3 nightZenith = vec3(0.0);
vec3 rainHorizon = vec3(0.8941, 0.8941, 0.8941);
vec3 rainZenith = vec3(0.7529, 0.7529, 0.7529);

vec3 dayZenith(vec3 color) {
  color.r = DAY_ZEN_R;
  color.g = DAY_ZEN_G;
  color.b = DAY_ZEN_B;
  return color;
}
vec3 dayHorizon(vec3 color) {
  color.r = DAY_HOR_R;
  color.g = DAY_HOR_G;
  color.b = DAY_HOR_B;
  return color;
}
vec3 dawnZenith(vec3 color) {
  color.r = DAWN_ZEN_R;
  color.g = DAWN_ZEN_G;
  color.b = DAWN_ZEN_B;
  return color;
}
vec3 dawnHorizon(vec3 color) {
  color.r = DAWN_HOR_R;
  color.g = DAWN_HOR_G;
  color.b = DAWN_HOR_B;
  return color;
}
vec3 duskZenith(vec3 color) {
  color.r = DUSK_ZEN_R;
  color.g = DUSK_ZEN_G;
  color.b = DUSK_ZEN_B;
  return color;
}
vec3 duskHorizon(vec3 color) {
  color.r = DUSK_HOR_R;
  color.g = DUSK_HOR_G;
  color.b = DUSK_HOR_B;
  return color;
}
vec3 NightZenith(vec3 color) {
  color.r = NIGHT_ZEN_R;
  color.g = NIGHT_ZEN_G;
  color.b = NIGHT_ZEN_B;
  return color;
}
vec3 NightHorizon(vec3 color) {
  color.r = NIGHT_HOR_R;
  color.g = NIGHT_HOR_G;
  color.b = NIGHT_HOR_B;
  return color;
}

float fogify(float x, float w) {
  return w / (x * x + w);
}

vec3 calcSkyColor(vec3 pos) {
  vec3 horizon;
  vec3 zenith;

  float VoL = dot(pos, lightVector);
  float rayleigh = Rayleigh(VoL) * RAYLEIGH_COEFF;
  //color assignments
  //DAY
  horizonColor = dayHorizon(horizonColor);
  zenithColor = dayZenith(zenithColor);
  //DAWN
  earlyHorizon = dawnHorizon(earlyHorizon);
  earlyZenith = dawnZenith(earlyZenith);
  //DUSK
  lateHorizon = duskHorizon(lateHorizon);
  lateZenith = duskZenith(lateZenith);
  //NIGHT
  nightHorizon = NightHorizon(nightHorizon);
  nightZenith = NightZenith(nightZenith);
  rainHorizon = rainHorizon;
  rainZenith = rainZenith;
  if (worldTime >= 0 && worldTime < 1000) {
    //smoothstep equation allows interpolation between times of day
    float time = smoothstep(0, 1000, float(worldTime));
    horizon = mix(earlyHorizon, horizonColor, time);
    zenith = mix(earlyZenith, zenithColor, time);
  } else if (worldTime >= 1000 && worldTime < 11500) {
    float time = smoothstep(10000, 11500, float(worldTime));
    horizon = mix(horizonColor, lateHorizon, time);
    zenith = mix(zenithColor, lateZenith, time);

  } else if (worldTime >= 11500 && worldTime < 13000) {
    float time = smoothstep(12800, 13000, float(worldTime));
    horizon = mix(lateHorizon, nightHorizon * 0.6, time);
    zenith = mix(lateZenith, nightZenith * 0.5, time);

  } else if (worldTime >= 13000 && worldTime < 24000) {
    float time = smoothstep(22500, 24000, float(worldTime));
    horizon = mix(nightHorizon * 0.6, earlyHorizon, time);
    zenith = mix(nightZenith * 0.5, earlyZenith, time);
    rainZenith *= 0.4;
    rainHorizon *= 0.3;

  }
  rainHorizon = mix(rainHorizon, rainHorizon, rayleigh);
  rainZenith = mix(rainZenith, rainZenith, rayleigh);
  zenith = mix(zenith, zenith * 30, rayleigh);
  horizon = mix(horizon, horizon * 30, rayleigh);
    zenith = mix(zenith, rainZenith *2, wetness);
  horizon = mix(horizon, rainHorizon *2, wetness);
  float upDot = dot(pos, gbufferModelView[1].xyz); //not much, what's up with you?
  vec3 sky = mix(zenith, horizon, fogify(max(upDot, 0.0), 0.024));

  vec3 sunColor = vec3(0.0);
  sunColor = currentSunColor(sunColor);
  float sunA =
    acos(dot(worldLightVector, normalize(feetPlayerPos))) *
    SUN_SIZE *
    clamp(AIR_FOG_DENSITY, 0.8, 5.0);
  vec3 sunCol = 0.02 * sunColor / sunA;

  vec3 sun = max(sky + 0.07 * sunCol, sunCol - wetness);
  sun = max(sun, 0.00001);
  sky = mix(sky, sun, 1.0);
  return sky;
}

vec3 calcMieSky(
  vec3 pos,
  vec3 lightPos,
  vec3 sunColor,
  vec3 viewPos,
  vec2 texcoord
) {
  //Mie scattering assignments
  vec3 mieScatterColor = vec3(0.102, 0.0431, 0.0078) * MIE_SCALE * sunColor;

  vec3 mieScat = mieScatterColor;

  bool inWater = isEyeInWater == 1.0;
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  float VoL = dot(normalize(feetPlayerPos), lightPos);
  if (rainStrength <= 1.0 && rainStrength > 0.0) {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    mieScat = mix(mieScat, mieScat * 0.8, rainStrength);
  }
  if (inWater) {
    mieScat *= 0.1;
    mieScat *= CS(0.75, VoL);
  }

  mieScat *= CS(0.75, VoL);
  return mieScat;
}

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  if (renderStage == MC_RENDER_STAGE_STARS) {
    color = glcolor * 0.5;

    for (int i = 0; i < 5; i++) {
      // generate some wave direction that looks kind of random
      float iter = 0.0;
      float starBrightnessShift = length(feetPlayerPos) * 3.1;
      vec2 posShift = vec2(sin(iter), cos(iter));
      float x =
        dot(feetPlayerPos.xz, posShift) * 2.5 +
        (frameTimeCounter * 0.9 + starBrightnessShift);
      float starTwinkleFactor = exp(sin(x - 1.0));
      float starFluctuation = starTwinkleFactor - exp(cos(x - 1.3));
      vec2 starTwinkle = vec2(starTwinkleFactor, -starFluctuation);

      starTwinkle += starBrightnessShift * posShift;
      color += float(starTwinkle) * 0.16;
    }
  } else {
    vec3 pos = viewPos;
    vec3 lightPos = normalize(shadowLightPosition);
    vec3 worldLightPos = mat3(gbufferModelViewInverse) * lightPos;
    vec4 skyMain = vec4(calcSkyColor(normalize(pos)), 1.0);
    vec3 sunColor = vec3(0.0);
    sunColor = currentSunColor(sunColor);
    vec4 skyMie = vec4(
      calcMieSky(normalize(pos), worldLightPos, sunColor, viewPos, texcoord),
      1.0
    );
    color = mix(skyMie, skyMain, 0.4);

  }
}
