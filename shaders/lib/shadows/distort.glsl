#ifndef DISTORT_GLSL
#define DISTORT_GLSL

#include "/lib/common.glsl"
#include "/lib/uniforms.glsl"
const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;
const bool shadowcolor0Nearest = true;


const int shadowMapResolution = SHADOW_RESOLUTION;

vec3 distortShadowClipPos(vec3 shadowClipPos){
  float distortionFactor = length(shadowClipPos.xy); // distance from the player in shadow clip space
  distortionFactor += 0.2; // very small distances can cause issues so we add this to slightly reduce the distortion

  shadowClipPos.xy /= distortionFactor;
  shadowClipPos.z *= 0.5; // increases shadow distance on the Z axis, which helps when the sun is very low in the sky
  return shadowClipPos;
}


#endif //DISTORT_GLSL