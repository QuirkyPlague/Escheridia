#ifndef SKY
#define SKY

#include "/lib/util.glsl"
#include "/lib/lighting/lighting.glsl"

//Pale Garden
const vec3 paleZenCol=vec3(1.0, 1.0, 1.0);
const vec3 paleHorCol=vec3(0.7137, 0.7137, 0.7137);
const vec3 paleGrndCol=vec3(0.4314, 0.4314, 0.4314);

//Day
const vec3 dayZenCol=vec3(0.2392, 0.4941, 1.0);
const vec3 dayHorCol=vec3(0.3922, 0.6314, 0.8745);
const vec3 dayGrndCol=vec3(0.298, 0.5412, 0.7843);

//Dawn
const vec3 dawnZenCol=vec3(0.2627, 0.4, 0.6706);
const vec3 dawnHorCol=vec3(0.8353, 0.4902, 0.3059);
const vec3 dawnGrndCol=vec3(0.5529, 0.3608, 0.1569);

//Dusk
const vec3 duskZenCol=vec3(0.4667, 0.5294, 0.851);
const vec3 duskHorCol=vec3(0.8431, 0.4941, 0.3216);
const vec3 duskGrndCol=vec3(0.7255, 0.251, 0.3608);

//Night
const vec3 nightZenCol=vec3(0.0392, 0.0745, 0.2824);
const vec3 nightHorCol=vec3(0.1059, 0.1569, 0.2314);
const vec3 nightGrndCol=vec3(0.0196, 0.0275, 0.1294);

const vec4 sunriseScatter=vec4(0.7922, 0.5294, 0.2627, 0.65);
const vec4 dayScatter=vec4(0.6863, 0.6275, 0.4706, 0.75);
const vec4 nightScatter=vec4(1.0, 1.0725, 1.1725, 0.55);

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

   vec3 fullSun = sun * sunColor * 35.0;
   vec3 fullmoon = moon * sunColor * 15.3;
   return fullSun + fullmoon;
}

vec3 skyScattering(vec3 pos){
   vec3 dir = normalize(pos);
    float VoL = dot(dir, worldLightVector);
    float rayleigh = Rayleigh(VoL);

    float upPos = clamp(dir.y, 0, 1);
    float downPos = clamp(dir.y, -1, 0);
    float negatedDownPos = -1.0 * downPos;
    float midPos = upPos + negatedDownPos;
    float negatedMidPos = 1.0 - midPos;

    float t = fract(worldTime / 24000.0);

    const int keys = 7;
 const float keyFrames[keys] = float[keys](
    0.0,        //sunrise
    0.0417,     //day
    0.45,       //noon
    0.5192,     //sunset
    0.5417,     //night
    0.9417,     //midnight
    1.0         //sunrise
    );

    const vec3 zenithColors[keys] = vec3[keys](
        dawnZenCol,
        dayZenCol,
        dayZenCol,
        duskZenCol * 0.7,
        nightZenCol * 0.85,
        nightZenCol * 0.85,
        dawnZenCol * 0.5
    );
    const vec3 horizonColors[keys] = vec3[keys](
        dawnHorCol,
        dayHorCol,
        dayHorCol,
        duskHorCol * 0.8,
        nightHorCol,
        nightHorCol,
        dawnHorCol * 0.5
    );
    const vec3 groundColors[keys] = vec3[keys](
        dawnGrndCol,
        dayGrndCol,
        dayGrndCol,
        duskGrndCol * 0.8,
        nightGrndCol,
        nightGrndCol,
        dawnGrndCol * 0.5
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

    int i = 0;
    for (int k = 0; k < keys - 1; ++k) {
        i += int(step(keyFrames[k + 1], t));
    }
    i = clamp(i, 0, keys - 2);

    float timeInterp = (t - keyFrames[i]) / max(1e-6, keyFrames[i + 1] - keyFrames[i]);
    timeInterp = smoothstep(0.0, 1.0, timeInterp);

    vec3 zenithCol = mix(zenithColors[i], zenithColors[i + 1], timeInterp);
    vec3 horizonCol = mix(horizonColors[i], horizonColors[i + 1], timeInterp);
    vec3 groundCol = mix(groundColors[i], groundColors[i + 1], timeInterp);

    zenithCol = mix(zenithCol, paleZenCol, PaleGardenSmooth);
    horizonCol = mix(horizonCol, paleHorCol, PaleGardenSmooth);
    groundCol = mix(groundCol, paleGrndCol, PaleGardenSmooth);

    float zenithBlend  = clamp(pow(upPos, 0.35), 0, 1);
    float horizonBlend = clamp(pow(negatedMidPos, 4.5), 0, 1);
    float groundBlend  = clamp(pow(negatedDownPos, 0.35), 0, 1);

    zenithCol *= rayleigh * 20.0 * zenithBlend;
    horizonCol *= rayleigh * 20.0 * horizonBlend;
    groundCol *= rayleigh * 20.0 * groundBlend;

    vec3 sky = zenithCol + horizonCol + groundCol;


    vec3 sunColor;
    sunColor = currentSunColor(sunColor);

    vec3 moonMieScatterColor = vec3(0.2196,0.2196,0.2353) * sunColor;
    vec3 mieScat = mix(mieColor[i].rgb, mieColor[i + 1].rgb, timeInterp);
    float mieScale = mix(mieColor[i].a, mieColor[i + 1].a, timeInterp);

    float sVoL = dot(dir, worldSunDir);
    float mVoL = dot(dir, worldMoonDir);

    float miePhase = CS(mieScale, sVoL);
    vec3 mieColors = mieScat * miePhase * 0.5;

    float moonPhase = CS(0.915, mVoL);
    vec3 mieNight = moonMieScatterColor * moonPhase * 0.7;

    vec3 finalMie = mieColors + mieNight;

    float dawnDuskMieFactor = smoothstep(-0.035, 0.035, dir.y);
    float dawnDuskTimeFactor = smoothstep(0.0, 0.1, t) * smoothstep(0.4, 0.6, t);
    finalMie *= mix(1.0, dawnDuskMieFactor, dawnDuskTimeFactor);
   
    return sky+finalMie;
}

#endif