#ifndef SKY
#define SKY

#include "/lib/util.glsl"
#include "/lib/lighting/lighting.glsl"

//Pale Garden
const vec3 paleZenCol = vec3(1.0, 1.0, 1.0);
const vec3 paleHorCol = vec3(0.7137, 0.7137, 0.7137);
const vec3 paleGrndCol = vec3(0.4314, 0.4314, 0.4314);

//rain
const vec3 rainZenCol = vec3(0.5529, 0.5529, 0.5529);
const vec3 rainHorCol = vec3(0.8549, 0.8549, 0.8549);
const vec3 rainGrndCol = vec3(0.2353, 0.2353, 0.2353);

//Day
const vec3 dayZenCol = vec3(0.32, 0.52, 1.0);
const vec3 dayHorCol = vec3(0.8353, 0.9176, 1.0);
const vec3 dayGrndCol = vec3(0.1686, 0.3451, 0.5216);

//Dawn
const vec3 dawnZenCol = vec3(0.4392, 0.6353, 1.0);
const vec3 dawnHorCol = vec3(0.8627, 0.6902, 0.4941);
const vec3 dawnGrndCol = vec3(0.1804, 0.4902, 0.7098);

//Dusk
const vec3 duskZenCol = vec3(0.3098, 0.4353, 0.6157);
const vec3 duskHorCol = vec3(0.8314, 0.5765, 0.3961);
const vec3 duskGrndCol = vec3(0.2118, 0.2706, 0.6118);

//Night
const vec3 nightZenCol = vec3(0.0392, 0.0745, 0.2824);
const vec3 nightHorCol = vec3(0.1059, 0.1569, 0.2314);
const vec3 nightGrndCol = vec3(0.0196, 0.0275, 0.1294);

const vec4 sunriseScatter = vec4(0.6392, 0.4549, 0.2745, 0.8);
const vec4 dayScatter = vec4(0.7333, 0.5922, 0.3922, 0.715);
const vec4 nightScatter = vec4(0.8824, 0.6196, 0.2745, 0.65);

vec3 getSun(vec3 dir) {
  float cosThetaSun = dot(dir, worldSunDir);
  float mDotL = dot(dir, worldMoonDir);

  float upPos = clamp(dir.y, 0, 1);
  float downPos = clamp(dir.y, -1, 0);
  float negatedDownPos = -1.0 * downPos;
  float midPos = upPos + negatedDownPos;
  float negatedMidPos = 1.0 - midPos;
  float zenithBlend = clamp(pow(upPos, 0.35), 0, 1);
  float horizonBlend = clamp(pow(negatedMidPos, 4.5), 0, 1);
  float groundBlend = clamp(pow(negatedDownPos, 0.35), 0, 1);

  float invCos = 1.0 - cosThetaSun;
  float invCos1 = 1.0 - mDotL;
  float angularDist = clamp(invCos, -1.0, 1.0);
  float angularDist1 = clamp(invCos1, -1.0, 1.0);
  float sunHeightFactor = smoothstep(groundBlend, groundBlend + 0.28, dir.y);
  float sun = smoothstep(
    0.0003 * SUN_ANGLUAR_RADIUS_MULT,
    0.0003 * SUN_ANGLUAR_RADIUS_MULT * 0.9,
    angularDist
  );
  float moon = smoothstep(
    0.0002 * MOON_ANGLUAR_RADIUS_MULT,
    0.0001 * MOON_ANGLUAR_RADIUS_MULT * 0.03,
    angularDist1
  );

  vec3 sunColor;
  sunColor = currentSunColor(sunColor);

  vec3 fullSun = sun * sunColor * 40.0 * sunHeightFactor;

  vec3 moonColor = vec3(0.098, 0.1294, 0.1843);
  vec3 fullmoon = moon * moonColor * 13.3;

  if (worldMoonDir.y < groundBlend) fullmoon *= 0.0;
  return fullSun + fullmoon;
}

