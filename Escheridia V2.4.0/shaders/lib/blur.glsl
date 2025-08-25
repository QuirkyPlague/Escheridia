#ifndef BLUR_GLSL
#define BLUR_GLSL

#include "/lib/SSR.glsl"
#include "/lib/util.glsl"
#include "/lib/uniforms.glsl"

vec2 blur5(vec2 uv, vec2 direction) {
  vec2 offset = vec2(0.0, 0.0);
  vec2 off1 = vec2(1.3333333333333333) * direction;
  offset += uv * 0.29411764705882354;
  offset += uv + off1 * 0.35294117647058826;
  offset += uv - off1 * 0.35294117647058826;
  return offset;
}

#endif
