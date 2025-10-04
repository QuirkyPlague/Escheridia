#version 400 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"
#include "/lib/lighting/lighting.glsl"
#include "/lib/common.glsl"
#include "/lib/atmosphere/skyColor.glsl"

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




vec3 calcMieSky(
  vec3 pos,
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



vec3 getSunBasic(vec3 dir)
{
    vec3 sunPos = normalize(sunPosition);
    vec3 moonPos = normalize(moonPosition);
    float cosTheta = dot(dir, sunPos);
    float mDotL = dot(dir, moonPos);

    float invCos = 1 - cosTheta;
    float invCos1 = 1 - mDotL;
    float angularDist = clamp(invCos, -1.0, 1.0);
    float angularDist1 = clamp(invCos1, -1.0, 1.0);
    float sun = smoothstep(0.0003, 0.0003 * 0.9, angularDist);
    float moon = smoothstep(0.0002, 0.0001 * 0.03, angularDist1);
    vec3 sunColor;
    
    sunColor = currentSunColor(sunColor);

   vec3 fullSun = sun * sunColor * 550.0;
   vec3 fullmoon = moon * sunColor * 6.3;
   return fullSun + fullmoon;
}



/* RENDERTARGETS: 0,8,8*/
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 stars;
layout(location = 2) out vec4 sun;
void main() {
 
  if (renderStage == MC_RENDER_STAGE_STARS) {
    color = glcolor * 1.5;
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
  const float starIntensity[keys] = float[keys](
    0.0, 
    0.0, 
    0.0,
    0.0, 
    1.0,
    1.0, 
    0.0 
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

    float starI = mix(starIntensity[i], starIntensity[i + 1], segW);
    // precompute values once
    float starBrightnessShift = length(feetPlayerPos) * 0.9;
    vec2 posShift;
    posShift = vec2(0.0, 1.0);
    float baseX =
      dot(feetPlayerPos.xz, posShift) * 0.5 +
      (frameTimeCounter * 2.9 + starBrightnessShift);

    float starTwinkleFactor = exp(sin(baseX - 1.6));
    float starFluctuation = starTwinkleFactor - exp(cos(baseX - 1.0));
    vec2 starTwinkle =
      vec2(starTwinkleFactor, -starFluctuation) +
      starBrightnessShift * posShift;
    stars += float(starTwinkle) * 0.96;
    stars *= starI;
  } else {
    vec3 pos = viewPos;


    vec3 sunColor = currentSunColor(vec3(0.0));

    vec3 skyMie = vec3(
      calcMieSky(normalize(pos), sunColor, pos, texcoord)
    );
    vec3 eyePlayerPos = feetPlayerPos - gbufferModelViewInverse[3].xyz;
    vec3 skyMain = newSky(eyePlayerPos);
    vec3 sunBasic = getSunBasic(normalize(pos));

    color.rgb = skyMain  + skyMie + sunBasic;
    sun.rgb = getSunBasic(normalize(pos));
  }
}
