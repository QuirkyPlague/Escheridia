#ifndef DISTORT_GLSL
#define DISTORT_GLSL

#include "/lib/common.glsl"



const int shadowMapResolution = SHADOW_MAP_RESOLUTION;

#if DO_SOFT_SHADOW == 1
const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;
const bool shadowcolor0Nearest = true;
#endif

vec3 getBiasDerivative(vec3 shadowClipPos)
{
  float x = length(shadowClipPos.xy);
  float biasDistance = 1.0 / (x + SHADOW_DISTORTION) - x / (x + pow(SHADOW_DISTORTION, 2.0));
  return vec3(biasDistance);
}


vec3 distortShadowClipPos(vec3 shadowClipPos){
  float distortionFactor = length(shadowClipPos.xy); // distance from the player in shadow clip space
  distortionFactor += 0.15; // very small distances can cause issues so we add this to slightly reduce the distortion

  shadowClipPos.xy /= distortionFactor;
  shadowClipPos.z *= 0.5; // increases shadow distance on the Z axis, which helps when the sun is very low in the sky
  return shadowClipPos;
}
#endif