vec3 skyScattering(vec3 pos) {
  vec3 dir = normalize(pos);
  float VoL = dot(dir, worldLightVector);
  float rayleigh =
    Rayleigh(VoL) * mix(8.0, 17.0, clamp(worldSunDir.y * 0.5 + 0.5, 0.0, 1.0));

  float upPos = clamp(dir.y, 0, 1);
  float downPos = clamp(dir.y, -1, 0);
  float negatedDownPos = -1.0 * downPos;
  float midPos = upPos + negatedDownPos;
  float negatedMidPos = 1.0 - midPos;

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

  const vec3 zenithColors[keys] = vec3[keys](
    dawnZenCol,
    dayZenCol * 1.32,
    dayZenCol * 1.32,
    duskZenCol * 0.7,
    nightZenCol * 0.85,
    nightZenCol * 0.85,
    dawnZenCol
  );
  const vec3 horizonColors[keys] = vec3[keys](
    dawnHorCol,
    dayHorCol,
    dayHorCol,
    duskHorCol * 0.8,
    nightHorCol,
    nightHorCol,
    dawnHorCol
  );
  const vec3 groundColors[keys] = vec3[keys](
    dawnGrndCol,
    dayGrndCol,
    dayGrndCol,
    duskGrndCol * 0.8,
    nightGrndCol,
    nightGrndCol,
    dawnGrndCol
  );

  const vec4 mieColor[keys] = vec4[keys](
    sunriseScatter,
    dayScatter,
    dayScatter,
    sunriseScatter,
    nightScatter,
    nightScatter,
    sunriseScatter
  );
  const float weatherIntensity[keys] = float[keys](
    0.75,
    1.0,
    1.0,
    0.65,
    0.25,
    0.25,
    0.75
  );

  int i = 0;
  for (int k = 0; k < keys - 1; ++k) {
    i += int(step(keyFrames[k + 1], t));
  }
  i = clamp(i, 0, keys - 2);

  float timeInterp =
    (t - keyFrames[i]) / max(1e-6, keyFrames[i + 1] - keyFrames[i]);
  timeInterp = smoothstep(0.0, 1.0, timeInterp);

  vec3 zenithCol = mix(zenithColors[i], zenithColors[i + 1], timeInterp);
  vec3 horizonCol = mix(horizonColors[i], horizonColors[i + 1], timeInterp);
  vec3 groundCol = mix(groundColors[i], groundColors[i + 1], timeInterp);

  float weatherStrength = mix(
    weatherIntensity[i],
    weatherIntensity[i + 1],
    timeInterp
  );

  zenithCol = mix(zenithCol, paleZenCol, PaleGardenSmooth);
  horizonCol = mix(horizonCol, paleHorCol, PaleGardenSmooth);
  groundCol = mix(groundCol, paleGrndCol, PaleGardenSmooth);

  zenithCol = mix(zenithCol, rainZenCol * weatherStrength, wetness);
  horizonCol = mix(horizonCol, rainHorCol * weatherStrength, wetness);
  groundCol = mix(groundCol, rainGrndCol * weatherStrength, wetness);

  float zenithBlend = clamp(pow(upPos, 0.35), 0, 1);
  float horizonBlend = clamp(pow(negatedMidPos, 4.5), 0, 1);
  float groundBlend = clamp(pow(negatedDownPos, 0.35), 0, 1);

  zenithCol *= rayleigh * zenithBlend;
  horizonCol *= rayleigh * horizonBlend;
  groundCol *= rayleigh * groundBlend;

  vec3 sky = zenithCol + horizonCol + groundCol;

  vec3 sunColor;
  sunColor = currentSunColor(sunColor);

  vec3 moonMieScatterColor = vec3(0.0, 0.0, 0.0);
  vec3 mieScat = mix(mieColor[i].rgb, mieColor[i + 1].rgb, timeInterp);
  mieScat = mix(mieScat, vec3(0.0), wetness);
  moonMieScatterColor = mix(moonMieScatterColor, vec3(0.0), wetness);
  float mieScale = mix(mieColor[i].a, mieColor[i + 1].a, timeInterp);

  float sVoL = dot(dir, worldSunDir);
  float mVoL = dot(dir, worldMoonDir);

  float miePhase = CS(mieScale, sVoL);
  vec3 mieColors = mieScat * miePhase * 0.5;

  float moonPhase = CS(0.915, mVoL);
  vec3 mieNight = moonMieScatterColor * moonPhase * 0.0;

  vec3 finalMie = mieColors + mieNight;

  float dawnDuskMieFactor = smoothstep(-0.035, 0.035, dir.y);
  float dawnDuskTimeFactor = smoothstep(0.0, 0.1, t) * smoothstep(0.4, 0.6, t);
  finalMie *= mix(1.0, dawnDuskMieFactor, dawnDuskTimeFactor);

  return sky + finalMie;
}

#endif
