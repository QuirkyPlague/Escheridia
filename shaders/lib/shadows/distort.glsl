#ifndef DISTORT_GLSL
#define DISTORT_GLSL

#include "/lib/common.glsl"
#include "/lib/uniforms.glsl"
const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;
const bool shadowcolor0Nearest = true;

#define _pow3(x) (x*x*x)
float pow3(in float x) {
    return _pow3(x);
}
int pow3(in int x) {
    return _pow3(x);
}
vec2 pow3(in vec2 x) {
    return _pow3(x);
}
vec3 pow3(in vec3 x) {
    return _pow3(x);
}
vec4 pow3(in vec4 x) {
    return _pow3(x);
}


float cubeLength(vec2 v) {
    vec2 t = abs(pow3(v));
    return pow(t.x + t.y, 1.0/3.0);
}
const int shadowMapResolution = SHADOW_RESOLUTION;

vec3 distortShadowClipPos(vec3 shadowClipPos){
  float distortionFactor = length(shadowClipPos.xy); // distance from the player in shadow clip space
  distortionFactor += 0.1; // very small distances can cause issues so we add this to slightly reduce the distortion

  shadowClipPos.xy /= distortionFactor;
  shadowClipPos.z *= 0.5; // increases shadow distance on the Z axis, which helps when the sun is very low in the sky
  return shadowClipPos;
}


#endif //DISTORT_GLSL