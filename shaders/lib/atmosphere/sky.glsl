#ifndef SKY
#define SKY

#include "/lib/util.glsl"
#include "/lib/lighting/lighting.glsl"

//Day
const vec3 dayZenCol=vec3(0.2392, 0.4941, 1.0);
const vec3 dayHorCol=vec3(0.3922, 0.6314, 0.8745);
const vec3 dayGrndCol=vec3(0.298, 0.5412, 0.7843);

//Dawn
const vec3 dawnZenCol=vec3(0.3255, 0.502, 0.8549);
const vec3 dawnHorCol=vec3(0.8353, 0.4902, 0.3059);
const vec3 dawnGrndCol=vec3(0.2863, 0.4235, 0.6784);

//Dusk
const vec3 duskZenCol=vec3(0.4667, 0.5294, 0.851);
const vec3 duskHorCol=vec3(0.8431, 0.4941, 0.3216);
const vec3 duskGrndCol=vec3(0.7255, 0.251, 0.3608);

//Night
const vec3 nightZenCol=vec3(0.0392, 0.0745, 0.2824);
const vec3 nightHorCol=vec3(0.1059, 0.1569, 0.2314);
const vec3 nightGrndCol=vec3(0.0196, 0.0275, 0.1294);

const vec4 sunriseScatter=vec4(0.7922, 0.5294, 0.2627, 0.8);
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

   vec3 fullSun = sun * sunColor * 150.0;
   vec3 fullmoon = moon * sunColor * 15.3;
   return fullSun + fullmoon;
}

vec3 skyScattering(vec3 pos){
   vec3 dir=normalize(pos);
    float VoL=dot(dir,worldLightVector);
    float rayleigh = Rayleigh(VoL);
    float upPos=clamp(dir.y,0,1);
    float downPos=clamp(dir.y,-1,0);
    float negatedDownPos=-1*downPos;
    float midPos=upPos+negatedDownPos;
    float negatedMidPos=1-midPos;
    
    float t = fract(worldTime / 24000.0);

    const int keys = 7;
    const float keyFrames[keys] = float[keys](
    0.0,        //sunrise
    0.0417,     //day
    0.25,       //noon
    0.4792,     //sunset
    0.5417,     //night
    0.8417,     //midnight
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
    //assings the keyframes
    for (int k = 0; k < keys - 1; ++k) {
        i += int(step(keyFrames[k + 1], t));
    }
    i = clamp(i, 0, keys - 2);

    //Interpolation factor based on the time
    float timeInterp = (t - keyFrames[i]) / max(1e-6, keyFrames[i + 1] - keyFrames[i]);
    timeInterp = smoothstep(0.0, 1.0, timeInterp);

    //apply interpolation to color
    vec3 zenithCol;
    vec3 horizonCol;
    vec3 groundCol;
    zenithCol = mix(zenithColors[i], zenithColors[i + 1], timeInterp);
    horizonCol = mix(horizonColors[i], horizonColors[i + 1], timeInterp);
    groundCol = mix(groundColors[i], groundColors[i + 1], timeInterp);

   float zenithBlend= clamp(pow(upPos,.15),0,1);
    float horizonBlend=clamp(pow(negatedMidPos,6.5),0,1);
    float groundBlend=clamp(pow(negatedDownPos,.15),0,1);
    
    zenithCol *= rayleigh * 20 * zenithBlend;
    horizonCol *= rayleigh * 20 * horizonBlend;
    groundCol *=groundBlend *rayleigh* 20;
    
    vec3 sky=zenithCol+horizonCol+groundCol;
    // MIE Scattering
    vec3 sunColor = vec3(0.9882, 0.8353, 0.5961);
    
    //Mie scattering assignments

    vec3 moonMieScatterColor=
    vec3(0.0471, 0.0549, 0.251)*sunColor;
    vec3 mieScat = mix(mieColor[i].rgb, mieColor[i + 1].rgb, timeInterp);
    float mieScale = mix(mieColor[i].a, mieColor[i + 1].a, timeInterp);
    vec3 mMieScat=moonMieScatterColor;
    
    
    float sVoL=dot(normalize(pos),worldSunDir);
    float mVoL=dot(normalize(pos),worldMoonDir);
    
    float miePhase=CS(mieScale,sVoL);
    vec3 mieColors=mieScat*miePhase*.5;// tweak multiplier
    
    float moonPhase=CS(.915,mVoL);
    vec3 mieNight=mMieScat*moonPhase*.3;
    vec3 finalMie=mieColors+mieNight;
   
    return sky+finalMie;
}

#endif