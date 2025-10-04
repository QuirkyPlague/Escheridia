#ifndef SKY_COLOR_GLSL
#define SKY_COLOR_GLSL

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"
#include "/lib/phaseFunctions.glsl"
#include "/lib/lighting/lighting.glsl"

const vec3 rainHorizon = vec3(0.5765, 0.5765, 0.5765);
const vec3 rainZenith = vec3(0.1137, 0.1137, 0.1137);

// Replace the color-setting functions with constants
const vec3 DAY_ZENITH = vec3(DAY_ZEN_R, DAY_ZEN_G, DAY_ZEN_B);
const vec3 DAY_HORIZON = vec3(DAY_HOR_R, DAY_HOR_G, DAY_HOR_B);
const vec3 DAWN_ZENITH = vec3(DAWN_ZEN_R, DAWN_ZEN_G, DAWN_ZEN_B);
const vec3 DAWN_HORIZON = vec3(DAWN_HOR_R, DAWN_HOR_G, DAWN_HOR_B);
const vec3 DUSK_ZENITH = vec3(DUSK_ZEN_R, DUSK_ZEN_G, DUSK_ZEN_B);
const vec3 DUSK_HORIZON = vec3(DUSK_HOR_R, DUSK_HOR_G, DUSK_HOR_B);
const vec3 NIGHT_ZENITH_C = vec3(NIGHT_ZEN_R, NIGHT_ZEN_G, NIGHT_ZEN_B);
const vec3 NIGHT_HORIZON_C = vec3(NIGHT_HOR_R, NIGHT_HOR_G, NIGHT_HOR_B);


vec3 getSun(vec3 dir)
{
  vec3 sunPos = normalize(sunPosition);
  vec3 worldSunPos = mat3(gbufferModelViewInverse) * sunPos;
  vec3 moonPos = normalize(moonPosition);
  vec3 worldMoonPos = mat3(gbufferModelViewInverse) * moonPos;
    float cosTheta = dot(dir, worldSunPos);
    float mDotL = dot(dir,worldMoonPos);

    float invCos = 1 - cosTheta;
    float invCos1 = 1 - mDotL;
    float angularDist = clamp(invCos, -1.0, 1.0);
    float angularDist1 = clamp(invCos1, -1.0, 1.0);
    float sun = smoothstep(0.0003, 0.0001 * 0.5, angularDist);
    float moon = smoothstep(0.0002, 0.0001 * 0.03, angularDist1);
    vec3 sunColor;
    
    sunColor = currentSunColor(sunColor);

   vec3 fullSun = sun * sunColor * 15.0;
   vec3 fullmoon = moon * sunColor * 15.3;
   return fullSun + fullmoon;
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
    DAWN_ZENITH ,
    DAY_ZENITH,
    DAY_ZENITH,
    DUSK_ZENITH * 0.7,
    NIGHT_ZENITH_C * 0.15,
    NIGHT_ZENITH_C * 0.15,
    DAWN_ZENITH * 0.5
  );
  const vec3 horizonColors[keys] = vec3[keys](
    DAWN_HORIZON,
    DAY_HORIZON,
    DAY_HORIZON,
    DUSK_HORIZON * 0.8,
    NIGHT_HORIZON_C * 0.35,
    NIGHT_HORIZON_C * 0.35,
    DAWN_HORIZON * 0.5
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
  vec3 groundCol = vec3(0.0549, 0.1451, 0.3804) * rayleigh * 20 * groundBlend;

  vec3 sky = zenithCol + horizonCol + groundCol;
  // MIE Scattering
  vec3 sunColor;
  sunColor = currentSunColor(sunColor);
  //Mie scattering assignments
  const vec3 sunriseScatter = vec3(1.0, 0.1882, 0.0039);
  const vec3 dayScatter = vec3(0.8745, 0.7882, 0.7098);
  const vec3  nightScatter = vec3(0.4627, 0.3412, 0.2745);
  vec3 moonMieScatterColor =
    vec3(0.0706, 0.0706, 0.1961)  * sunColor;
  vec3 mieScat;
  vec3 mMieScat = moonMieScatterColor;

  vec3 sunPos = normalize(sunPosition);
  vec3 worldSunPos = mat3(gbufferModelViewInverse) * sunPos;
  vec3 moonPos = normalize(moonPosition);
  vec3 worldMoonPos = mat3(gbufferModelViewInverse) * moonPos;
  float sVoL = dot(normalize(pos), worldSunPos);
  float mVoL = dot(normalize(pos), worldMoonPos);

  if (rainStrength <= 1.0 && rainStrength > 0.0) {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    mieScat = mix(mieScat, mieScat * 0.8, rainStrength);
  }

  float mieScale;
  const float dayScale = 0.85;
  const float sunriseScale = 0.55;
  const float nightScale = 0.35;

  const float mieTimeScale[keys] = float[keys](
    sunriseScale,
    dayScale,
    dayScale,
    sunriseScale,
    nightScale,
    nightScale,
    sunriseScale
  );

   const vec3 mieColor[keys] = vec3[keys](
    sunriseScatter,
    dayScatter,
    dayScatter,
    sunriseScatter,
    nightScatter,
    nightScatter,
    sunriseScatter
  );

  mieScale = mix(mieTimeScale[i], mieTimeScale[i + 1], segW);
  mieScat= mix(mieColor[i], mieColor[i + 1], segW);

  float miePhase = CS(mieScale, sVoL);
  vec3 mieColors =  mieScat * miePhase * 0.5 ; // tweak multiplier

  float moonPhase = CS(0.95, mVoL);
  vec3 mieNight = mMieScat * moonPhase * 0.3;
  vec3 finalMie = mieColors + mieNight;
 

  return sky + finalMie;
}

#endif //SKY_COLOR_GLSL
