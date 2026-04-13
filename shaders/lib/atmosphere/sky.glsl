#ifndef SKY
#define SKY

#include "/lib/util.glsl"
#include "/lib/lighting/lighting.glsl"

//Pale Garden
const vec3 paleZenCol = vec3(1.0, 1.0, 1.0);
const vec3 paleHorCol = vec3(0.7137, 0.7137, 0.7137);
const vec3 paleGrndCol = vec3(0.4314, 0.4314, 0.4314);

//rain
const vec3 rainZenCol = vec3(0.3804, 0.3922, 0.4078);
const vec3 rainHorCol = vec3(0.3843, 0.3843, 0.3843);
const vec3 rainGrndCol = vec3(0.1176, 0.1333, 0.149);

//Day
const vec3 dayZenCol = vec3(DAY_ZENITH_COLOR_R, DAY_ZENITH_COLOR_G, DAY_ZENITH_COLOR_B);
const vec3 dayHorCol = vec3(DAY_HORIZON_COLOR_R, DAY_HORIZON_COLOR_G, DAY_HORIZON_COLOR_B);
const vec3 dayGrndCol = vec3(DAY_GROUND_COLOR_R, DAY_GROUND_COLOR_G, DAY_GROUND_COLOR_B);

const vec3 noonHorCol = vec3(NOON_HORIZON_COLOR_R, NOON_HORIZON_COLOR_G, NOON_HORIZON_COLOR_B);
const vec3 noonGrndCol = vec3(NOON_GROUND_COLOR_R, NOON_GROUND_COLOR_G, NOON_GROUND_COLOR_B);

//Dawn
const vec3 dawnZenCol = vec3(DAWN_ZENITH_COLOR_R, DAWN_ZENITH_COLOR_G, DAWN_ZENITH_COLOR_B);
const vec3 dawnHorCol = vec3(DAWN_HORIZON_COLOR_R, DAWN_HORIZON_COLOR_G, DAWN_HORIZON_COLOR_B);
const vec3 dawnGrndCol = vec3(DAWN_GROUND_COLOR_R, DAWN_GROUND_COLOR_G, DAWN_GROUND_COLOR_B);

//Dusk
const vec3 duskZenCol = vec3(DUSK_ZENITH_COLOR_R, DUSK_ZENITH_COLOR_G, DUSK_ZENITH_COLOR_B);
const vec3 duskHorCol = vec3(DUSK_HORIZON_COLOR_R, DUSK_HORIZON_COLOR_G, DUSK_HORIZON_COLOR_B);
const vec3 duskGrndCol = vec3(DUSK_GROUND_COLOR_R, DUSK_GROUND_COLOR_G, DUSK_GROUND_COLOR_B);

//Night
const vec3 nightZenCol = vec3(NIGHT_ZENITH_COLOR_R, NIGHT_ZENITH_COLOR_G, NIGHT_ZENITH_COLOR_B);
const vec3 nightHorCol = vec3(NIGHT_HORIZON_COLOR_R, NIGHT_HORIZON_COLOR_G, NIGHT_HORIZON_COLOR_B);
const vec3 nightGrndCol = vec3(NIGHT_GROUND_COLOR_R, NIGHT_GROUND_COLOR_G, NIGHT_GROUND_COLOR_B);


const vec4 sunriseScatter = vec4(0.7686, 0.4392, 0.298, 0.753);
const vec4 eveningScatter = vec4(0.8745, 0.3961, 0.1765, 0.83);
const vec4 dayScatter = vec4(0.6588, 0.4275, 0.1569, 0.755);
const vec4 noonScatter = vec4(0.3725, 0.2706, 0.1294, 0.805);
const vec4 nightScatter = vec4(0.6471, 0.4667, 0.2275, 0.65);

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
  float groundBlend = clamp(pow(negatedDownPos, 0.25), 0, 1);

  float invCos = 1.0 - cosThetaSun;
  float invCos1 = 1.0 - mDotL;
  float angularDist = clamp(invCos, -1.0, 1.0);
  float angularDist1 = clamp(invCos1, -1.0, 1.0);
  float sunHeightFactor = smoothstep(groundBlend, groundBlend + 0.28, dir.y);
  float sun = smoothstep(
    0.0003 * SUN_ANGULAR_RADIUS_MULT,
    0.0003 * SUN_ANGULAR_RADIUS_MULT * 0.9,
    angularDist
  );
  float moon = smoothstep(
    0.0002 * MOON_ANGULAR_RADIUS_MULT,
    0.0001 * MOON_ANGULAR_RADIUS_MULT * 0.03,
    angularDist1
  );

  vec3 sunColor;
  sunColor = currentSunColor(sunColor);

  vec3 fullSun = sun * sunColor * 700.0 * sunHeightFactor;
  fullSun *= mix(1.0, 0.001, wetness * hotBiomeSmooth);
  vec3 moonColor =  sunColor;
  vec3 fullmoon = moon * moonColor * 150.3 * sunHeightFactor;
  fullmoon *= mix(1.0, 0.001, wetness * hotBiomeSmooth);
  if (worldMoonDir.y < groundBlend) fullmoon *= 0.0;
  vec3 celestial = fullSun + fullmoon;

  return celestial;
}

