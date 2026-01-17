#ifndef DISTORT_GLSL
#define DISTORT_GLSL

#include "/lib/common.glsl"
#include "/lib/uniforms.glsl"
const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;
const bool shadowcolor0Nearest = true;

const int shadowMapResolution = SHADOW_RESOLUTION;

vec3 distortShadowClipPos(vec3 shadowClipPos) {
  float distortionFactor = length(shadowClipPos.xy); // distance from the player in shadow clip space
  distortionFactor += 0.05; // very small distances can cause issues so we add this to slightly reduce the distortion

  shadowClipPos.xy /= distortionFactor;
  shadowClipPos.z *= 0.5; // increases shadow distance on the Z axis, which helps when the sun is very low in the sky
  return shadowClipPos;
}

float cubeLength(vec2 v) {
  vec2 t = abs(pow(v, vec2(3.0)));
  return pow(t.x + t.y, 1.0 / 3.0);
}

vec3 distort(vec3 pos) {
  float factor =
    cubeLength(pos.xy) * 0.85 + (1.0 - 0.85);
  pos.xy /= factor;
  pos.z /= 2.0;
  return pos;
}

vec3 getDistortedPos(vec3 pos) {
    vec2 distortionCenter = vec2(0.0); // Any arbitrary point in NDC space
    vec2 offset = pos.xy - distortionCenter;
    vec2 delta  = sign(offset) - distortionCenter;
    float distortionAmount = 0.85;
    float factor = mix(1.0, length(offset / delta), distortionAmount); 
    return vec3(distortionCenter + offset / factor, pos.z * 0.2);
}



#endif //DISTORT_GLSL