vec3 skyScattering(vec3 pos) {
  vec3 dir = normalize(pos);
 float VoL = dot(dir, worldSunDir);
  float rayleigh =
    Rayleigh(VoL) * 13.1;

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
    dawnZenCol * 1.25,
    dayZenCol * 1.65,
    dayZenCol* 1.65,
    duskZenCol,
    nightZenCol,
    nightZenCol,
    dawnZenCol * 1.25
  );
  const vec3 horizonColors[keys] = vec3[keys](
    dawnHorCol,
    dayHorCol,
    noonHorCol,
    duskHorCol,
    nightHorCol * 1.5,
    nightHorCol  *1.5,
    dawnHorCol
  );
  const vec3 groundColors[keys] = vec3[keys](
    dawnGrndCol,
    dayGrndCol,
    noonGrndCol,
    duskGrndCol,
    nightGrndCol,
    nightGrndCol,
    dawnGrndCol
  );

  const vec4 mieColor[keys] = vec4[keys](
    sunriseScatter,
    dayScatter,
    noonScatter,
    eveningScatter,
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
     const float paleIntensity[keys] = float[keys](
    0.75,
    1.0,
    1.0,
    0.65,
    0.45,
    0.45,
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
  float paleStrength = mix(
    paleIntensity[i],
    paleIntensity[i + 1],
    timeInterp
  );
  
  zenithCol = mix(zenithCol, paleZenCol * paleStrength, PaleGardenSmooth);
  horizonCol = mix(horizonCol, paleHorCol * paleStrength, PaleGardenSmooth);
  groundCol = mix(groundCol, paleGrndCol * paleStrength, PaleGardenSmooth);

  zenithCol = mix(zenithCol, rainZenCol * weatherStrength, wetness * hotBiomeSmooth);
  horizonCol = mix(horizonCol, rainHorCol * weatherStrength, wetness * hotBiomeSmooth);
  groundCol = mix(groundCol, rainGrndCol * weatherStrength, wetness * hotBiomeSmooth);

  float zenithBlend = clamp(pow(upPos, 0.65), 0, 1);
  float horizonBlend = clamp(pow(negatedMidPos, 3.5), 0, 1);
  float groundBlend = clamp(pow(negatedDownPos, 0.55), 0, 1);

  zenithCol *=  zenithBlend;
  horizonCol *= horizonBlend;
  groundCol *=  groundBlend;

  vec3 sky = zenithCol + horizonCol + groundCol;
  sky *= rayleigh;
  vec3 sunColor = currentSunColor(vec3(0.0)); 
  

  vec3 moonMieScatterColor = vec3(0.1041, 0.1141, 0.1296);
  vec3 mieScat = mix(mieColor[i].rgb, mieColor[i + 1].rgb, timeInterp);
  mieScat = mix(mieScat, vec3(0.0), wetness);
  moonMieScatterColor = mix(moonMieScatterColor, vec3(0.0), wetness);
  float mieScale = mix(mieColor[i].a, mieColor[i + 1].a, timeInterp);

  float sVoL = dot(dir, worldSunDir);
  float mVoL = dot(dir, worldMoonDir);

  float miePhase = CS(mieScale, sVoL);
  vec3 mieColors = mieScat * miePhase * 0.95;

  float moonPhase = CS(0.815, mVoL);
  vec3 mieNight = moonMieScatterColor * moonPhase * 0.4;

  vec3 finalMie = mieColors + mieNight ;
  float sunHeightFactor = smoothstep(groundBlend, groundBlend + 0.041, dir.y);
  finalMie *=sunHeightFactor;

    vec3 color = sky + finalMie;
  
  return color;
}

vec3 computeSkyColoring(vec3 pos)
{
  vec3 dir = normalize(pos);
  float VoL = dot(dir, worldLightVector);
  float rayleigh =
    Rayleigh(VoL) * 12.1;
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
    dawnZenCol * 0.81 ,
    dayZenCol,
    dayZenCol,
    duskZenCol * 0.81 ,
    nightZenCol * 1.19,
    nightZenCol * 1.19,
    dawnZenCol * 0.81
  );
  const float weatherIntensity[keys] = float[keys](
    0.75,
    1.0,
    1.0,
    0.65,
    0.45,
    0.45,
    0.75
  );
    const float paleIntensity[keys] = float[keys](
    0.75,
    1.0,
    1.0,
    0.65,
    0.45,
    0.45,
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
   float weatherStrength = mix(
    weatherIntensity[i],
    weatherIntensity[i + 1],
    timeInterp
  );
  float paleStrength = mix(
    paleIntensity[i],
    paleIntensity[i + 1],
    timeInterp
  );

  vec3 zenithCol = mix(zenithColors[i], zenithColors[i + 1], timeInterp) ;
  zenithCol = mix(zenithCol, rainZenCol * weatherStrength, wetness * hotBiomeSmooth);
  zenithCol = mix(zenithCol, paleZenCol * paleStrength, PaleGardenSmooth);

  return zenithCol;
}

#endif
